defmodule FluminusBot.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      FluminusBot.Repo,
      ExGram,
      {FluminusBot, [method: :polling, token: ExGram.Config.get(:ex_gram, :token)]}
    ]

    opts = [strategy: :one_for_one, name: FluminusBot.Supervisor]
    result = Supervisor.start_link(children, opts)

    Logger.info("FluminusBot started")

    result
  end
end
