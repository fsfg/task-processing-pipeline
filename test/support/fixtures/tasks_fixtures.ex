defmodule TaskPipeline.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskPipeline.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, %{task: task}} =
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

  @doc """
  Generate a task_progress.
  """
  def task_progress_fixture(attrs \\ %{}) do
    {:ok, task_progress} =
      attrs
      |> Enum.into(%{
        end_time: ~U[2026-02-16 18:43:00.000000Z],
        metadata: %{},
        start_time: ~U[2026-02-16 18:43:00.000000Z],
        status: :queued
      })
      |> TaskPipeline.Tasks.create_task_progress()

    task_progress
  end
end
