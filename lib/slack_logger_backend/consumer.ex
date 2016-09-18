alias Experimental.GenStage

defmodule SlackLoggerBackend.Consumer do

  @moduledoc """
  Consumes logger events and pushes them onto the worker pool to send to Slack.
  """
  use GenStage
  alias SlackLoggerBackend.{ProducerConsumer, Pool}

  @doc false
  def start_link(interval) do
    GenStage.start_link(__MODULE__, interval, name: __MODULE__)
  end

  @doc false
  def init(interval) do
    {:consumer, interval,
     subscribe_to: [{ProducerConsumer, max_demand: 10, min_demand: 1}]}
  end

  @doc false
  def handle_events([], _from, interval) do
    process_events([], interval)
  end

  @doc false
  def handle_events(events, _from, interval) do
    process_events(events, interval)
  end

  defp process_events([], interval) do
    :timer.sleep(interval)
    {:noreply, [], interval}
  end

  defp process_events([{url, json}|events], interval) do
    Pool.post(url, json)
    process_events(events, interval)
  end

end
