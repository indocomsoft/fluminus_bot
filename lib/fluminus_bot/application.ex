defmodule FluminusBot.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    [scheme: scheme, hostname: _, port: port] = Application.get_env(:fluminus_bot, :server_url)

    token = ExGram.Config.get(:ex_gram, :token)

    children = [
      FluminusBot.Repo,
      ExGram,
      {FluminusBot, [method: :polling, token: token]},
      {Plug.Cowboy, [scheme: scheme, plug: FluminusBot.Router, options: [port: port]]},
      FluminusBot.Worker.TokenRefresher,
      FluminusBot.Worker.AnnouncementPoller
    ]

    opts = [strategy: :one_for_one, name: FluminusBot.Supervisor]
    result = Supervisor.start_link(children, opts)

    Logger.info("FluminusBot started")

    result
  end
end
