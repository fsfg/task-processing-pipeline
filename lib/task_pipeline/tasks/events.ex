defmodule TaskPipeline.Tasks.Events do
  @moduledoc """
  Subscribe to tasks statuses changes
  """

  use GenServer

  @not_set :not_set

  def child_spec(opts) do
    %{
      id: Keyword.fetch!(opts, :ets_key),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name)

    ets_table = Keyword.fetch!(opts, :ets_table)
    ets_key = Keyword.fetch!(opts, :ets_key)
    from = Keyword.get(opts, :from, @not_set)
    to = Keyword.get(opts, :to, @not_set)

    args = %{
      ets_table: ets_table,
      ets_key: ets_key,
      from: from,
      to: to
    }

    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl GenServer
  def init(opts) do
    TaskPipeline.Tasks.subscribe_task_changes()
    {:ok, opts, {:continue, :put_default}}
  end

  @impl GenServer
  def handle_info(%{id: id, from: from, to: to}, state) when is_binary(id) do
    if should_increment?(state, from, to) do
      :ets.update_counter(state.ets_table, state.ets_key, 1)
    end

    {:noreply, state}
  end

  defp should_increment?(%{from: from, to: to}, from, to), do: true
  defp should_increment?(%{from: @not_set, to: to}, _from, to), do: true
  defp should_increment?(%{from: from, to: @not_set}, from, _to), do: true
  defp should_increment?(_state, _from, _to), do: false

  @impl GenServer
  def handle_continue(:put_default, state) do
    :ets.insert_new(state.ets_table, {state.ets_key, 0})
    {:noreply, state}
  end
end
