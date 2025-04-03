defmodule FireSaga.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      FireSaga.Repo,
      {Oban, Application.get_env(:fire_saga, Oban)}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
