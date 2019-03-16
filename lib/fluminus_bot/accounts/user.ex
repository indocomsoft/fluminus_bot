defmodule FluminusBot.Accounts.User do
  @moduledoc """
  Represents a user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:username, :string)
    field(:chat_id, :integer)
    field(:push_enabled, :boolean, default: false)

    timestamps()
  end

  @required_fields ~w(chat_id first_name)a
  @optional_fields ~w(last_name username push_enabled)a

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
