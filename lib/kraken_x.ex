defmodule KrakenX do
  import Logger, only: [info: 1, warn: 1]

  @moduledoc """
  Documentation for KrakenX.
  """

  def get_historical_closes(ohlc) do
    acc = []

    Enum.reduce(ohlc, acc, fn x, acc ->
      [price, _, _, _, _, _] = x
      [price | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Get recent trades
  URL: https://api.kraken.com/0/public/Trades

  Input:
  pair = asset pair to get trade data for
  since = return trade data since given id (optional.  exclusive)

  Result: array of pair name and recent trade data

  <pair_name> = pair name
  array of array entries(<price>, <volume>, <time>, <buy/sell>, <market/limit>, <miscellaneous>)
  last = id to be used as since when polling for new trade dat

  %{
    "error" => [],
    "result" => %{
      "XETHZUSD" => [[price, volume, time, buy/sell, market/limit, misc]],
      "last" => "time_id"
    }
  }
  """
  def get_historical_trades_since(pair, since) do
    {:ok, res} = Krakex.trades(pair, since: since)
    # KrakenX.Spot.Rest.trades(%{pair: pair, since: since})

    # last = res["result"]["last"]
    # [pair, _] = Map.keys(res["result"])
    # trades = res["result"][pair]

    last = res["last"]
    [pair, _] = Map.keys(res)
    trades = res[pair]

    {pair, trades, last}
  end

  def get_all_historical_trades(pair) do
    if String.length(pair) < 8 do
      raise ArgumentError, message: "Please use with 8 letter pair, like: XETHZUSD"
    end

    p = String.upcase(pair)

    file = File.read("./#{p}_trade_history.txt")

    case file do
      {:ok, file_content} ->
        {pair, old_trades, last} =
          file_content
          |> :erlang.binary_to_term()

        warn(
          "read: https://www.bignerdranch.com/blog/elixir-and-io-lists-part-2-io-lists-in-phoenix/"
        )

        {npair, new_trades, nlast} = get_historical_trades_since(pair, "#{last}")
        trades = (old_trades ++ new_trades) |> Enum.reverse()
        req_time = DateTime.utc_now()
        get_trades(npair, nlast, trades, req_time)

      {:error, :enoent} ->
        {pair, trades, last} = get_historical_trades_since(pair, 0)
        req_time = DateTime.utc_now()
        get_trades(pair, last, trades, req_time)

      _ ->
        {:error}
    end

    info("finished!!")
  end

  defp get_trades(pair, last, acc, req_time) do
    [_, _, time, _, _, _] = List.last(acc)
    last_trade = DateTime.from_unix!(trunc(time))

    if last_trade < req_time do
      info("Got all your data, Say  an")
      file_content = {pair, acc, last}
      File.write!("./#{pair}_trade_history.txt", :erlang.term_to_binary(file_content))
      {pair, acc, last}
    else
      info("run again #{last_trade}, i'm not ready yet. Have a coffee?")
      {npair, ntrades, nlast} = get_historical_trades_since(pair, last)
      nacc = (ntrades ++ acc) |> Enum.reverse()
      Process.sleep(5000)
      get_trades(npair, nlast, nacc, req_time)
    end
  end

  # def k_v(kv) do
  #   for {key, val} <-
  #         kv,
  #       into: %{},
  #       do: {atomize(String.downcase(key)), val}
  # end

  # def atomize(key) do
  #   try do
  #     String.to_atom(key)
  #   rescue
  #     ArgumentError -> Logger.warn("Map Signal with unknown Values found!")
  #   end
  # end
end
