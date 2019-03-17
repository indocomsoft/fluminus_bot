defmodule FluminusBot.TokenRefresher do
  @moduledoc """
  The GenServer that is in charge of making sure all tokens in the database is up to date.
  Otherwise, it will ask the user to re-login.

  The interval between each refresh is determined by the `@interval` module attribute.
  There is some stochastic element involved to be nice to the destination server.
  The value is set to be 20 minutes currently.
  """

  # 20 minutes
  @interval 20 * 60 * 1000

  use GenServer

  require Logger

  alias Fluminus.Authorization
  alias FluminusBot.Accounts
  alias FluminusBot.Accounts.User

  @impl true
  def init(_) do
    Logger.info("TokenRefresher: loading all chat_ids")
    chat_ids = Accounts.get_all_chat_ids()

    Enum.each(chat_ids, &schedule_update/1)

    {:ok, MapSet.new(chat_ids)}
  end

  @impl true
  def handle_call({:add, chat_id}, _from, state) when is_integer(chat_id) and is_map(state) do
    if MapSet.member?(state, chat_id) do
      {:reply, {:ok, :existing}, state}
    else
      schedule_update(chat_id)
      {:reply, {:ok, :new}, MapSet.put(state, chat_id)}
    end
  end

  @impl true
  def handle_call(:list, _from, state) when is_map(state) do
    {:reply, {:ok, MapSet.to_list(state)}, state}
  end

  @impl true
  def handle_info({:update, chat_id}, state) when is_map(state) do
    Logger.info("Updating for #{chat_id}")

    if MapSet.member?(state, chat_id) do
      case Accounts.get_user_by_chat_id(chat_id) do
        %User{jwt: jwt, refresh_token: refresh_token, chat_id: chat_id} ->
          auth = Authorization.new(jwt, refresh_token)

          renew_jwt(auth, chat_id)

          {:noreply, state}

        nil ->
          {:noreply, MapSet.delete(state, chat_id)}
      end
    else
      {:noreply, state}
    end
  end

  defp renew_jwt(auth = %Authorization{}, chat_id) when is_integer(chat_id) do
    case Authorization.renew_jwt(auth) do
      {:ok, auth = %Authorization{}} ->
        jwt = Authorization.get_jwt(auth)
        refresh_token = Authorization.get_refresh_token(auth)

        Accounts.insert_or_update_user(%{
          chat_id: chat_id,
          jwt: jwt,
          refresh_token: refresh_token
        })

        Logger.info("Updated token for #{chat_id}")

        schedule_update(chat_id)

      {:error, :invalid_authorization} ->
        reply_markup = FluminusBot.reply_markup(chat_id)

        ExGram.send_message(chat_id, "Your token expired. Please login again!",
          reply_markup: reply_markup
        )

      {:error, _} ->
        nil
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec add_new_chat_id(integer()) :: {:ok, :new} | {:ok, :existing}
  def add_new_chat_id(chat_id) when is_integer(chat_id) do
    GenServer.call(__MODULE__, {:add, chat_id})
  end

  @spec all_chat_ids :: {:ok, [integer()]}
  def all_chat_ids do
    GenServer.call(__MODULE__, :list)
  end

  defp schedule_update(chat_id) do
    time = Enum.random(100..@interval)
    Logger.info("Scheduling after #{time} ms")
    Process.send_after(self(), {:update, chat_id}, time)
  end
end
