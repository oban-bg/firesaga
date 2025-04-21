defmodule FireSaga.MixProject do
  use Mix.Project

  def project do
    [
      app: :fire_saga,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {FireSaga.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:plug, "~> 1.17"},
      {:postgrex, "~> 0.20"},
      {:oban, "~> 2.19"},
      {:oban_pro, "~> 1.6.0-rc.3", repo: :oban},
      {:req, "~> 0.5"},
    ]
  end
end
