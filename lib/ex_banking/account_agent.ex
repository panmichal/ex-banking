defmodule ExBanking.AccountAgent do
  @doc """
  Agent for storing user's account balance.
  """
  use Agent

  alias ExBanking.Accounts

  @doc """
  Starts a new agent with empty balance.
  """
  def start_link(args) do
    Agent.start_link(fn -> %{} end, args)
  end

  def get_balance(pid, currency) do
    Agent.get(pid, fn state -> {:ok, Accounts.get_balance(state, currency)} end)
  end

  def increase_balance(pid, amount, currency) do
    Agent.get_and_update(pid, fn state ->
      new_balance = Accounts.increase_balance(state, currency, amount)
      {{:ok, Accounts.get_balance(new_balance, currency)}, new_balance}
    end)
  end

  @spec decrease_balance(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any(), any()) ::
          any()
  def decrease_balance(pid, currency, amount) do
    Agent.get_and_update(pid, fn state ->
      case Accounts.decrease_balance(state, currency, amount) do
        {:ok, state} -> {{:ok, Accounts.get_balance(state, currency)}, state}
        {:error, :not_enough_money} -> {{:error, :not_enough_money}, state}
      end
    end)
  end
end
