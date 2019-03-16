defmodule FluminusBot.Repo.Migrations.CreateUserModule do
  use Ecto.Migration

  def change do
    create table(:users_modules) do
      add(:user_id, references(:users))
      add(:module_id, references(:modules))

      timestamps()
    end

    create(unique_index(:users_modules, [:user_id, :module_id]))
  end
end
