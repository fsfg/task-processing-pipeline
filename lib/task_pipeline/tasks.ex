defmodule TaskPipeline.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias TaskPipeline.Tasks.TaskProgress
  alias TaskPipeline.Repo

  alias TaskPipeline.Tasks.Task

  alias Ecto.Multi

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  def list_tasks(params) do
    filtered_params =
      params |> Enum.reject(fn {_, value} -> value == :not_set end) |> Enum.into(%{})

    per_page = Map.fetch!(filtered_params, :per_page)

    from(t in Task)
    |> maybe_filter_by(:status, filtered_params)
    |> maybe_filter_by(:priority, filtered_params)
    |> maybe_filter_by(:type, filtered_params)
    |> maybe_filter_by_id(filtered_params)
    |> limit(^per_page)
    |> order_by([t], asc: t.priority, desc: t.id)
    |> Repo.all()
  end

  defp maybe_filter_by(query, field, params) when is_map_key(params, field) do
    filter = [{field, params[field]}]
    where(query, ^filter)
  end

  defp maybe_filter_by(query, _, _), do: query

  defp maybe_filter_by_id(query, params) when is_map_key(params, :id) do
    id = params[:id]
    where(query, [t], t.id < ^id)
  end

  defp maybe_filter_by_id(query, _), do: query

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
    Multi.new()
    |> Multi.insert(:task, Task.create_changeset(%Task{}, attrs))
    |> Multi.insert(:task_progress, fn %{task: task} ->
      TaskProgress.changeset(%TaskProgress{}, %{
        start_time: DateTime.utc_now(),
        status: task.status,
        task_id: task.id,
        node_id: TaskPipeline.Nodes.CurrentNode.node_id()
      })
    end)
    |> Repo.transact()
  end

  def create_task!(attrs) do
    {:ok, %{task: task}} = create_task(attrs)

    get_task!(task.id)
  end

  def change_status(%Task{} = task, status) do
    task
    |> Task.update_changeset(%{status: status})
    |> Repo.update()
  end

  def get_summary do
    default_values =
      Task |> Ecto.Enum.values(:status) |> Map.from_keys(0)

    from(t in Task, group_by: :status, select: {t.status, count(1)})
    |> Repo.all()
    |> Enum.into(default_values)
  end

  alias TaskPipeline.Tasks.TaskProgress

  @doc """
  Returns the list of task_progress.

  ## Examples

      iex> list_task_progress()
      [%TaskProgress{}, ...]

  """
  def list_task_progress do
    Repo.all(TaskProgress)
  end

  @doc """
  Gets a single task_progress.

  Raises `Ecto.NoResultsError` if the Task progress does not exist.

  ## Examples

      iex> get_task_progress!(123)
      %TaskProgress{}

      iex> get_task_progress!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task_progress!(id), do: Repo.get!(TaskProgress, id)

  @doc """
  Creates a task_progress.

  ## Examples

      iex> create_task_progress(%{field: value})
      {:ok, %TaskProgress{}}

      iex> create_task_progress(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task_progress(attrs) do
    %TaskProgress{}
    |> TaskProgress.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task_progress.

  ## Examples

      iex> update_task_progress(task_progress, %{field: new_value})
      {:ok, %TaskProgress{}}

      iex> update_task_progress(task_progress, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task_progress(%TaskProgress{} = task_progress, attrs) do
    task_progress
    |> TaskProgress.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task_progress.

  ## Examples

      iex> delete_task_progress(task_progress)
      {:ok, %TaskProgress{}}

      iex> delete_task_progress(task_progress)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task_progress(%TaskProgress{} = task_progress) do
    Repo.delete(task_progress)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task_progress changes.

  ## Examples

      iex> change_task_progress(task_progress)
      %Ecto.Changeset{data: %TaskProgress{}}

  """
  def change_task_progress(%TaskProgress{} = task_progress, attrs \\ %{}) do
    TaskProgress.changeset(task_progress, attrs)
  end
end
