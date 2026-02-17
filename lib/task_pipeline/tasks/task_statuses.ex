defmodule TaskPipeline.Tasks.TaskStatuses do
  def all_statuses, do: [:queued, :processing, :completed, :failed]
end
