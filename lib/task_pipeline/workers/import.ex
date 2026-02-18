defmodule TaskPipeline.Workers.Import do
  @moduledoc """
  TaskPipeline import task worker
  """
  # TODO: unique tasks (preventing duplicate job processing)
  use Oban.Worker, queue: :import

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_id" => task_id} = _args}) do
    IO.puts("Processing import task: #{task_id}")

    :ok
  end
end
