defmodule FluminusBot.Repo do
  use Ecto.Repo,
    otp_app: :fluminus_bot,
    adapter: Ecto.Adapters.Postgres
end
