import Config

config :fire_saga, FireSaga.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: "postgres://localhost:5432/fire_saga_test"

config :fire_saga, FireSaga.LLM, plug: {Req.Test, FireSaga.LLM}

config :fire_saga, Oban, testing: :manual
