defmodule TaskPipeline.Tasks do
  @moduledoc """
  The Tasks context.
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias TaskPipeline.Repo
  alias TaskPipeline.PubSub
  alias TaskPipeline.Tasks.Task
  alias TaskPipeline.Tasks.TaskProgress

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
    {:ok, %{task: task} = results} =
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

    task_status_changed(task.id, nil, task.status)

    {:ok, results}
  end

  def create_task!(attrs) do
    {:ok, %{task: task}} = create_task(attrs)

    get_task!(task.id)
  end

  def change_status(%Task{} = task, status) do
    result =
      Multi.new()
      |> Multi.one(:get_old_progress, latest_task_progress(task.id))
      |> Multi.update(:task, Task.update_changeset(task, %{status: status}))
      |> Multi.update(
        :old_task_progress,
        fn %{get_old_progress: old_progress} ->
          TaskProgress.changeset(old_progress, %{end_time: DateTime.utc_now()})
        end
      )
      |> Multi.insert(:new_task_progress, fn %{task: task} ->
        TaskProgress.changeset(%TaskProgress{}, %{
          start_time: DateTime.utc_now(),
          status: task.status,
          task_id: task.id,
          node_id: TaskPipeline.Nodes.CurrentNode.node_id()
        })
      end)
      |> Repo.transact()

    task_status_changed(task.id, task.status, status)

    result
  end

  defp task_status_changed(task_id, from, to) do
    PubSub.broadcast!("tasks", %{id: task_id, from: from, to: to})
    PubSub.broadcast!("task:" <> task_id, %{from: from, to: to})
  end

  def subscribe_task_changes(), do: PubSub.subscribe("tasks")
  def subscribe_task_changes(task_id), do: PubSub.subscribe("tasks" <> task_id)

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
  Gets a latest single task_progress by task_id.

  Raises `Ecto.NoResultsError` if no TaskProgress records was found.

  ## Examples

      iex> get_task_progress_by_task_id!("019c6d48-eb86-7a3d-8ebd-26c08fe5b720")
      %TaskProgress{}

      iex> get_task_progress_by_task_id!(123)
      ** (Ecto.NoResultsError)

  """
  def get_task_progress_by_task_id!(task_id) do
    task_id
    |> latest_task_progress()
    |> Repo.one!()
  end

  defp latest_task_progress(task_id) do
    from(t in TaskProgress)
    |> where(task_id: ^task_id)
    |> order_by([t], desc: t.id)
    |> limit(1)
  end

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
