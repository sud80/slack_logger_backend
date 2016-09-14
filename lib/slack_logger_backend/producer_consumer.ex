alias Experimental.GenStage

defmodule SlackLoggerBackend.ProducerConsumer do

  @moduledoc """
  Formats log events into pretty Slack messages.
  """

  use GenStage
  import Poison, only: [encode: 1]
  alias SlackLoggerBackend.Producer

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(state) do
    {:producer_consumer, state,
     subscribe_to: [{Producer, max_demand: 10, min_demand: 1}]}
  end

  @doc false
  def handle_events(events, _from, state) do
    events = Enum.map(events, &format_event/1)
    {:noreply, events, state}
  end

  @doc """
  Formats a log event for Slack.
  """
  def format_event({url, {level, message, module, function, file, line}}) do
    {:ok, event} = %{attachments: [%{
          fallback: "An #{level} level event has occurred: #{message}",
          pretext: message,
          fields: [%{
            title: "Level",
            value: level,
            short: true
          }, %{
            title: "Module",
            value: module,
            short: true
          }, %{
            title: "Function",
            value: function,
            short: true
          }, %{
            title: "File",
            value: file,
            short: true
          }, %{
            title: "Line",
            value: line,
            short: true
          }]
      }]}
      |> encode
    {url, event}
  end

  @doc """
  Formats a log event for Slack.
  """
  def format_event({url, {level, message, application, module, function, file, line}}) do
    {:ok, event} = %{attachments: [%{
          fallback: "An #{level} level event has occurred: #{message}",
          pretext: message,
          fields: [%{
            title: "Level",
            value: level,
            short: true
          }, %{
            title: "Application",
            value: application,
            short: true
          }, %{
            title: "Module",
            value: module,
            short: true
          }, %{
            title: "Function",
            value: function,
            short: true
          }, %{
            title: "File",
            value: file,
            short: true
          }, %{
            title: "Line",
            value: line,
            short: true
          }]
      }]}
      |> encode
    {url, event}
  end

end
