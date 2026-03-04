defmodule TaskPipeline.Workers.Cleanup do
  @moduledoc """
  TaskPipeline cleanup task worker
  """
  alias TaskPipeline.Workers.CustomWorker
  use CustomWorker, queue: :cleanup

  @impl CustomWorker
  def process_task(task) do
    IO.puts("Processing cleanup task: #{task.id}")

    TaskPipeline.Workers.Dummy.perform(task)
  end
end
