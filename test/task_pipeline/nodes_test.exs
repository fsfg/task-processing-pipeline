defmodule TaskPipeline.NodesTest do
  use TaskPipeline.DataCase

  alias TaskPipeline.Nodes

  describe "nodes" do
    alias TaskPipeline.Nodes.NodeInstance

    import TaskPipeline.NodesFixtures

    @invalid_attrs %{title: nil, last_active: nil}

    test "list_nodes/0 returns all nodes" do
      node_instance = node_instance_fixture()
      assert Nodes.list_nodes() == [node_instance]
    end

    test "get_node_instance!/1 returns the node_instance with given id" do
      node_instance = node_instance_fixture()
      assert Nodes.get_node_instance!(node_instance.id) == node_instance
    end

    test "create_node_instance/1 with valid data creates a node_instance" do
      valid_attrs = %{title: "some title", last_active: ~U[2026-02-16 17:59:00.000000Z]}

      assert {:ok, %NodeInstance{} = node_instance} = Nodes.create_node_instance(valid_attrs)
      assert node_instance.title == "some title"
      assert node_instance.last_active == ~U[2026-02-16 17:59:00.000000Z]
    end

    test "create_node_instance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Nodes.create_node_instance(@invalid_attrs)
    end

    test "update_node_instance/2 with valid data updates the node_instance" do
      node_instance = node_instance_fixture()
      update_attrs = %{title: "some updated title", last_active: ~U[2026-02-17 17:59:00.000000Z]}

      assert {:ok, %NodeInstance{} = node_instance} = Nodes.update_node_instance(node_instance, update_attrs)
      assert node_instance.title == "some updated title"
      assert node_instance.last_active == ~U[2026-02-17 17:59:00.000000Z]
    end

    test "update_node_instance/2 with invalid data returns error changeset" do
      node_instance = node_instance_fixture()
      assert {:error, %Ecto.Changeset{}} = Nodes.update_node_instance(node_instance, @invalid_attrs)
      assert node_instance == Nodes.get_node_instance!(node_instance.id)
    end

    test "delete_node_instance/1 deletes the node_instance" do
      node_instance = node_instance_fixture()
      assert {:ok, %NodeInstance{}} = Nodes.delete_node_instance(node_instance)
      assert_raise Ecto.NoResultsError, fn -> Nodes.get_node_instance!(node_instance.id) end
    end

    test "change_node_instance/1 returns a node_instance changeset" do
      node_instance = node_instance_fixture()
      assert %Ecto.Changeset{} = Nodes.change_node_instance(node_instance)
    end
  end
end
