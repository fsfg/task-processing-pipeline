defmodule TaskPipeline.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias TaskPipeline.Repo

  alias TaskPipeline.Tasks.Task

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs) do
    %Task{}
    |> Task.create_changeset(attrs)
    |> Repo.insert()
  end

  def create_task!(attrs) do
    {:ok, task} = create_task(attrs)
    get_task!(task.id)
  end

  def change_status(%Task{} = task, status) do
    task
    |> Task.update_changeset(%{status: status})
    |> Repo.update()
  end

  def get_summary do
    from(t in Task, group_by: :status, select: {t.status, count(1)})
    |> Repo.all()
    |> Enum.into(%{})
  end
end
