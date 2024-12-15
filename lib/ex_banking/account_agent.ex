defmodule ExBanking.AccountAgent do
  @doc """
  Agent for storing user's account balance.
  """
  use Agent

  alias ExBanking.Accounts

  @max_pending_operations 10

  @doc """
  Starts a new agent with empty balance and no pending operations.
  """
  def start_link(args) do
    Agent.start_link(fn -> %{pending: 0, balance: %{}} end, args)
  end

  def add_pending(pid) do
    Agent.get_and_update(pid, fn state ->
      current_pending = state.pending
      new_state = %{state | pending: current_pending + 1}

      if current_pending < @max_pending_operations,
        do: {:ok, new_state},
        else: {{:error, :too_many_requests_to_user}, state}
    end)
  end

  def complete_pending(pid) do
    Agent.update(pid, fn state ->
      %{state | pending: max(0, state.pending - 1)}
    end)
  end

  def get_balance(pid, currency) do
    case add_pending(pid) do
      :ok ->
        result =
          Agent.get(pid, fn state -> {:ok, Accounts.get_balance(state.balance, currency)} end)

        complete_pending(pid)
        result

      error ->
        error
    end
  end

  @spec increase_balance(pid(), number(), String.t()) ::
          {:ok, number()} | {:error, :too_many_requests_to_user}
  def increase_balance(pid, amount, currency) do
    case add_pending(pid) do
      :ok ->
        result =
          Agent.get_and_update(pid, fn state ->
            new_balance = Accounts.increase_balance(state.balance, currency, amount)
            new_state = %{state | balance: new_balance}

            {{:ok, Accounts.get_balance(new_balance, currency)}, new_state}
          end)

        complete_pending(pid)
        result

      error ->
        error
    end
  end

  @spec decrease_balance(pid(), number(), String.t()) ::
          {:ok, number()} | {:error, :not_enough_money | :too_many_requests_to_user}
  def decrease_balance(pid, amount, currency) do
    case add_pending(pid) do
      :ok ->
        result =
          Agent.get_and_update(pid, fn state ->
            case Accounts.decrease_balance(state.balance, currency, amount) do
              {:ok, new_balance} ->
                new_state = %{state | balance: new_balance}
                {{:ok, Accounts.get_balance(new_balance, currency)}, new_state}

              {:error, :not_enough_money} ->
                {{:error, :not_enough_money}, state}
            end
          end)

        complete_pending(pid)
        result

      error ->
        error
    end
  end
end
