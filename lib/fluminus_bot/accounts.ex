defmodule FluminusBot.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management.
  """
  import Ecto.Query

  alias FluminusBot.Repo

  alias FluminusBot.Accounts.User

  @spec create_or_update_user(map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def create_or_update_user(attrs = %{chat_id: chat_id}) when is_integer(chat_id) do
    User
    |> where(chat_id: ^chat_id)
    |> Repo.one()
    |> case do
      nil ->
        User.changeset(%User{}, attrs)

      user ->
        User.changeset(user, attrs)
    end
    |> Repo.insert_or_update()
  end

  @spec get_user_by_chat_id(integer()) :: %User{} | nil
  def get_user_by_chat_id(chat_id) when is_integer(chat_id) do
    User
    |> where(chat_id: ^chat_id)
    |> Repo.one()
  end

  @spec get_all_users :: [%User{}]
  def get_all_users do
    Repo.all(User)
  end
end
