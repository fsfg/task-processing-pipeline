defmodule TaskPipeline.TasksTest do
  use TaskPipeline.DataCase, async: true

  alias TaskPipeline.Tasks

  describe "tasks" do
    alias TaskPipeline.Tasks.Task

    import TaskPipeline.TasksFixtures

    @invalid_attrs %{
      priority: nil,
      status: nil,
      type: nil,
      version: nil,
      max_attempts: nil,
      title: nil,
      payload: nil
    }

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tasks.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert Tasks.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      valid_attrs = %{
        priority: :low,
        type: :import,
        max_attempts: 42,
        title: "some title",
        payload: %{}
      }

      assert {:ok, %Task{} = task} = Tasks.create_task(valid_attrs)
      assert task.priority == :low
      assert task.status == :queued
      assert task.type == :import
      assert task.version == 1
      assert task.max_attempts == 42
      assert task.title == "some title"
      assert task.payload == %{}
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task(@invalid_attrs)
    end

    test "change_status/2 with valid data updates status" do
      task = task_fixture()
      assert {:ok, %Task{}} = Tasks.change_status(task, :completed)
      assert task.status !== Tasks.get_task!(task.id).status
    end

    test "change_status/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.change_status(task, :wrong_status)
      assert task == Tasks.get_task!(task.id)
    end

    test "change_status/2 concurrent status modification raises an error" do
      task = task_fixture()
      assert task.status == :queued
      assert {:ok, %Task{}} = Tasks.change_status(task, :processing)

      assert_raise Ecto.StaleEntryError, fn ->
        Tasks.change_status(task, :completed)
      end

      assert Tasks.get_task!(task.id).status == :processing
    end
  end
end
