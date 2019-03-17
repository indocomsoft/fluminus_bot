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

  @spec get_all_chat_ids :: [integer()]
  def get_all_chat_ids do
    User
    |> select([u], u.chat_id)
    |> Repo.all()
  end

  @spec delete_user_by_chat_id(integer()) :: :ok | :error
  def delete_user_by_chat_id(chat_id) when is_integer(chat_id) do
    User
    |> where(chat_id: ^chat_id)
    |> Repo.one()
    |> case do
      user = %User{} ->
        case Repo.delete(user) do
          {:ok, _} -> :ok
          {:error, _} -> :error
        end

      nil ->
        :ok
    end
  end
end
