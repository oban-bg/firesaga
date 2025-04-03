defmodule FireSaga.Repo do
  use Ecto.Repo,
    otp_app: :fire_saga,
    adapter: Ecto.Adapters.Postgres
end
