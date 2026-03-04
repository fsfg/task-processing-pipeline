defmodule TaskPipeline.Tasks.TaskPriorities do
  def all_priorities, do: [low: 3, normal: 2, high: 1, critical: 0]
end
