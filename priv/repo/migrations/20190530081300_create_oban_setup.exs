defmodule Omen.Repo.Migrations.CreateObanSetup do
  use Ecto.Migration

  defdelegate up, to: Oban.Migrations
  defdelegate down, to: Oban.Migrations
end
