defmodule TaskPipelineWeb.TaskJSON do
  alias TaskPipeline.Tasks.Task
  alias TaskPipeline.Tasks.TaskProgress

  @doc """
  Renders a list of tasks.
  """
  def index(%{tasks: tasks, cursor: cursor}) do
    %{data: for(task <- tasks, do: brief_task_data(task)), cursor: cursor}
  end

  def show_brief(%{task: task}) do
    %{data: brief_task_data(task)}
  end

  def show_full(%{task: task}) do
    %{data: full_task_data(task)}
  end

  defp brief_task_data(%Task{} = task) do
    %{
      id: task.id,
      title: task.title,
      type: task.type,
      priority: task.priority,
      status: task.status
    }
  end

  defp full_task_data(%Task{} = task) do
    task
    |> brief_task_data()
    |> Map.merge(%{
      payload: task.payload,
      max_attempts: task.max_attempts,
      progress: Enum.map(task.progress, &task_progress_data/1)
    })
  end

  defp task_progress_data(%TaskProgress{} = progress) do
    %{
      id: progress.id,
      status: progress.status,
      start_time: progress.start_time,
      end_time: progress.end_time,
      node_id: progress.node_id,
      metadata: progress.metadata
    }
  end

  def summary(%{info: info}) do
    %{data: info}
  end

  def metrics(%{data: data}) do
    %{data: data}
  end
end
