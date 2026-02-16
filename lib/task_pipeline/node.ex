defmodule TaskPipeline.Node do
  def get_id do
    case :persistent_term.get(__MODULE__, :not_set) do
      :not_set ->
        generate_node_id()

      binary when is_binary(binary) ->
        binary
    end
  end

  defp generate_node_id do
    :persistent_term.put(__MODULE__, Ecto.UUID.generate())

    :persistent_term.get(__MODULE__)
  end
end
