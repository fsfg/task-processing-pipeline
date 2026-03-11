defmodule TaskPipeline.TasksTest do
  use TaskPipeline.DataCase, async: true
  use Oban.Testing, repo: TaskPipeline.Repo

  alias TaskPipeline.Tasks
  alias TaskPipeline.Tasks.Task
  alias TaskPipeline.Tasks.TaskProgress

  describe "tasks" do
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

    test "create_task/1 with valid data creates a task, task_progress and Oban job" do
      valid_attrs = %{
        priority: :low,
        type: :import,
        max_attempts: 42,
        title: "some title",
        payload: %{}
      }

      assert {:ok, %Task{id: task_id} = task} = Tasks.create_task(valid_attrs)
      assert task.priority == :low
      assert task.status == :queued
      assert task.type == :import
      assert task.version == 1
      assert task.max_attempts == 42
      assert task.title == "some title"
      assert task.payload == %{}

      assert %TaskProgress{task_id: ^task_id, status: :queued} =
               Tasks.get_task_progress_by_task_id!(task_id)

      assert_enqueued(worker: TaskPipeline.Workers.Import, args: %{task_id: task_id})
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, :task, %Ecto.Changeset{}, _} = Tasks.create_task(@invalid_attrs)
    end

    test "change_status/2 with valid data updates status and task_progress" do
      task = task_fixture()
      assert {:ok, %Task{id: task_id}} = Tasks.change_status(task, :processing)
      assert task.status !== Tasks.get_task!(task.id).status

      assert %TaskProgress{task_id: ^task_id, status: :processing} =
               Tasks.get_task_progress_by_task_id!(task_id)
    end

    test "change_status/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, :task, %Ecto.Changeset{}, _} = Tasks.change_status(task, :wrong_status)
      assert task == Tasks.get_task!(task.id)
    end

    test "change_status/2 concurrent status modification raises an error" do
      task = task_fixture()
      assert task.status == :queued

      assert {:ok, %Task{status: :processing} = processing_task} =
               Tasks.change_status(task, :processing)

      assert {:ok, %Task{status: :failed}} = Tasks.change_status(processing_task, :failed)

      assert_raise Ecto.StaleEntryError, fn ->
        Tasks.change_status(processing_task, :completed)
      end

      assert Tasks.get_task!(processing_task.id).status == :failed
    end
  end

  describe "task_progress" do
    import TaskPipeline.TasksFixtures

    @invalid_attrs %{status: nil, metadata: nil, start_time: nil, end_time: nil}

    test "get_task_progress!/1 returns the task_progress with given id" do
      task_progress = task_progress_fixture()
      assert Tasks.get_task_progress!(task_progress.id) == task_progress
    end

    test "create_task_progress/1 with valid data creates a task_progress" do
      %TaskPipeline.Tasks.Task{id: task_id} = task_fixture()

      valid_attrs = %{
        status: :queued,
        metadata: %{},
        start_time: ~U[2026-02-16 18:43:00.000000Z],
        end_time: ~U[2026-02-16 18:43:00.000000Z],
        task_id: task_id,
        node_id: TaskPipeline.Nodes.CurrentNode.node_id()
      }

      assert {:ok, %TaskProgress{} = task_progress} = Tasks.create_task_progress(valid_attrs)
      assert task_progress.status == :queued
      assert task_progress.metadata == %{}
      assert task_progress.start_time == ~U[2026-02-16 18:43:00.000000Z]
      assert task_progress.end_time == ~U[2026-02-16 18:43:00.000000Z]
    end

    test "create_task_progress/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task_progress(@invalid_attrs)
    end

    test "update_task_progress/2 with valid data updates the task_progress" do
      task_progress = task_progress_fixture()

      update_attrs = %{
        status: :processing,
        metadata: %{},
        start_time: ~U[2026-02-17 18:43:00.000000Z],
        end_time: ~U[2026-02-17 18:43:00.000000Z]
      }

      assert {:ok, %TaskProgress{} = task_progress} =
               Tasks.update_task_progress(task_progress, update_attrs)

      assert task_progress.status == :processing
      assert task_progress.metadata == %{}
      assert task_progress.start_time == ~U[2026-02-17 18:43:00.000000Z]
      assert task_progress.end_time == ~U[2026-02-17 18:43:00.000000Z]
    end

    test "update_task_progress/2 with invalid data returns error changeset" do
      task_progress = task_progress_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Tasks.update_task_progress(task_progress, @invalid_attrs)

      assert task_progress == Tasks.get_task_progress!(task_progress.id)
    end

    test "delete_task_progress/1 deletes the task_progress" do
      task_progress = task_progress_fixture()
      assert {:ok, %TaskProgress{}} = Tasks.delete_task_progress(task_progress)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task_progress!(task_progress.id) end
    end

    test "change_task_progress/1 returns a task_progress changeset" do
      task_progress = task_progress_fixture()
      assert %Ecto.Changeset{} = Tasks.change_task_progress(task_progress)
    end
  end
end
