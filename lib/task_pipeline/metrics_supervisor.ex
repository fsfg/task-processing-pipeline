defmodule TaskPipeline.MetricsSupervisor do
  @moduledoc """
  Set up ETS cache for metrics
  and supervise Events GenServers
  """

  use Supervisor

  @ets_table :metrics

  @metrics_config %{
    created_tasks: [from: nil],
    completed_tasks: [to: :completed],
    process_attempts: [to: :processing],
    restarted_tasks: [from: :processing, to: :queued],
    failed_tasks: [to: :failed],
    settled_tasks: [from: :processing],
    queued_tasks: [to: :queued]
  }

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      [
        %{
          id: @ets_table,
          start:
            {Agent, :start_link, [fn -> :ets.new(@ets_table, [:set, :public, :named_table]) end]}
        }
      ] ++
        Enum.map(@metrics_config, fn {key, filter} ->
          {TaskPipeline.Tasks.Events,
           Keyword.merge([ets_table: @ets_table, ets_key: key], filter)}
        end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def get_metrics() do
    @ets_table
    |> :ets.match(:"$1")
    |> Enum.map(&List.first/1)
    |> Map.new()
  end
end
