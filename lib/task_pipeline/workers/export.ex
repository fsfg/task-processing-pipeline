defmodule TaskPipeline.Workers.Export do
  @moduledoc """
  TaskPipeline export task worker
  """
  alias TaskPipeline.Workers.CustomWorker
  use CustomWorker, queue: :export

  @impl CustomWorker
  def process_task(task) do
    IO.puts("Processing export task: #{task.id}")

    TaskPipeline.Workers.Dummy.perform(task)
  end
end
