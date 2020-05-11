defmodule SlackLoggerBackend.Util do
  def hostname() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end