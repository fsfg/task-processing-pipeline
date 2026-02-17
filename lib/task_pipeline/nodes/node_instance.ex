defmodule TaskPipeline.Nodes.NodeInstance do
  use TaskPipeline.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :title, :string
    field :last_active, :utc_datetime_usec

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(node_instance, attrs) do
    node_instance
    |> cast(attrs, [:title, :last_active])
    |> validate_required([:title, :last_active])
  end

  @doc false
  def last_active_changeset(node_instance, attrs) do
    node_instance
    |> cast(attrs, [:last_active])
    |> validate_required([:last_active])
  end
end
