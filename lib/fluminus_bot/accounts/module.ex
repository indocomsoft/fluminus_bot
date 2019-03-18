defmodule FluminusBot.Accounts.Module do
  @moduledoc """
  Represents a module in a given term.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias FluminusBot.Accounts.{User, UserModule}

  schema "modules" do
    field(:luminus_id, :string)
    field(:code, :string)
    field(:name, :string)
    field(:term, :string)
    field(:last_announcement_check, :utc_datetime)
    many_to_many(:users, User, join_through: UserModule)

    timestamps()
  end

  @required_fields ~w(luminus_id code name term)a
  @optional_fields ~w(last_announcement_check)a

  def changeset(module = %__MODULE__{}, params \\ %{}) do
    module
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
