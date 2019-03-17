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

  @required_fields ~w(user_id module_id)a

  def changeset(users_modules = %__MODULE__{}, params \\ %{}) do
    users_modules
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
