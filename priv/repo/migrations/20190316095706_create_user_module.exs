defmodule FluminusBot.Repo.Migrations.CreateUserModule do
  use Ecto.Migration

  def change do
    create table(:users_modules) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:module_id, references(:modules), null: false)

      timestamps()
    end

    create(unique_index(:users_modules, [:user_id, :module_id]))
  end
end
