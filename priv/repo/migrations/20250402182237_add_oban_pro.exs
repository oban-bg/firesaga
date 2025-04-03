defmodule FireSaga.Repo.Migrations.AddObanPro do
  use Ecto.Migration

  def up do
    Oban.Pro.Migration.up()
  end
end
