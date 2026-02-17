defmodule TaskPipeline.Nodes do
  @moduledoc """
  The Nodes context.
  """

  import Ecto.Query, warn: false
  alias TaskPipeline.Nodes.NodeInstance
  alias TaskPipeline.Repo

  @doc """
  Returns the list of nodes.

  ## Examples

      iex> list_nodes()
      [%NodeInstance{}, ...]

  """
  def list_nodes do
    Repo.all(NodeInstance)
  end

  @doc """
  Gets a single node_instance.

  Raises `Ecto.NoResultsError` if the Node instance does not exist.

  ## Examples

      iex> get_node_instance!(123)
      %NodeInstance{}

      iex> get_node_instance!(456)
      ** (Ecto.NoResultsError)

  """
  def get_node_instance!(id), do: Repo.get!(NodeInstance, id)

  @doc """
  Creates a node_instance.

  ## Examples

      iex> create_node_instance(%{field: value})
      {:ok, %NodeInstance{}}

      iex> create_node_instance(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_node_instance(attrs) do
    %NodeInstance{}
    |> NodeInstance.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a node_instance.

  ## Examples

      iex> update_node_instance(node_instance, %{field: new_value})
      {:ok, %NodeInstance{}}

      iex> update_node_instance(node_instance, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_node_instance(%NodeInstance{} = node_instance, attrs) do
    node_instance
    |> NodeInstance.changeset(attrs)
    |> Repo.update()
  end

  def update_node_instance_last_active(id, last_active \\ DateTime.utc_now()) do
    {:ok, _} =
      %NodeInstance{id: id}
      |> NodeInstance.last_active_changeset(%{last_active: last_active})
      |> Repo.update()

    :ok
  end

  @doc """
  Deletes a node_instance.

  ## Examples

      iex> delete_node_instance(node_instance)
      {:ok, %NodeInstance{}}

      iex> delete_node_instance(node_instance)
      {:error, %Ecto.Changeset{}}

  """
  def delete_node_instance(%NodeInstance{} = node_instance) do
    Repo.delete(node_instance)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking node_instance changes.

  ## Examples

      iex> change_node_instance(node_instance)
      %Ecto.Changeset{data: %NodeInstance{}}

  """
  def change_node_instance(%NodeInstance{} = node_instance, attrs \\ %{}) do
    NodeInstance.changeset(node_instance, attrs)
  end
end
