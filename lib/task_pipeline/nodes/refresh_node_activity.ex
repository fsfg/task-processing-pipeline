defmodule TaskPipeline.Nodes.RefreshNodeActivity do
  use GenServer

  @refresh :refresh

  def start_link(opts) do
    interval = Keyword.get(opts, :interval, 60_000..90_000)
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, interval, name: name)
  end

  def get_interval(server \\ __MODULE__), do: GenServer.call(server, :get_interval)

  @impl GenServer
  def init(interval), do: {:ok, interval, {:continue, @refresh}}

  @impl GenServer
  def handle_continue(@refresh, interval), do: refresh(interval)

  @impl GenServer
  def handle_info(@refresh, interval), do: refresh(interval)

  @impl GenServer
  def handle_call(:get_interval, _from, interval) do
    {:reply, interval, interval, :hibernate}
  end

  defp refresh(interval) do
    TaskPipeline.Nodes.CurrentNode.refresh_last_active()
    random_interval = Enum.random(interval)
    Process.send_after(self(), @refresh, random_interval)

    {:noreply, interval, :hibernate}
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end
end
