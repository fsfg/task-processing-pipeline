defmodule TaskPipeline.Workers.CustomWorker do
  @moduledoc """
  TaskPipeline custom worker behaviour
  """
  alias TaskPipeline.{Tasks, Tasks.Task}

  @callback process_task(Task.t()) :: Oban.Worker.result()

  def perform(module, %Oban.Job{args: %{"task_id" => task_id}, attempt: attempt} = job) do
    {:ok, task} =
      task_id
      |> Tasks.get_task_by_id_and_status!(:queued)
      |> Tasks.change_status(:processing)

    result =
      try do
        module.process_task(task)
      rescue
        e ->
          {:error, e}
      end

    %Task{priority: priority} =
      processed_task = Tasks.get_task_by_id_and_status!(task_id, :processing)

    case result do
      :ok ->
        Tasks.change_status(processed_task, :completed)
        :ok

      {:error, e} ->
        if attempt > 0 do
          Tasks.change_status(processed_task, :queued)
          Oban.Job.update(job, %{priority: priority})
        else
          Tasks.change_status(processed_task, :failed)
        end

        {:error, e}
    end
  end

  defmacro __using__(oban_opts) do
    quote do
      use Oban.Worker, unquote(oban_opts)

      @behaviour unquote(__MODULE__)

      @impl Oban.Worker
      def perform(job) do
        unquote(__MODULE__).perform(__MODULE__, job)
      end
    end
  end
end
