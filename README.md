# ExBanking

## Running

1. Install dependencies:
   ```mix deps.get```

2. Run the mix project (and connect IEx session): ```iex -S mix```

### Example usage
```
iex(1)> ExBanking.create_user("testuser")
:ok
iex(2)> ExBanking.deposit("testuser", 150.50, "eur")
{:ok, 150.5}
iex(3)> ExBanking.withdraw("testuser", 140.50, "pln")
{:error, :not_enough_money}
iex(4)> ExBanking.withdraw("testuser", 150.50, "eur")
{:ok, 0.0}
```

