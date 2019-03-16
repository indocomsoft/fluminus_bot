defmodule FluminusBot.Accounts.Module do
  @moduledoc """
  Represents a module in a given term.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "modules" do
    field(:luminus_id, :string)
    field(:code, :string)
    field(:name, :string)
    field(:term, :string)

    timestamps()
  end
end
