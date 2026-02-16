defmodule TaskPipeline.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, UUIDv7, autogenerate: true}
      @foreign_key_type UUIDv7
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
