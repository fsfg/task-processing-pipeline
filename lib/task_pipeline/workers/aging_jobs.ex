defmodule TaskPipeline.Workers.AgingJobs do
  @moduledoc """
  Fix "starvation" condition

  Increase priority for jobs that are waiting for too long in the queue
  """
  use Oban.Worker
  import Ecto.Query
  alias TaskPipeline.Repo

  @time_span_hours 2
  @batch 20

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    max_datetime = DateTime.utc_now() |> DateTime.add(-@time_span_hours, :hour)

    Oban.Job
    |> where(state: :available)
    |> where([j], j.scheduled_at < ^max_datetime)
    |> where([j], j.priority > 0)
    |> limit(@batch)
    |> order_by([j], asc: j.id)
    |> Repo.update_all(inc: [priority: -1])

    :ok
  end
end
