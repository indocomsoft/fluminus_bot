defmodule FluminusBot.Accounts.User do
  @moduledoc """
  Represents a user.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias FluminusBot.Accounts.{Module, UserModule}

  schema "users" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:username, :string)
    field(:chat_id, :integer)
    field(:push_enabled, :boolean, default: false)
    field(:jwt, :string)
    field(:refresh_token, :string)

    many_to_many(:modules, Module, join_through: UserModule)

    timestamps()
  end

  @required_fields ~w(chat_id first_name)a
  @optional_fields ~w(last_name username push_enabled jwt refresh_token)a

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
