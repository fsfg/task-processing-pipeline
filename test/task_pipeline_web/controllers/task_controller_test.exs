defmodule TaskPipelineWeb.TaskControllerTest do
  use TaskPipelineWeb.ConnCase, async: true

  alias TaskPipeline.Tasks

  @create_attrs %{
    priority: :low,
    type: :import,
    max_attempts: 42,
    title: "some title",
    payload: %{}
  }
  @invalid_attrs %{
    priority: nil,
    type: nil,
    max_attempts: nil,
    title: nil,
    payload: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all tasks", %{conn: conn} do
      conn = get(conn, ~p"/api/tasks")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create task" do
    test "renders brief task when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/tasks", task: @create_attrs)

      assert %{
               "id" => _,
               "title" => "some title",
               "type" => "import",
               "priority" => "low",
               "status" => "queued"
             } = json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/tasks", task: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show summary" do
    test "returns correct numbers", %{conn: conn} do
      statuses = Ecto.Enum.values(Tasks.Task, :status)

      expected =
        for _ <- 1..10, reduce: Map.from_keys(statuses, 0) do
          acc ->
            status = Enum.random(statuses)
            create_task_with_status(status)
            update_in(acc[status], &(&1 + 1))
        end
        |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
        |> Enum.into(%{})

      conn = get(conn, ~p"/api/tasks/summary")

      assert expected == json_response(conn, 200)["data"]
    end
  end

  describe "get task by id" do
    import TaskPipeline.TasksFixtures

    test "renders full data with sorted progress", %{conn: conn} do
      %{id: task_id} = task = task_fixture()

      node_id = TaskPipeline.Nodes.CurrentNode.node_id()

      conn = get(conn, ~p"/api/tasks/#{task_id}")

      assert %{
               "id" => ^task_id,
               "max_attempts" => 42,
               "payload" => %{},
               "priority" => "low",
               "status" => "queued",
               "title" => "some title",
               "type" => "import",
               "progress" => [
                 %{
                   "id" => _,
                   "status" => "queued",
                   "start_time" => _,
                   "end_time" => nil,
                   "metadata" => nil,
                   "node_id" => ^node_id
                 }
               ]
             } = json_response(conn, 200)["data"]

      task |> Tasks.change_status(:processing)

      conn = get(conn, ~p"/api/tasks/#{task_id}")

      assert %{
               "id" => ^task_id,
               "max_attempts" => 42,
               "payload" => %{},
               "priority" => "low",
               "status" => "processing",
               "title" => "some title",
               "type" => "import",
               "progress" => [
                 %{
                   "id" => _,
                   "status" => "queued",
                   "start_time" => _,
                   "end_time" => _,
                   "metadata" => nil,
                   "node_id" => ^node_id
                 },
                 %{
                   "id" => _,
                   "status" => "processing",
                   "start_time" => _,
                   "end_time" => nil,
                   "metadata" => nil,
                   "node_id" => ^node_id
                 }
               ]
             } = json_response(conn, 200)["data"]
    end
  end

  import TaskPipeline.TasksFixtures

  defp create_task_with_status(status) do
    task_fixture() |> Tasks.change_status(status)
  end
end
