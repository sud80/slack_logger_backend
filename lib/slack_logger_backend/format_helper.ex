defmodule SlackLoggerBackend.FormatHelper do

  @moduledoc """
  Simple formatter for Slack messages.
  """
  @hostname SlackLoggerBackend.Util.hostname()
  import Poison, only: [encode: 1]
  
  @doc """
  Formats a log event for Slack.
  """
  def format_event({level, message, module, function, file, line}) do
    message = message
    |> truncate_message()
    |> mask_data()
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
          }, %{
            title: "Host",
            value: @hostname,
            short: true,
          }]
      }]}
      |> encode
    event
  end

  @doc """
  Formats a log event for Slack.
  """
  def format_event({level, message, application, module, function, file, line}) do
    message = truncate_message(message)
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
          }, %{
            title: "Host",
            value: @hostname,
            short: true,
          }]
      }]}
      |> encode
    event
  end

  defp truncate_message([message | _]) do
    truncate_message(message)
  end

  defp truncate_message(message) do
    String.slice(message, 0, 8096)
  end

  defp mask_data([message | _]) do
    mask_data(message)
  end

  defp mask_data(message) do
    Enum.reduce(get_mask_regexes(), message, fn x, m ->
      Regex.replace(x, m, "<<FILTERED>>")
    end)
  end

  defp get_mask_regexes() do
    Application.get_env(:slack_logger_backend, :mask_regexes, [])
  end

end
