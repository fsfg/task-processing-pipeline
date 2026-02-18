defmodule TaskPipeline.Workers.Cleanup do
  @moduledoc """
  TaskPipeline cleanup task worker
  """
  use Oban.Worker, queue: :cleanup

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_id" => task_id} = _args}) do
    IO.puts("Processing cleanup task: #{task_id}")

    :ok
  end
end
