defmodule KrakenX.Futures.Rest do
  @moduledoc """
  Wrapper for the KrakenFutures / Cryptofacilities API
  """
  alias KrakenX.Futures.Client

  @public_get [
    "orderbook",
    "tickers",
    "instruments",
    "history"
  ]

  @private_get [
    "accounts",
    "openpositions",
    "editorder",
    "sendorder",
    "cancelorder",
    "fills",
    "transfer",
    "batchorder",
    "notifications",
    "cancelallordersafter",
    "openorders",
    "recentorders",
    "historicorders",
    "withdrawal",
    "transfers"
  ]

  for endpoint <- @public_get do
    def unquote(String.to_atom(endpoint))(params \\ %{}),
      do: Client.get_public(unquote(endpoint), params)
  end

  for endpoint <- @private_get do
    def unquote(String.to_atom(endpoint))(
          public_api_key,
          private_api_key,
          params \\ %{}
        ) do
      Client.get_private(
        unquote(endpoint),
        public_api_key,
        private_api_key,
        params
      )
    end

    def unquote(String.to_atom(endpoint))(params \\ %{}) do
      Client.get_private(
        unquote(endpoint),
        public_api_key(),
        private_api_key(),
        params
      )
    end
  end

  defp public_api_key, do: System.get_env("KrakenFuturesPublic")
  defp private_api_key, do: System.get_env("KrakenFuturesPrivate")
end
