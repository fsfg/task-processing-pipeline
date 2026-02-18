defmodule TaskPipeline.Workers.Report do
  @moduledoc """
  TaskPipeline report task worker
  """
  use Oban.Worker, queue: :report

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_id" => task_id} = _args}) do
    IO.puts("Processing report task: #{task_id}")

    :ok
  end
end
