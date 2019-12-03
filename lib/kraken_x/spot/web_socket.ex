defmodule KrakenX.Spot.WebSocket do
  use WebSockex
  import Logger, only: [info: 1, warn: 1]
  # alias __MODULE__.Agent

  defmacro __using__(_opts) do
    quote do
      use WebSockex

      # Once the socket is open you can subscribe to a public channel by sending a subscribe request message.
      @public_base "wss://ws.kraken.com/"

      # Once the socket is open you can subscribe to both public and private channels by sending a subscribe request message.
      @auth_base "wss://ws-auth.kraken.com/"
      # @auth_test_base "wss://beta-ws.kraken.com/"

      def start_link(args \\ %{}) do
        name = args[:name] || __MODULE__
        state = Map.merge(args, %{heartbeat: 0})
        debug = args[:debug]

        {:ok, pid} =
          WebSockex.start_link(@public_base, __MODULE__, state, name: name, debug: debug)
      end

      ######
      ### Interface
      ######

      ######
      ### Callbacks
      ######
      @impl true
      def handle_connect(conn, state) do
        :ok = info("WebSocket sucessfully connected with Kraken WebSocket!")

        # send(self(), :heartbeat)
        send(self(), :ping)
        send(self(), :subscribe_tickers)
        # send(self(), :subscribe_channels)

        {:ok, state}
      end

      @impl true
      def handle_info(:ping, state) do
        {:reply, ping_frame(), state}
      end

      @impl true
      def handle_info(:subscribe_tickers, state) do
        {:reply, subscribe_tickers_frame(), state}
      end

      # not in tje api
      # def handle_info(:heartbeat, state) do
      #   {:reply, heartbeat_frame(), state}
      # end

      @impl true
      def handle_frame({:text, msg}, state) do
        msg
        |> Jason.decode!()
        |> handle_response(state)
      end

      def handle_response(%{"event" => "pong", "reqid" => reqid} = msg, state) do
        info(reqid)
        {:ok, state}
      end

      def handle_response(
            %{
              "channelID" => channel_id,
              "channelName" => channel_name,
              "event" => "subscriptionStatus",
              "pair" => pair,
              "status" => status,
              "reqid" => reqid,
              "subscription" => subscription
            } = msg,
            state
          ) do
        info("Subscribed to #{channel_id} with request_id: #{reqid}")
        {:ok, state}
      end

      def handle_response(%{"event" => "heartbeat"} = msg, state) do
        info("Heartbeat received from Kraken Spot Websocket.")
        {:ok, state}
      end

      def handle_response(
            %{
              "connectionID" => conn_id,
              "event" => "systemStatus",
              "status" => status,
              "version" => version
            } = msg,
            state
          ) do
        info("Kraken Spot Websocket is: #{status} with id: #{conn_id} and version: #{version}")
        {:ok, state}
      end

      def handle_response(
            [channel_id, price_data, channel_name, pair] = msg,
            state
          ) do
        info("Data from #{channel_name} for the pair #{pair} received.")
        {:ok, state}
      end

      def handle_response(
            %{
              event: "addOrderStatus",
              status: "ok",
              txid: txid,
              descr: descr
            } = msg,
            state
          ) do
        info("Add Order #{txid} successful.")
        {:ok, state}
      end

      def handle_response(
            %{
              event: "addOrderStatus",
              status: "error",
              errorMessage: error_message
            } = msg,
            state
          ) do
        info("Add Order failed with #{error_message}.")
        {:ok, state}
      end

      @impl true
      def handle_disconnect(_conn, state) do
        warn("Kraken WebSocket disconnected! Reconnecting...")
        {:ok, state}
      end

      defp ping_frame() do
        subscription_msg =
          %{
            event: "ping",
            reqid: 42
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp subscribe_tickers_frame do
        subscription_msg =
          %{
            event: "subscribe",
            reqid: 1,
            pair: ["XBT/USD", "ETH/USD"],
            subscription: %{
              name: "ticker"
            }
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp add_order_frame do
        subscription_msg =
          %{
            event: "addOrder",
            token: "0000000000000000000000000000000000000000",
            ordertype: "limit",
            # side, buy, sell
            type: "buy",
            pair: "XBT/USD",
            price: "9000",
            price2: "",
            volume: "10",
            leverage: "none",
            oflags: "",
            starttm: "",
            expiretm: "",
            userref: "",
            validate: ""
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      def add_close_order_frame do
        subscription_msg =
          %{
            "close[ordertype]" => "limit",
            "close[price]" => "9100",
            "close[price2]" => "9100",
            "event" => "addOrder",
            "ordertype" => "limit",
            "pair" => "XBT/USD",
            "price" => "9000",
            "token" => "0000000000000000000000000000000000000000",
            "type" => "buy",
            "volume" => "10"
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      def cancel_order_frame(txid) when txid(is_list) do
        subsciption_msg =
          %{
            event: "cancelOrder",
            token: "0000000000000000000000000000000000000000",
            txid: txid
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end

      defp unsubscribe_tickers_frame do
        subscription_msg =
          %{
            event: "unsubscribe",
            pair: ["XBT/USD", "XBT/EUR"],
            subscription: %{
              name: "ticker"
            }
          }
          |> Jason.encode!()

        {:text, subscription_msg}
      end
    end
  end
end
