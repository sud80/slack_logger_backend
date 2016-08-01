ExUnit.start

defmodule SlackLoggerTest do
  use ExUnit.Case
  require Logger

  setup do
    bypass = Bypass.open
    Application.put_env SlackLogger, :slack, [url: "http://localhost:#{bypass.port}/hook"]
    System.put_env "SLACK_LOGGER_WEBHOOK_URL", "http://localhost:#{bypass.port}/hook"
    {:ok, _} = Logger.add_backend(SlackLogger, flush: true)
    on_exit fn ->
      Logger.remove_backend(SlackLogger, flush: true)
    end
    {:ok, %{bypass: bypass}}
  end

  test "posts the error to the Slack incoming webhook", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/hook" == conn.request_path
      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, "ok")
    end

    Logger.error "This error should be logged to Slack"
    Logger.flush
  end

  test "doesn't post a debug message to Slack if the level is not set", %{bypass: bypass} do
    Application.put_env SlackLogger, :levels, [:info]
    on_exit fn ->
      Application.put_env SlackLogger, :levels, [:debug, :info, :warn, :error]
    end

    Bypass.expect bypass, fn _conn ->
      flunk "Slack should not have been notified"
    end
    Bypass.pass(bypass)

    Logger.error "This error should not be logged to Slack"
    Logger.flush
  end

end
