defmodule ExBanking.Accounts do
  @moduledoc """
  Context module for operations on account balance.
  """

  @doc """
   Returns balance for the given currency.

   ## Examples

   iex> ExBanking.Accounts.get_balance(%{"usd" => Decimal.new(100)}, "usd")
   100.00

   iex> ExBanking.Accounts.get_balance(%{"usd" => Decimal.from_float(50.50), "pln" => Decimal.new(200)}, "eur")
   0.00

  """
  @spec get_balance(map(), String.t()) :: number()
  def get_balance(balance, currency),
    do:
      balance
      |> Map.get(currency, 0)
      |> Decimal.round(2)
      |> Decimal.to_float()

  @doc """
   Increases balance for the given currency. Sets 0 as initial balance if currency does not exist.
   ## Examples
   iex> ExBanking.Accounts.increase_balance(%{"usd" => Decimal.new(100)}, "usd", 200)
   %{"usd" => Decimal.new(300)}

   iex> ExBanking.Accounts.increase_balance(%{"usd" => Decimal.from_float(55.55)}, "eur", 200.50)
   %{"eur" => Decimal.from_float(200.50), "usd" => Decimal.from_float(55.55)}
  """
  @spec increase_balance(map(), String.t(), number()) :: map()
  def increase_balance(balance, currency, amount),
    do: Map.update(balance, currency, to_decimal(amount), &Decimal.add(&1, to_decimal(amount)))

  @doc """
  Decreases balance for the given currency. Returns an error if current balance is lower than the amount.
  ## Examples
  iex> ExBanking.Accounts.decrease_balance(%{"usd" => Decimal.new(100)}, "usd", 50.50)
  {:ok, %{"usd" => Decimal.from_float(49.50)}}

  iex> ExBanking.Accounts.decrease_balance(%{"usd" => Decimal.from_float(120.00)}, "usd", 150)
  {:error, :not_enough_money}

  iex> ExBanking.Accounts.decrease_balance(%{"usd" => Decimal.new(100)}, "eur", 1)
  {:error, :not_enough_money}
  """
  @spec decrease_balance(map(), String.t(), number()) ::
          {:ok, map()} | {:error, :not_enough_money}
  def decrease_balance(balance, currency, amount) do
    current_balance = to_decimal(get_balance(balance, currency))

    amount = to_decimal(amount)

    if Decimal.compare(current_balance, amount) == :lt,
      do: {:error, :not_enough_money},
      else:
        {:ok,
         Map.update(
           balance,
           currency,
           Decimal.new(0),
           &Decimal.sub(&1, amount)
         )}
  end

  defp to_decimal(number) when is_integer(number) do
    Decimal.new(number)
  end

  defp to_decimal(number) do
    Decimal.from_float(number)
  end
end
