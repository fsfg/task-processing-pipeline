defmodule TaskPipeline.Workers.Dummy do
  @moduledoc """
  TaskPipeline dummy task flow
  """
  alias TaskPipeline.Tasks.Task

  @sleep_time %{
    critical: 1000..2000,
    high: 2000..4000,
    normal: 4000..6000,
    low: 6000..8000
  }

  @type result() :: :ok | {:error, reason :: binary()}

  @spec perform(%Task{}) :: result()
  def perform(%Task{priority: priority}) do
    @sleep_time |> Map.get(priority) |> Enum.random() |> :timer.sleep()

    if :rand.uniform(100) <= 20 do
      {:error, "random failure"}
    else
      :ok
    end
  end
end
