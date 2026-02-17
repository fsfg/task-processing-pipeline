defmodule TaskPipeline.Repo.Migrations.CreateNodes do
  use Ecto.Migration

  def change do
    create table(:nodes) do
      add :title, :text
      add :last_active, :utc_datetime_usec

      timestamps(updated_at: false)
    end

    create index(:nodes, [:last_active])
  end
end
