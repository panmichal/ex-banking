defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.AccountAgent

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    case get_user(user) do
      nil ->
        name = {:via, Registry, {ExBanking.UserRegistry, user}}

        {:ok, _account_agent} =
          DynamicSupervisor.start_child(
            ExBanking.UserSupervisor,
            {ExBanking.AccountAgent, name: name}
          )

        :ok

      _user ->
        {:error, :user_already_exists}
    end
  end

  def create_user(_user) do
    {:error, :wrong_arguments}
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount > 0 and is_binary(currency) do
    case get_user(user) do
      nil ->
        {:error, :user_does_not_exist}

      {:ok, user_agent} ->
        AccountAgent.increase_balance(user_agent, amount, currency)
    end
  end

  def deposit(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount > 0 and is_binary(currency) do
    case get_user(user) do
      nil ->
        {:error, :user_does_not_exist}

      {:ok, user_agent} ->
        AccountAgent.decrease_balance(user_agent, amount, currency)
    end
  end

  def withdraw(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    case get_user(user) do
      nil ->
        {:error, :user_does_not_exist}

      {:ok, user_agent} ->
        AccountAgent.get_balance(user_agent, currency)
    end
  end

  def get_balance(_user, _currency) do
    {:error, :wrong_arguments}
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_binary(currency) and
             is_number(amount) and amount > 0 and from_user != to_user do
    with {:ok, from_user_agent} <- get_sender(from_user),
         {:ok, to_user_agent} <- get_receiver(to_user),
         {:ok, from_user_balance} <- withdraw_from_sender(from_user_agent, amount, currency),
         {:ok, to_user_balance} <- deposit_to_receiver(to_user_agent, amount, currency) do
      {:ok, from_user_balance, to_user_balance}
    end
  end

  def send(_from_user, _to_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  defp withdraw_from_sender(from_user_agent, amount, currency) do
    case AccountAgent.decrease_balance(from_user_agent, amount, currency) do
      {:ok, from_user_balance} -> {:ok, from_user_balance}
      {:error, :not_enough_money} -> {:error, :not_enough_money}
      {:error, :too_many_requests_to_user} -> {:error, :too_many_requests_to_sender}
    end
  end

  defp deposit_to_receiver(to_user_agent, amount, currency) do
    case AccountAgent.increase_balance(to_user_agent, amount, currency) do
      {:ok, to_user_balance} -> {:ok, to_user_balance}
      {:error, :too_many_requests} -> {:error, :too_many_requests_to_receiver}
    end
  end

  defp get_sender(from_user) do
    case get_user(from_user) do
      nil -> {:error, :sender_does_not_exist}
      {:ok, user_agent} -> {:ok, user_agent}
    end
  end

  defp get_receiver(to_user) do
    case get_user(to_user) do
      nil -> {:error, :receiver_does_not_exist}
      {:ok, user_agent} -> {:ok, user_agent}
    end
  end

  defp get_user(user) do
    case Registry.lookup(ExBanking.UserRegistry, user) do
      [{pid, _}] -> {:ok, pid}
      _ -> nil
    end
  end
end
