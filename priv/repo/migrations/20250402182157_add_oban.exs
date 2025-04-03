defmodule FireSaga.Repo.Migrations.AddOban do
  use Ecto.Migration

  def up do
    Oban.Migration.up()
  end
end
