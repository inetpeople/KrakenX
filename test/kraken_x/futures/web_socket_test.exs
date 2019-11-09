defmodule WsWrapper do
  ### from ex_okex lib
  @moduledoc false
  require Logger
  use KrakenX.Futures.WebSocket
end

defmodule KrakenX.Futures.WebSocketTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  setup do
    channels = ["pi_ethusd"]

    {:ok, socket} =
      WsWrapper.start_link(%{
        channels: channels,
        debug: [],
        require_auth: false,
        config: %{access_keys: ["API_KEY", "API_SECRET", "API_PASSPHRASE"]}
      })

    {:ok, socket: socket, state: :sys.get_state(socket)}
  end

  describe "initial state" do
    test "get state", %{state: state} do
      assert state == %{
               channels: ["pi_ethusd"],
               debug: [],
               config: %{
                 access_keys: ["API_KEY", "API_SECRET", "API_PASSPHRASE"]
               },
               heartbeat: 0,
               require_auth: false
             }
    end
  end

  describe "logging" do
    test "it logs connect", %{state: state} do
      assert capture_log(fn -> WsWrapper.handle_connect(%{}, state) end) =~
               "WebSocket sucessfully connected with Kraken Futures WebSocket!"
    end

    test "it logs disconnect", %{state: state} do
      assert capture_log(fn -> WsWrapper.handle_disconnect(%{}, state) end) =~
               "Kraken Futures WebSocket disconnected! Reconnecting..."
    end
  end

  describe "overrides" do
    defmodule WsWrapperOverride do
      @moduledoc false
      require Logger
      use KrakenX.Futures.WebSocket

      def handle_connect(_, _), do: :works
      def handle_disconnect(_, _), do: :works
      def handle_response(_, _), do: :works
      def broadcast!(_, _, _), do: :works
    end

    test "it can override" do
      assert :works == WsWrapperOverride.handle_connect(nil, nil)
      assert :works == WsWrapperOverride.handle_disconnect(nil, nil)
      assert :works == WsWrapperOverride.handle_response(nil, nil)
      assert :works == WsWrapperOverride.broadcast!(nil, nil, nil)
    end
  end
end
