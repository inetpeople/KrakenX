defmodule KrakenX.Futures.WebSocket do
  use WebSockex
  import Logger, only: [info: 1, warn: 1]
  alias __MODULE__.Agent

  defmacro __using__(_opts) do
    quote do
      use WebSockex
      @base "wss://futures.kraken.com/ws/v1"

      def start_link(args \\ %{}) do
        name = args[:name] || __MODULE__
        state = Map.merge(args, %{heartbeat: 0})
        debug = args[:debug]
        {:ok, pid} = WebSockex.start_link(@base, __MODULE__, state, name: name, debug: debug)
      end

      ######
      ### Interface
      ######
      def subscribe_channels(pid, channels) do
        info("Subscribed to channels.")
        WebSockex.send_frame(pid, channels_frame(channels))
      end

      def unsubscribe_ticker(pid, products) do
        WebSockex.send_frame(pid, ticker_unsubscribe_frame(products))
      end

      def heartbeat(pid) do
        WebSockex.send_frame(pid, heartbeat_frame())
      end

      def heartbeat_unsubscribe(pid) do
        WebSockex.send_frame(pid, heartbeat_unsubscribe_frame())
      end

      def get_challenge(pid) do
        WebSockex.send_frame(pid, challenge_frame())
      end

      def get_open_positions(pid) do
        WebSockex.send_frame(pid, open_positions_frame())
      end

      def get_account_balances_and_margins(pid) do
        WebSockex.send_frame(pid, account_balances_and_margins_frame())
      end

      def get_open_orders_verbose(pid) do
        WebSockex.send_frame(pid, open_orders_verbose_frame())
      end

      def get_open_orders(pid) do
        WebSockex.send_frame(pid, open_orders_frame())
      end

      ######
      ### Callbacks
      ######

      @impl true
      def handle_connect(conn, state) do
        :ok = info("WebSocket sucessfully connected with Kraken Futures WebSocket!")

        send(self(), :heartbeat)
        send(self(), :get_challenge)
        send(self(), :subscribe_channels)

        {:ok, state}
      end

      @impl true
      def handle_info(:get_challenge, state) do
        {:reply, challenge_frame(), state}
      end

      @impl true
      def handle_info(:heartbeat, state) do
        {:reply, heartbeat_frame(), state}
      end

      @impl true
      def handle_info(:subscribe_channels, %{channels: channels} = state) do
        {:reply, channels_frame(channels), state}
      end

      @impl true
      def handle_frame({:text, msg}, state) do
        msg
        |> Jason.decode!()
        |> handle_response(state)
      end

      @impl true
      def handle_disconnect(_conn, state) do
        warn("Kraken Futures WebSocket disconnected! Reconnecting...")
        {:ok, state}
      end

      def handle_response(
            %{"event" => "challenge", "message" => original_challenge} = _msg,
            state
          ) do
        hash = :crypto.hash(:sha256, original_challenge)
        secret = Base.decode64!(System.get_env("KrakenFuturesPrivate"))
        signed_challenge = :crypto.hmac(:sha512, secret, hash) |> Base.encode64()
        Agent.put(Agent, :original_challenge, original_challenge)
        Agent.put(Agent, :signed_challenge, signed_challenge)
        {:ok, state}
      end

      def handle_response(%{"feed" => "heartbeat", "time" => time} = msg, state) do
        # utc_time = DateTime.from_unix!(time, :millisecond)
        # info("received heartbeat at #{utc_time}")
        state = %{state | heartbeat: state.heartbeat + 1}

        {:ok, state}
      end

      def handle_response(%{"feed" => "ticker", "product_id" => _product_id} = msg, state) do
        broadcast!("krakenx_futures", "tickers", msg)
        {:ok, state}
      end

      def handle_response(
            %{"event" => "subscribed", "feed" => "ticker", "product_ids" => product_ids} = msg,
            state
          ) do
        Enum.each(product_ids, fn x -> info("Ticker Feed for: #{x}") end)
        broadcast!("krakenx_futures", "subscribed_tickers", msg)
        {:ok, state}
      end

      def handle_response(%{"feed" => "account_balances_and_margins"} = msg, state) do
        info("Subscribed to Accoounts, Balances and Margins")
        broadcast!("krakenx_futures", "account_balances_and_margins", msg)
        {:ok, state}
      end

      def handle_response(%{"feed" => "open_positions"} = msg, state) do
        info("Subscribed to Open Positions")
        broadcast!("krakenx_futures", "open_positions", msg)
        {:ok, state}
      end

      def handle_response(%{"feed" => "open_orders_verbose_snapshot"} = msg, state) do
        info("Subscribed to Open Orders Verbose")
        broadcast!("krakenx_futures", "open_orders_verbose", msg)
        {:ok, state}
      end

      def handle_response(%{"feed" => "open_orders_snapshot"} = msg, state) do
        info("Subscribed to Open Orders")
        broadcast!("krakenx_futures", "open_orders", msg)
        {:ok, state}
      end

      def handle_response(%{"event" => "unsubscribed", "feed" => feed} = msg, state) do
        warn("Unsubscribed from #{feed}")
        broadcast!("krakenx_futures", "unsubscribed", msg)
        {:ok, state}
      end

      def handle_response(%{"event" => "error", "message" => message} = msg, state) do
        warn("Error: #{message}")
        broadcast!("krakenx_futures", "error", msg)
        {:ok, state}
      end

      def handle_response(resp, state) do
        :ok = info("#{__MODULE__} received response: #{inspect(resp)}")
        {:ok, state}
      end

      def broadcast!(topic, event, msg) do
        warn("Please define a custom broadcast! function. See Docs.")
      end

      ### private

      defp account_balances_and_margins_frame() do
        subscription_msg =
          %{
            event: "subscribe",
            feed: "account_balances_and_margins",
            api_key: System.get_env("KrakenFuturesPublic"),
            original_challenge: Agent.get(Agent, :original_challenge),
            signed_challenge: Agent.get(Agent, :signed_challenge)
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp challenge_frame() do
        subscription_msg =
          %{
            event: "challenge",
            api_key: System.get_env("KrakenFuturesPublic")
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp open_orders_verbose_frame() do
        subscription_msg =
          %{
            event: "subscribe",
            feed: "open_orders_verbose",
            api_key: System.get_env("KrakenFuturesPublic"),
            original_challenge: Agent.get(Agent, :original_challenge),
            signed_challenge: Agent.get(Agent, :signed_challenge)
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp open_orders_frame() do
        subscription_msg =
          %{
            event: "subscribe",
            feed: "open_orders",
            api_key: System.get_env("KrakenFuturesPublic"),
            original_challenge: Agent.get(Agent, :original_challenge),
            signed_challenge: Agent.get(Agent, :signed_challenge)
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp open_positions_frame() do
        subscription_msg =
          %{
            event: "subscribe",
            feed: "open_positions",
            api_key: System.get_env("KrakenFuturesPublic"),
            original_challenge: Agent.get(Agent, :original_challenge),
            signed_challenge: Agent.get(Agent, :signed_challenge)
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp heartbeat_frame() do
        subscription_msg =
          %{
            event: "subscribe",
            feed: "heartbeat"
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp heartbeat_unsubscribe_frame() do
        subscription_msg =
          %{
            event: "unsubscribe",
            feed: "heartbeat"
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp channels_frame(product_ids) when is_list(product_ids) do
        subscription_msg =
          %{
            event: "subscribe",
            feed: "ticker",
            product_ids: product_ids
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp ticker_unsubscribe_frame(product_ids) when is_list(product_ids) do
        subscription_msg =
          %{
            event: "unsubscribe",
            feed: "ticker",
            product_ids: product_ids
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defoverridable handle_connect: 2, handle_disconnect: 2, handle_response: 2, broadcast!: 3
    end
  end
end
