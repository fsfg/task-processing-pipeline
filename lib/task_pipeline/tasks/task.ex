defmodule TaskPipeline.Tasks.Task do
  alias __MODULE__
  alias Ecto.Changeset
  alias TaskPipeline.Tasks.{TaskPriorities, TaskProgress, TaskStatuses}

  import Changeset

  use TaskPipeline.Schema

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
    |> validate_statuses_flow()
    |> optimistic_lock(:version)
  end

  @valid_status_transitions_mapping %{
    queued: [:processing],
    processing: [:queued, :completed, :failed],
    completed: [],
    failed: []
  }

  @spec validate_statuses_flow(changeset :: Changeset.t(t())) :: Changeset.t(t())
  defp validate_statuses_flow(%Changeset{changes: %{status: _}} = changeset) do
    %Changeset{
      data: %Task{status: status},
      changes: %{status: new_status}
    } = changeset

    valid_transition =
      @valid_status_transitions_mapping
      |> Map.fetch!(status)
      |> Enum.member?(new_status)

    if valid_transition do
      changeset
    else
      changeset
      |> delete_change(:status)
      |> add_error(:status, "invalid status transition")
    end
  end

  defp validate_statuses_flow(%Changeset{} = changeset), do: changeset
end
