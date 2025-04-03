import Config

config :logger, level: :info

config :fire_saga, ecto_repos: [FireSaga.Repo]

config :fire_saga, FireSaga.Repo,
  url: "postgres://localhost:5432/fire_saga_dev"

config :fire_saga, Oban,
  engine: Oban.Pro.Engines.Smart,
  notifier: Oban.Notifiers.PG,
  queues: [default: 10],
  repo: FireSaga.Repo

if File.exists?("#{__DIR__}/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end
