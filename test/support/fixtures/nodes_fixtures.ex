defmodule TaskPipeline.NodesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskPipeline.Nodes` context.
  """

  @doc """
  Generate a node_instance.
  """
  def node_instance_fixture(attrs \\ %{}) do
    {:ok, node_instance} =
      attrs
      |> Enum.into(%{
        last_active: ~U[2026-02-16 17:59:00.000000Z],
        title: "some title"
      })
      |> TaskPipeline.Nodes.create_node_instance()

    node_instance
  end
end
