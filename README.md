# TaskPipeline

You can install proper versions Erlang and Elixir via [Mise](https://mise.jdx.dev/getting-started.html) (see [`mise.toml`](mise.toml)).

To start your Phoenix server:

* Run PostgreSQL instance. You can do it via Docker command. `docker run -d -p 127.0.0.1:5432:5432 --name task-pipeline_db -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres postgres:18`
* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
