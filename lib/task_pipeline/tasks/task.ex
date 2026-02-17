defmodule TaskPipeline.Tasks.Task do
  use TaskPipeline.Schema
  import Ecto.Changeset
  alias TaskPipeline.Tasks.TaskStatuses

  schema "tasks" do
    field :title, :string
    field :type, Ecto.Enum, values: [:import, :export, :report, :cleanup]
    field :priority, Ecto.Enum, values: [low: 3, normal: 2, high: 1, critical: 0]
    field :payload, :map
    field :max_attempts, :integer
    field :status, Ecto.Enum, values: TaskStatuses.all_statuses(), default: :queued
    field :version, :integer, default: 1

    timestamps()
  end

  @doc false
  def create_changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :type, :priority, :payload, :max_attempts])
    |> validate_required([:title, :type, :priority, :payload])
  end

  @doc false
  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> optimistic_lock(:version)
  end
end
