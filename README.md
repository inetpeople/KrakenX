# KrakenX

**TODO: Add description**

## Installation

The package can be installed by adding `kraken_x` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kraken_x, "~> 0.1.0"}
  ]
end
```

Run `mix deps.get` to install.

## Configuration

### Static API Key


Static API Key is the key you setup once and would never change. And this is what we need for most cases.

Add the following configuration variables in your config/config.exs file:

```elixir
use Mix.Config

config :kraken_x, api_key:        {:system, "KRAKEN_FUTURES_API_KEY"},
                  api_secret:     {:system, "KRAKEN_FUTURES_API_SECRET"},
                  api_passphrase: {:system, "KRAKEN_FUTURES_API_PASSPHRASE"}
```

Alternatively to hard coding credentials, the recommended approach is
to use environment variables as follows:

```elixir
use Mix.Config

config :kraken_x, api_key:        System.get_env("KRAKEN_FUTURES_API_KEY"),
                  api_secret:     System.get_env("KRAKEN_FUTURES_API_SECRET"),
                  api_passphrase: System.get_env("KRAKEN_FUTURES_API_PASSPHRASE")
```


```elixir
    children = [
      {KrakenX.Futures, %{channels: ["pi_ethusd"], require_auth: true, debug: [:trace]}}
    ]
```


```elixir
defmodule MyModule do
  use KrakenX.Futures.WebSocket

  def broadcast!(topic, event, msg) do
    # Use Phoenix PubSub
    MyApplicationWeb.Endpoint.broadcast!(topic, event, msg)
    # or do something else like writting in a DB if your really need that.
    something_else()
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kraken_x](https://hexdocs.pm/kraken_x).

