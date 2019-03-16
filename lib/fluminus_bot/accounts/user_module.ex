defmodule FluminusBot.Accounts.UserModule do
  @moduledoc """
  The schema that is the join table of the many-to-many relationship between user and module.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias FluminusBot.Accounts.{Module, User}

  schema "users_modules" do
    belongs_to(:user, User)
    belongs_to(:module, Module)

    timestamps()
  end
end
