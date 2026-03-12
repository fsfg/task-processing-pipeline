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

  @doc """
  Get current node uptime in seconds
  """
  def uptime() do
    now = System.monotonic_time(:second)

    case :persistent_term.get({__MODULE__, :uptime}, :not_set) do
      :not_set ->
        :persistent_term.put({__MODULE__, :uptime}, now)
        0

      uptime ->
        now - uptime
    end
  end

  if Mix.env() == :test do
    defoverridable(node_id: 0)

    def node_id() do
      case Process.get(__MODULE__, :not_set) do
        :not_set ->
          Process.put(__MODULE__, compute_value())
          Process.get(__MODULE__)

        data ->
          data
      end
    end
  end
end
