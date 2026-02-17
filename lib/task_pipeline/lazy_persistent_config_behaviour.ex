defmodule TaskPipeline.LazyPersistentConfigBehaviour do
  @callback compute_value() :: any()

  use GenServer

  def start_link(%{module: _} = opts) do
    {name, opts} = Map.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl GenServer
  def handle_call(:get_value, _from, state) do
    not_set = make_ref()

    result =
      case :persistent_term.get(state.module, not_set) do
        ^not_set ->
          :persistent_term.put(state.module, state.module.compute_value())
          :persistent_term.get(state.module)

        data ->
          data
      end

    {:reply, result, state}
  end

  def get_value(module) when is_atom(module) do
    not_set = make_ref()

    case :persistent_term.get(module, not_set) do
      ^not_set ->
        GenServer.call(module, :get_value)

      data ->
        data
    end
  end

  def child_spec_for_module(module, opts) do
    default_opts = %{
      module: module,
      name: module
    }

    %{
      id: Map.get(opts, :id, module),
      start: {__MODULE__, :start_link, [Map.merge(default_opts, opts)]}
    }
  end

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def get_value() do
        unquote(__MODULE__).get_value(__MODULE__)
      end

      def child_spec(opts) do
        unquote(__MODULE__).child_spec_for_module(__MODULE__, opts)
      end
    end
  end
end
