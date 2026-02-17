defmodule TaskPipelineWeb.TaskJSON do
  alias TaskPipeline.Tasks.Task

  @doc """
  Renders a list of tasks.
  """
  def index(%{tasks: tasks, cursor: cursor}) do
    %{data: for(task <- tasks, do: data(task)), cursor: cursor}
  end

  @doc """
  Renders a single task.
  """
  def show(%{task: task}) do
    %{data: data(task)}
  end

  defp data(%Task{} = task) do
    %{
      id: task.id,
      title: task.title,
      type: task.type,
      priority: task.priority,
      payload: task.payload,
      max_attempts: task.max_attempts,
      status: task.status,
      version: task.version
    }
  end

  def summary(%{info: info}) do
    %{data: info}
  end
end
