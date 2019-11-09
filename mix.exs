defmodule KrakenX.MixProject do
  use Mix.Project

  def project do
    [
      app: :kraken_x,
      version: "0.1.1",
      elixir: "~> 1.9",
      deps: deps(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Postgrex",
      source_url: "https://github.com/elixir-ecto/postgrex"
    ]
  end

  defp description do
  end

  defp package do
    [
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KrakenX.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:websockex, "~> 0.4.2"},
      {:httpoison, "~> 1.6"}
    ]
  end
end
