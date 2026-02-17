defmodule TaskPipeline.QueryParams do
  alias Ecto.Changeset
  use Ecto.Schema

  @not_set :not_set

  @default_data %{
    status: @not_set,
    type: @not_set,
    priority: @not_set,
    cursor: @not_set,
    per_page: 10,
    id: @not_set
  }

  def changeset(params) do
    filter_changeset = filter_changeset(params)
    cursor_changeset = cursor_changeset(params)

    has_conflicts =
      filter_keys()
      |> Enum.map(&Changeset.changed?(filter_changeset, &1))
      |> Enum.any?() and params["cursor"]

    if has_conflicts do
      Changeset.add_error(%Changeset{}, :cursor, "You need to set either cursor or filters")
    else
      filter_changeset
      |> Changeset.merge(cursor_changeset)
      |> Changeset.merge(per_page_changeset(params))
    end
  end

  defp filter_changeset(params) do
    types = filter_types()

    {@default_data, types}
    |> Changeset.cast(params, filter_keys())
  end

  defp filter_types do
    for field <- filter_keys(), into: %{} do
      {field,
       Ecto.ParameterizedType.init(Ecto.Enum,
         values: Ecto.Enum.values(TaskPipeline.Tasks.Task, field)
       )}
    end
  end

  def filter_keys, do: [:status, :type, :priority]

  defp per_page_changeset(params) do
    types = %{per_page: :integer}

    {@default_data, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_inclusion(:per_page, 1..100)
  end

  defp cursor_changeset(params) do
    types = %{cursor: :string}

    {@default_data, types} |> Changeset.cast(params, Map.keys(types)) |> validate_cursor()
  end

  defp validate_cursor(changeset) do
    if(Changeset.changed?(changeset, :cursor)) do
      with cursor <- Changeset.get_field(changeset, :cursor),
           {:ok, json} <- Base.decode64(cursor),
           {:ok, params} <- Jason.decode(json) do
        Changeset.merge(filter_changeset(params), validate_id(params))
      else
        {:error, _error} -> Changeset.add_error(changeset, :cursor, "Invalid cursor")
      end
    else
      changeset
    end
  end

  defp validate_id(params) do
    types = %{id: UUIDv7}

    {@default_data, types} |> Changeset.cast(params, Map.keys(types))
  end
end
