defmodule TaskPipeline.Repo.Migrations.CreateTaskProgress do
  use Ecto.Migration

  def change do
    create table(:task_progress) do
      add :start_time, :utc_datetime_usec, null: false
      add :end_time, :utc_datetime_usec
      add :status, :string, null: false
      add :metadata, :map
      add :task_id, references(:tasks, on_delete: :nothing), null: false
      add :node_id, references(:nodes, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:task_progress, [:task_id, :status, :id, :end_time])
    create index(:task_progress, [:node_id])
  end
end
