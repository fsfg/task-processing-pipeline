defmodule TaskPipeline.Tasks.Task do
  use TaskPipeline.Schema
  import Ecto.Changeset
  alias TaskPipeline.Tasks.{TaskPriorities, TaskProgress, TaskStatuses}

  @type t() :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          type: atom(),
          priority: atom(),
          payload: %{optional(String.t()) => any()},
          max_attempts: integer(),
          status: atom(),
          version: integer(),
          progress: Ecto.Association.NotLoaded.t() | [TaskProgress.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "tasks" do
    field :title, :string
    field :type, Ecto.Enum, values: [:import, :export, :report, :cleanup]
    field :priority, Ecto.Enum, values: TaskPriorities.all_priorities()
    field :payload, :map
    field :max_attempts, :integer, default: 3
    field :status, Ecto.Enum, values: TaskStatuses.all_statuses(), default: :queued
    field :version, :integer, default: 1
    has_many :progress, TaskProgress, preload_order: [asc: :id]

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
