defmodule FluminusBot.Repo.Migrations.CreateModule do
  use Ecto.Migration

  def change do
    create table(:modules) do
      add(:luminus_id, :string, null: false)
      add(:code, :string, null: false)
      add(:name, :string, null: false)
      add(:term, :string, null: false)
      add(:last_announcement_check, :utc_datetime)

      timestamps()
    end

    create(unique_index(:modules, [:luminus_id]))
    create(unique_index(:modules, [:code, :term]))
    create(unique_index(:modules, [:luminus_id, :code, :term]))
  end
end
