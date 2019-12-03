defmodule KrakenX.Spot.Rest do
  @moduledoc """
  Wrapper for the KrakenFutures / Cryptofacilities API
  """
  alias KrakenX.Spot.Client

  @public_get [
    "Time",
    "Assets",
    "AssetPairs",
    "Ticker",
    "OHLC",
    "Depth",
    "Trades",
    "Spread"
  ]

  @private_get [
    "TradeBalance",
    "OpenOrders",
    "ClosedOrders",
    "QueryOrders",
    "TradesHistory",
    "QueryTrades",
    "OpenPositions",
    "Ledgers",
    "QueryLedgers",
    "TradeVolume",
    "AddExport",
    "ExportStatus",
    "RetrieveExport",
    "RemoveExport",
    "AddOrder",
    "CancelOrder",
    "DepositMethods",
    "DepositAddresses",
    "DepositStatus",
    "WithdrawInfo",
    "Withdraw",
    "WithdrawStatus",
    "WithdrawCancel",
    "WalletTransfer"
  ]

  for epoint <- @public_get do
    endpoint =
      Macro.underscore(epoint)
      |> String.to_atom()

    def unquote(endpoint)(params \\ %{}),
      do: Client.get_public(unquote(epoint), params)
  end

  for epoint <- @private_get do
    endpoint =
      Macro.underscore(epoint)
      |> String.to_atom()

    def unquote(endpoint)(
          public_api_key,
          private_api_key,
          params \\ %{}
        ) do
      Client.get_private(
        unquote(epoint),
        public_api_key,
        private_api_key,
        params
      )
    end

    def unquote(endpoint)(params \\ %{}) do
      Client.get_private(
        unquote(epoint),
        public_api_key(),
        private_api_key(),
        params
      )
    end
  end

  defp public_api_key, do: System.get_env("kraken_spot_public")
  defp private_api_key, do: System.get_env("kraken_spot_private")
end
