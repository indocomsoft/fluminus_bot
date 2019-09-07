defmodule FluminusBot.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management.
  """
  import Ecto.Query

  alias Ecto.Multi
  alias FluminusBot.Accounts.{Module, User, UserModule}
  alias FluminusBot.Repo

  def user_count do
    User
    |> select([u], count(u))
    |> Repo.one()
  end

  def user_push_enabled_count do
    User
    |> select([u], count(u))
    |> where(push_enabled: true)
    |> Repo.one()
  end

  def module_count do
    Module
    |> select([m], count(m))
    |> Repo.one()
  end

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

  @spec get_all_chat_id_expiries :: [{integer(), DateTime.t()}]
  def get_all_chat_id_expiries do
    User
    |> select([u], {u.chat_id, u.expiry})
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

  defp insert_or_update_module_changeset(attrs = %{luminus_id: luminus_id})
       when is_binary(luminus_id) do
    {:ok, datetime} = DateTime.from_unix(0)

    Module
    |> where(luminus_id: ^luminus_id)
    |> Repo.one()
    |> case do
      nil ->
        Module.changeset(%Module{}, Map.put(attrs, :last_announcement_check, datetime))

      module ->
        Module.changeset(module, attrs)
    end
  end

  def insert_or_update_module(attrs = %{luminus_id: luminus_id}) when is_binary(luminus_id) do
    attrs
    |> insert_or_update_module_changeset
    |> Repo.insert_or_update()
  end

  def insert_or_update_modules(modules) when is_list(modules) do
    insert_or_update_modules(Multi.new(), modules)
  end

  defp insert_or_update_modules(multi = %Multi{}, [
         %Fluminus.API.Module{id: luminus_id, code: code, name: name, term: term} | xs
       ]) do
    multi
    |> Multi.insert_or_update(
      code,
      insert_or_update_module_changeset(%{
        luminus_id: luminus_id,
        code: code,
        name: name,
        term: term
      })
    )
    |> insert_or_update_modules(xs)
  end

  defp insert_or_update_modules(multi = %Multi{}, []) do
    Repo.transaction(multi)
  end

  def insert_or_update_user_modules(user = %User{}, modules) when is_list(modules) do
    insert_or_update_user_modules(Multi.new(), user, modules)
  end

  defp insert_or_update_user_modules(multi = %Multi{}, user = %User{id: user_id}, [
         module = %Module{id: module_id} | xs
       ]) do
    multi
    |> Multi.insert_or_update(
      "#{user_id},#{module_id}",
      insert_or_update_user_module_changeset(user, module)
    )
    |> insert_or_update_user_modules(user, xs)
  end

  defp insert_or_update_user_modules(multi = %Multi{}, %User{}, []) do
    Repo.transaction(multi)
  end

  def insert_or_update_user_module_changeset(%User{id: user_id}, %Module{id: module_id}) do
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
  end

  @spec get_all_modules :: [%Module{}]
  def get_all_modules do
    Repo.all(Module)
  end

  @spec get_all_module_luminus_ids :: [String.t()]
  def get_all_module_luminus_ids do
    Module
    |> select([m], m.luminus_id)
    |> Repo.all()
  end

  def get_module_by_luminus_id_preload_subscribers(luminus_id) when is_binary(luminus_id) do
    {:ok, now} = DateTime.now("Etc/UTC")

    Module
    |> where(luminus_id: ^luminus_id)
    |> join(:left, [m], u in assoc(m, :users), on: u.push_enabled == true and u.expiry > ^now)
    |> preload([_, u], users: u)
    |> Repo.one()
  end

  def remove_module(module = %Module{}) do
    Repo.delete(module)
  end

  def disable_push_for_chat_id(chat_id) when is_integer(chat_id) do
    insert_or_update_user(%{chat_id: chat_id, push_enabled: false})

    UserModule
    |> join(:inner, [um], u in assoc(um, :user))
    |> where([_, u], u.chat_id == ^chat_id)
    |> Repo.delete_all()
  end
end
