defmodule TaskPipeline.PubSub do
  @spec broadcast!(topic :: binary(), payload :: term()) :: :ok
  def broadcast!(topic, payload) do
    :ok = Phoenix.PubSub.broadcast!(__MODULE__, topic, payload)
  end

  @spec subscribe(topic :: binary()) :: :ok | {:error, {:already_registered, pid()}}
  def subscribe(topic) do
    :ok = Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  @spec unsubscribe(topic :: binary()) :: :ok
  def unsubscribe(topic) do
    :ok = Phoenix.PubSub.unsubscribe(__MODULE__, topic)
  end
end
