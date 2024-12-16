defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  setup %{} do
    start_link_supervised!({Registry, keys: :unique, name: ExBanking.UserRegistryTest})

    start_link_supervised!(
      {DynamicSupervisor, name: ExBanking.UserSupervisorTest, strategy: :one_for_one}
    )

    Application.put_env(:ex_banking, ExBanking,
      user_registry: ExBanking.UserRegistryTest,
      user_supervisor: ExBanking.UserSupervisorTest
    )

    :ok = ExBanking.create_user("testuser")
  end

  describe "create_user/1" do
    test "creates user with empty balance" do
      :ok = ExBanking.create_user("michal")
      assert ExBanking.get_balance("michal", "eur") == {:ok, 0}
    end

    test "returns error when user name is not a string" do
      assert ExBanking.create_user(:michal) == {:error, :wrong_arguments}
    end

    test "returns error when user already exists" do
      :ok = ExBanking.create_user("michal")
      assert ExBanking.create_user("michal") == {:error, :user_already_exists}
    end
  end

  describe "deposit and check balance" do
    test "returns error when user does not exist" do
      assert ExBanking.get_balance("michal", "eur") == {:error, :user_does_not_exist}
    end

    test "returns error when currency is not a string" do
      assert ExBanking.get_balance("michal", :eur) == {:error, :wrong_arguments}
    end

    test "returns balance for the given currency" do
      :ok = ExBanking.create_user("michal")
      {:ok, 100.50} = ExBanking.deposit("michal", 100.50, "eur")
      assert ExBanking.get_balance("michal", "eur") == {:ok, 100.50}
      assert ExBanking.get_balance("michal", "pln") == {:ok, 0}
    end

    test "returns error when too many operations are executed at the same time" do
      :ok = ExBanking.create_user("michal")

      results =
        Enum.map(1..11, fn _ ->
          Task.async(fn -> ExBanking.deposit("michal", 1.50, "eur") end)
        end)
        |> Enum.map(&Task.await/1)

      assert MapSet.new(results) ==
               MapSet.new(
                 ok: 1.5,
                 ok: 3.0,
                 ok: 4.5,
                 ok: 6.0,
                 ok: 7.5,
                 ok: 9.0,
                 ok: 10.5,
                 ok: 12.0,
                 ok: 13.5,
                 ok: 15.0,
                 error: :too_many_requests_to_user
               )
    end
  end

  describe "wihtdraw money" do
    test "returns error when user does not exist" do
      assert ExBanking.withdraw("non-existent", 100.50, "eur") == {:error, :user_does_not_exist}
    end

    test "returns error when currency is not a string" do
      assert ExBanking.withdraw("testuser", 100.50, :eur) == {:error, :wrong_arguments}
    end

    test "returns error when amount is not a number" do
      assert ExBanking.withdraw("testuser", :eur, 100.50) == {:error, :wrong_arguments}
    end

    test "returns error when amount is a negative number" do
      assert ExBanking.withdraw("testuser", -100.50, "eur") == {:error, :wrong_arguments}
    end

    test "returns error when user does not have enough money" do
      assert ExBanking.withdraw("testuser", 100.50, "eur") == {:error, :not_enough_money}
    end

    test "decreases balance of the given currency by the given amount" do
      ExBanking.deposit("testuser", 100.25, "eur")
      ExBanking.deposit("testuser", 100.50, "pln")
      ExBanking.withdraw("testuser", 100.0, "eur")

      assert ExBanking.get_balance("testuser", "eur") == {:ok, 0.25}
      assert ExBanking.get_balance("testuser", "pln") == {:ok, 100.50}
    end
  end

  describe "transfer money between accounts" do
    test "returns error when sender does not have enough money in the given currency" do
      :ok = ExBanking.create_user("sender")
      :ok = ExBanking.create_user("receiver")
      {:ok, 100.25} = ExBanking.deposit("sender", 100.25, "eur")

      assert ExBanking.send("sender", "receiver", 100.50, "pln") == {:error, :not_enough_money}
    end

    test "transfer the given amount between the sender and the receiver" do
      :ok = ExBanking.create_user("sender")
      :ok = ExBanking.create_user("receiver")
      {:ok, 100.50} = ExBanking.deposit("sender", 100.50, "eur")
      {:ok, 55.55} = ExBanking.deposit("sender", 55.55, "pln")

      assert ExBanking.send("sender", "receiver", 50.25, "pln") == {:ok, 5.30, 50.25}
    end
  end
end
