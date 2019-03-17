defmodule FluminusBot.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management.
  """
  import Ecto.Query

  alias FluminusBot.Repo

  alias FluminusBot.Accounts.{Module, User, UserModule}

  @spec insert_or_update_user(map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def insert_or_update_user(attrs = %{chat_id: chat_id}) when is_integer(chat_id) do
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

  def insert_or_update_module(
        attrs = %{luminus_id: luminus_id, code: code, name: name, term: term}
      )
      when is_binary(luminus_id) and is_binary(code) and is_binary(name) and is_binary(term) do
    Module
    |> where(luminus_id: ^luminus_id)
    |> Repo.one()
    |> case do
      nil ->
        Module.changeset(%Module{}, attrs)

      module ->
        Module.changeset(module, attrs)
    end
    |> Repo.insert_or_update()
  end

  def insert_or_update_user_modules(%User{id: user_id}, modules) when is_list(modules) do
    for %Module{id: module_id} <- modules do
      attrs = %{user_id: user_id, module_id: module_id}

      UserModule
      |> where(user_id: ^user_id)
      |> where(module_id: ^module_id)
      |> Repo.one()
      |> case do
        nil ->
          UserModule.changeset(%UserModule{}, attrs)

        user_module = %UserModule{} ->
          UserModule.changeset(user_module, attrs)
      end
      |> Repo.insert_or_update()
    end
  end
end
