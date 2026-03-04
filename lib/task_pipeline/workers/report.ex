defmodule TaskPipeline.Workers.Report do
  @moduledoc """
  TaskPipeline report task worker
  """
  alias TaskPipeline.Workers.CustomWorker
  use CustomWorker, queue: :report

  @impl CustomWorker
  def process_task(task) do
    IO.puts("Processing report task: #{task.id}")

    TaskPipeline.Workers.Dummy.perform(task)
  end
end
