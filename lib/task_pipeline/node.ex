defmodule TaskPipeline.Node do
  alias TaskPipeline.LazyPersistentConfigBehaviour
  use LazyPersistentConfigBehaviour

  @impl LazyPersistentConfigBehaviour
  def compute_value() do
    Ecto.UUID.generate()
  end
end
