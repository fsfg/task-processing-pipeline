defmodule TaskPipeline.Tasks.TaskProgress do
  use TaskPipeline.Schema
  import Ecto.Changeset
  alias TaskPipeline.Nodes.NodeInstance
  alias TaskPipeline.Tasks.{Task, TaskStatuses}

  @type t() :: %__MODULE__{
          id: String.t(),
          start_time: DateTime.t(),
          end_time: DateTime.t(),
          status: atom(),
          metadata: %{optional(String.t()) => any()},
          task_id: String.t(),
          task: Ecto.Association.NotLoaded.t() | Task.t(),
          node_id: String.t(),
          node: Ecto.Association.NotLoaded.t() | NodeInstance.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "task_progress" do
    field :start_time, :utc_datetime_usec
    field :end_time, :utc_datetime_usec
    field :status, Ecto.Enum, values: TaskStatuses.all_statuses()
    field :metadata, :map
    belongs_to :task, TaskPipeline.Tasks.Task
    belongs_to :node, TaskPipeline.Nodes.NodeInstance

    timestamps()
  end

  @doc false
  def changeset(task_progress, attrs) do
    task_progress
    |> cast(attrs, [:start_time, :end_time, :status, :metadata, :task_id, :node_id])
    |> foreign_key_constraint(:task)
    |> foreign_key_constraint(:node)
    |> validate_required([:start_time, :status])
  end
end
