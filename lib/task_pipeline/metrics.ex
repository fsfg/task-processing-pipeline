defmodule TaskPipeline.Metrics do
  @moduledoc """
  Metrics module
  """

  alias TaskPipeline.MetricsSupervisor
  alias TaskPipeline.Nodes.CurrentNode

  @precision 4

  def get_metrics() do
    node_id = CurrentNode.node_id()
    online_time = CurrentNode.uptime()

    node_metrics = %{
      node_id: node_id,
      online_time: online_time
    }

    %{
      completed_tasks: completed_tasks,
      process_attempts: process_attempts,
      settled_tasks: settled_tasks,
      queued_tasks: queued_tasks
    } = tasks_metrics = MetricsSupervisor.get_metrics()

    # number of tasks per second: all (to :completed)
    throughput_all = Float.round(completed_tasks / online_time, @precision)
    # number of tasks per second: all settled (from :processing)
    throughput_settled = Float.round(settled_tasks / online_time, @precision)
    in_queue = queued_tasks - process_attempts

    average_processing_time =
      case settled_tasks do
        0 ->
          nil

        _ ->
          Float.round(online_time / settled_tasks, @precision)
      end

    extra_metrics = %{
      average_processing_time_rate: average_processing_time,
      tasks_in_queue: in_queue,
      throughput_all_rate: throughput_all,
      throughput_settled_rate: throughput_settled
    }

    %{}
    |> Map.merge(node_metrics)
    |> Map.merge(tasks_metrics)
    |> Map.merge(extra_metrics)
  end
end
