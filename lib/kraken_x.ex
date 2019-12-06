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
    trades = Krakex.trades(pair, since: since)

    case trades do
      {:ok, res} ->
        last = res["last"]
        [pair, _] = Map.keys(res)
        trades = res[pair]
        {pair, trades, last}

      {:error, error} ->
        warn("Boss, we get an error: #{error}. I will try again, oklah?")
        get_historical_trades_since(pair, since)
    end
  end

  def get_all_historical_trades(pair) do
    if String.length(pair) < 8 do
      raise ArgumentError, message: "Please use with 8 letter pair, like: XETHZUSD"
    end

    p = String.upcase(pair)
    file = File.read("./#{p}_history.txt")

    case file do
      {:ok, file_content} ->
        {pair, old_trades, last} =
          file_content
          |> :erlang.binary_to_term()

        warn(
          "read: https://www.bignerdranch.com/blog/elixir-and-io-lists-part-2-io-lists-in-phoenix/"
        )

        {npair, new_trades, nlast} = get_historical_trades_since(pair, "#{last}")
        trades = [new_trades | old_trades]
        # req_time = DateTime.utc_now()
        get_trades(npair, nlast, trades, last)

      {:error, :enoent} ->
        {pair, trades, last} = get_historical_trades_since(pair, "0")
        warn("No file found, starting back in time!")
        get_trades(pair, last, trades, "0")

      _ ->
        {:error}
    end

    info("Got all your data, Sayan")
    info("finished!!")
  end

  defp get_trades(pair, last, acc, req_time) do
    # [_, _, time, _, _, _] = List.last(acc)
    # last_trade = DateTime.from_unix!(trunc(time))

    if last == req_time do
      file_content = {pair, acc, last}
      File.write!("./#{pair}_history.txt", :erlang.term_to_binary(file_content))
      {pair, acc, last}
    else
      t = last |> String.to_integer()
      {:ok, time} = System.convert_time_unit(t, :native, :second) |> DateTime.from_unix()
      info("run again #{last} #{time}, i'm not ready yet. Kopi (coffee) time?")
      {npair, ntrades, nlast} = get_historical_trades_since(pair, last)
      nacc = ntrades ++ acc
      file_content = {npair, nacc, nlast}
      File.write!("./#{pair}_history.txt", :erlang.term_to_binary(file_content))
      Process.sleep(3000)
      get_trades(npair, nlast, nacc, last)
    end
  end
end
