defmodule ExBanking.Accounts do
  @moduledoc """
  Context module for operations on account balance.
  """

  @doc """
   Returns balance for the given currency.

   ## Examples

   iex> ExBanking.Accounts.get_balance(%{"usd" => 100}, "usd")
   100

   iex> ExBanking.Accounts.get_balance(%{"usd" => 100, "pln" => 200}, "eur")
   0

  """
  @spec get_balance(map(), String.t()) :: number()
  def get_balance(account, currency), do: Map.get(account, currency, 0)

  @doc """
   Increases balance for the given currency. Sets 0 as initial balance if currency does not exist.
   ## Examples
   iex> ExBanking.Accounts.increase_balance(%{"usd" => 100}, "usd", 200)
   %{"usd" => 300}

   iex> ExBanking.Accounts.increase_balance(%{"usd" => 100}, "eur", 200)
   %{"eur" => 200, "usd" => 100}
  """
  @spec increase_balance(map(), String.t(), number()) :: map()
  def increase_balance(account, currency, amount),
    do: Map.update(account, currency, amount, &(&1 + amount))

  @doc """
  Decreases balance for the given currency. Returns an error if current balance is lower than the amount.
  ## Examples
  iex> ExBanking.Accounts.decrease_balance(%{"usd" => 100}, "usd", 50)
  {:ok, %{"usd" => 50}}

  iex> ExBanking.Accounts.decrease_balance(%{"usd" => 100}, "usd", 150)
  {:error, :not_enough_money}

  iex> ExBanking.Accounts.decrease_balance(%{"usd" => 100}, "eur", 1)
  {:error, :not_enough_money}
  """
  @spec decrease_balance(map(), String.t(), number()) :: {:ok, map()} | {:error, String.t()}
  def decrease_balance(account, currency, amount) do
    current_balance = get_balance(account, currency)

    if current_balance < amount,
      do: {:error, :not_enough_money},
      else: {:ok, Map.update(account, currency, 0, &(&1 - amount))}
  end
end
