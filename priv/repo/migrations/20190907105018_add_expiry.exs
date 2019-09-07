defmodule FluminusBot.Repo.Migrations.AddExpiry do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:expiry, :utc_datetime, null: true)
      remove(:refresh_token, :string, size: 1024)
      modify(:jwt, :string, from: :string, null: false, default: "", size: 1024)
    end
  end
end
