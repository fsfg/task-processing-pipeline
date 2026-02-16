defmodule TaskPipeline.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :text, null: false
      add :type, :string, null: false, size: 32
      add :priority, :integer, null: false
      add :payload, :map, null: false
      add :max_attempts, :integer, default: 3
      add :status, :string, null: false, size: 12, default: "queued"
      add :version, :integer, default: 1

      timestamps()
    end

    create index(:tasks, ["priority ASC", "id DESC", :type, :status])
    create index(:tasks, [:status, "priority ASC", "id DESC"])
  end
end
