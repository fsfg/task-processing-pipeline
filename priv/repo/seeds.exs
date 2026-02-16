# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TaskPipeline.Repo.insert!(%TaskPipeline.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TaskPipeline.Repo
alias TaskPipeline.Tasks.Task

for i <- 1..100,
    status <- [:queued, :processing, :completed, :failed],
    type <- [:import, :export, :report, :cleanup],
    priority <- [:low, :normal, :high, :critical] do
  Repo.insert!(%Task{
    title: "Task #{i}-#{type}-#{status}-#{priority}",
    type: type,
    status: status,
    priority: priority,
    payload: %{
      type: type,
      status: status,
      priority: priority,
      i: i
    }
  })
end
