defmodule TaskPipeline.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskPipeline.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        max_attempts: 42,
        payload: %{},
        priority: :low,
        status: :queued,
        title: "some title",
        type: :import,
        version: 42
      })
      |> TaskPipeline.Tasks.create_task()

    task
  end
end
