defmodule KrakenX.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: KrakenX.Worker.start_link(arg)
      {KrakenX.Futures.WebSocket.Agent, []}
      # {KrakenX.Futures, %{channels: [], debug: [:trace]}}
      # Add debug: [:trace] to see the WebSocket Debug Messages.
      # {KrakenX.Futures, %{channels: ["pi_ethusd"], require_auth: true, debug: []}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KrakenX.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
