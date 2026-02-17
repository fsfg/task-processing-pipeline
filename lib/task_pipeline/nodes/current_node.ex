defmodule TaskPipeline.Nodes.CurrentNode do
  alias TaskPipeline.LazyPersistentConfigBehaviour
  alias TaskPipeline.Nodes.NodeInstance
  use LazyPersistentConfigBehaviour

  @impl LazyPersistentConfigBehaviour
  def compute_value() do
    {:ok, %NodeInstance{} = instance} =
      TaskPipeline.Nodes.create_node_instance(%{
        title: Node.self() |> Atom.to_string(),
        last_active: DateTime.utc_now()
      })

    instance.id
  end

  defdelegate node_id, to: __MODULE__, as: :get_value

  def refresh_last_active() do
    TaskPipeline.Nodes.update_node_instance_last_active(node_id())
  end

  if Mix.env() == :test do
    defoverridable(node_id: 0)
    def node_id(), do: compute_value()
  end
end
