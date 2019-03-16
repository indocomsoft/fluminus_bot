use Mix.Config

config :fluminus_bot, FluminusBot.Repo,
  database: "fluminus_bot_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :logger, :console, format: "[$level] $message\n"
