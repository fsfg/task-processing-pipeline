defmodule TaskPipeline.Workers.Import do
  @moduledoc """
  TaskPipeline import task worker
  """
  alias TaskPipeline.Workers.CustomWorker
  use CustomWorker, queue: :import

  @impl CustomWorker
  def process_task(task) do
    IO.puts("Processing import task: #{task.id}")

    TaskPipeline.Workers.Dummy.perform(task)
  end
end
