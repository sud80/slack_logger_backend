use Mix.Config

config SlackLogger, :levels, [:debug, :info, :warn, :error]
config SlackLogger, :slack, [url: "http://example.com"]
