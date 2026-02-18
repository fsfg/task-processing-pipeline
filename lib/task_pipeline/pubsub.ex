defmodule TaskPipeline.PubSub do
  def broadcast!(topic, payload) do
    Phoenix.PubSub.broadcast!(__MODULE__, topic, payload)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(__MODULE__, topic)
  end
end
