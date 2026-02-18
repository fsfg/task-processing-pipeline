defmodule TaskPipeline.Workers.Export do
  @moduledoc """
  TaskPipeline export task worker
  """
  use Oban.Worker, queue: :export

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_id" => task_id} = _args}) do
    IO.puts("Processing export task: #{task_id}")

    :ok
  end
end
