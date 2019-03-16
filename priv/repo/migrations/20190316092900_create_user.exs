defmodule FluminusBot.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:first_name, :string)
      add(:last_name, :string)
      add(:username, :string)
      add(:chat_id, :int, null: false)
      add(:push_enabled, :boolean, default: false)
      add(:jwt, :string, size: 2048)
      add(:idsrv, :string, size: 1024)

      timestamps()
    end

    create(unique_index(:users, [:chat_id]))
  end
end
