defmodule TaskPipelineWeb.TaskController do
  use TaskPipelineWeb, :controller

  alias Ecto.Changeset
  alias TaskPipeline.Metrics
  alias TaskPipeline.QueryParams
  alias TaskPipeline.Tasks
  alias TaskPipeline.Tasks.Task

  action_fallback TaskPipelineWeb.FallbackController

  def index(conn, params) do
    with {:ok, valid_params} <- Changeset.apply_action(QueryParams.changeset(params), :validate) do
      tasks = Tasks.list_tasks(valid_params)

      cursor_params =
        for field <- QueryParams.filter_keys(), valid_params[field] != :not_set, into: %{} do
          {field, valid_params[field]}
        end

      cursor_params =
        if Enum.any?(tasks) do
          %Task{id: id} = List.last(tasks)
          Map.put(cursor_params, :id, id)
        else
          cursor_params
        end

      cursor = cursor_params |> Jason.encode!() |> Base.encode64()

      render(conn, :index, tasks: tasks, cursor: cursor)
    end
  end

  def create(conn, %{"task" => task_params}) do
    with {:ok, %Task{} = task} <- Tasks.create_task(task_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/tasks/#{task}")
      |> render(:show_brief, task: task)
    else
      {:error, :task, changeset, _} -> {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    task = Tasks.get_task_with_progress!(id)
    render(conn, :show_full, task: task)
  end

  def summary(conn, _) do
    render(conn, :summary, info: Tasks.get_summary())
  end

  def metrics(conn, _) do
    render(conn, :metrics, data: Metrics.get_metrics())
  end
end
