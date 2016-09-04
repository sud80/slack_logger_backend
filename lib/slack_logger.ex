defmodule SlackLogger do

  @moduledoc """
  A logger backend for posting errors to Slack.

  You can find the hex package [here](https://hex.pm/packages/slack_logger_backend), and the docs [here](http://hexdocs.pm/slack_logger_backend).

  ## Usage

  First, add the client to your `mix.exs` dependencies:

  ```elixir
  def deps do
    [{:slack_logger_backend, "~> 0.0.1"}]
  end
  ```

  Then run `$ mix do deps.get, compile` to download and compile your dependencies.

  Finally, add `SlackLogger` to your list of logging backends in your app's config:

  ```elixir
  config :logger, backends: [SlackLogger, :console]
  ```

  You can set the log levels you want posted to slack in the config:

  ```elixir
  config SlackLogger, :levels, [:debug, :info, :warn, :error]
  ```

  Alternatively, do both in one step:

  ```elixir
  config :logger, backends: [{SlackLogger, :error}]
  config :logger, backends: [{SlackLogger, [:info, error]}]
  ```

  You'll need to create a custom incoming webhook URL for your Slack team. You can either configure the webhook
  in your config:

  ```elixir
  config SlackLogger, :slack, [url: "http://example.com"]
  ```

  ... or you can put the webhook URL in the `SLACK_LOGGER_WEBHOOK_URL` environment variable if you prefer. If
  you have both the environment variable will be preferred.
  """

  use GenEvent

  @env_webhook "SLACK_LOGGER_WEBHOOK_URL"

  @doc false
  def init(__MODULE__) do
    {:ok, %{levels: []}}
  end

  def init({__MODULE__, levels}) when is_atom(levels) do
    {:ok, %{levels: [levels]}}
  end

  def init({__MODULE__, levels}) when is_list(levels) do
    {:ok, %{levels: levels}}
  end

  @doc false
  def handle_call(_request, state) do
    {:ok, state}
  end

  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: []} = state) do
    levels = case Application.get_env(SlackLogger, :levels) do
      nil ->
        [:error] # by default only log error level messages
      levels ->
        levels
    end
    if level in levels do
      handle_event(level, message, detail)
    end
    {:ok, %{state | levels: levels}}
  end

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: levels} = state) do
    if level in levels do
      handle_event(level, message, detail)
    end
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  @doc false
  def handle_info(_message, state) do
    {:ok, state}
  end

  defp get_url do
    case System.get_env(@env_webhook) do
      nil ->
        Application.get_env(SlackLogger, :slack)[:url]
      url ->
        url
    end
  end

  defp handle_event(level, message, [pid: _, application: application, module: module, function: function, file: file, line: line]) do
    %{ attachments: [%{
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
    |> Poison.encode
    |> send_event
  end

  defp handle_event(level, message, [pid: _, module: module, function: function, file: file, line: line]) do
    %{ attachments: [%{
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
    |> Poison.encode
    |> send_event
  end

  defp handle_event(_, _, _) do
    :noop
  end

  defp send_event({:ok, json}) do
    get_url |> HTTPoison.post(json)
  end

end
