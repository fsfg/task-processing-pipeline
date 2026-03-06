defmodule TaskPipeline.Workers.StuckTasks do
  @moduledoc """
  Fix stuck "in-flight" jobs - tasks with "processing" status but on dead node
  """
  use Oban.Worker
  import Ecto.Query
  alias TaskPipeline.Nodes.RefreshNodeActivity
  alias TaskPipeline.Repo
  alias TaskPipeline.Tasks
  alias TaskPipeline.Tasks.Task

  @time_span_multiplier 2
  @batch 20

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Repo.transact(&restart_stuck_jobs/0)

    :ok
  end

  defp restart_stuck_jobs do
    time_span =
      RefreshNodeActivity.get_interval()
      |> Enum.max()
      |> then(&(&1 * @time_span_multiplier))

    max_datetime = DateTime.utc_now() |> DateTime.add(-time_span, :millisecond)

    results =
      from(t in Task,
        where: t.status == :processing,
        left_join: p in assoc(t, :progress),
        where: is_nil(p.end_time),
        left_join: n in assoc(p, :node),
        where: n.last_active < ^max_datetime,
        limit: @batch,
        order_by: t.id
      )
      |> Repo.all()

    Enum.each(results, &Tasks.change_status(&1, :queued))

    task_ids = Enum.map(results, & &1.id)

    from(j in Oban.Job)
    |> where([j], fragment("? ->> 'task_id'", j.args) in ^task_ids)
    |> Repo.update_all(set: [state: "available"])

    {:ok, "success"}
  end
end
