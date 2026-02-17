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
    default_values =
      Task |> Ecto.Enum.values(:status) |> Map.from_keys(0)

    from(t in Task, group_by: :status, select: {t.status, count(1)})
    |> Repo.all()
    |> Enum.into(default_values)
  end
end
