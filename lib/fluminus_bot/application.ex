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
      FluminusBot.TokenRefresher
    ]

    opts = [strategy: :one_for_one, name: FluminusBot.Supervisor]
    result = Supervisor.start_link(children, opts)

    Logger.info("FluminusBot started")

    FluminusBot.Accounts.get_all_users()
    |> Enum.map(& &1.chat_id)
    |> Enum.each(&FluminusBot.TokenRefresher.add_new_chat_id/1)

    Logger.info("Added chat_ids to TokenRefresher")

    result
  end
end
