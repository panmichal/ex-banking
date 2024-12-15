defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

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
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    case get_user(user) do
      nil ->
        {:error, :user_does_not_exist}

      user_agent ->
        ExBanking.AccountAgent.increase_balance(user_agent, amount, currency)
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
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    case get_user(user) do
      nil ->
        {:error, :user_does_not_exist}

      user_agent ->
        ExBanking.AccountAgent.decrease_balance(user_agent, currency, amount)
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    case get_user(user) do
      nil ->
        {:error, :user_does_not_exist}

      user_agent ->
        ExBanking.AccountAgent.get_balance(user_agent, currency)
    end
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
  def send(from_user, to_user, amount, currency) do
    {:ok, amount, amount}
  end

  defp get_user(user) do
    case Registry.lookup(ExBanking.UserRegistry, user) do
      [{pid, _}] -> pid
      _ -> nil
    end
  end
end
