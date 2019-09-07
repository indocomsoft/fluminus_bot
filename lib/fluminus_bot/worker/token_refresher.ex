defmodule FluminusBot.Worker.TokenRefresher do
  @moduledoc """
  The GenServer that is in charge of making sure all tokens in the database is up to date.
  Otherwise, it will ask the user to re-login.

  The interval between each refresh is determined by the `@interval` module attribute.
  There is some stochastic element involved to be nice to the destination server.
  The value is set to be 20 minutes currently.
  """

  # 20 minutes
  @interval 1 * 60 * 1000

  use GenServer

  require Logger

  alias Fluminus.Authorization
  alias FluminusBot.Accounts
  alias FluminusBot.Accounts.User

  @impl true
  def init(_) do
    Logger.info("TokenRefresher: loading all chat_ids")

    chat_id_expiries = Accounts.get_all_chat_id_expiries()

    Enum.each(chat_id_expiries, &schedule_update/1)

    chat_ids = Enum.map(chat_id_expiries, fn {chat_id, _} -> chat_id end)

    {:ok, MapSet.new(chat_ids)}
  end

  @impl true
  def handle_call({:add, {chat_id, expiry}}, _from, state = %MapSet{}) when is_integer(chat_id) do
    if MapSet.member?(state, chat_id) do
      {:reply, {:ok, :existing}, state}
    else
      schedule_update({chat_id, expiry})
      {:reply, {:ok, :new}, MapSet.put(state, chat_id)}
    end
  end

  @impl true
  def handle_call(:list, _from, state = %MapSet{}) do
    {:reply, {:ok, MapSet.to_list(state)}, state}
  end

  @impl true
  def handle_info({:update, chat_id}, state = %MapSet{}) do
    Logger.info("Updating for #{chat_id}")

    case Accounts.get_user_by_chat_id(chat_id) do
      %User{jwt: jwt, chat_id: chat_id, push_enabled: true} ->
        case check_token_expiry(jwt) do
          :ok ->
            {:ok, now} = DateTime.now("Etc/UTC")
            Logger.info(inspect(DateTime.add(now, @interval)))
            schedule_update({chat_id, DateTime.add(now, @interval)})
            {:noreply, state}

          {:error, :expired} ->
            Logger.info("Token of #{chat_id} expired")

            ExGram.send_message(chat_id, "Your token expired. Please login again!",
              reply_markup: FluminusBot.reply_markup(chat_id)
            )

            {:noreply, MapSet.delete(state, chat_id)}
        end

      _ ->
        {:noreply, MapSet.delete(state, chat_id)}
    end
  end

  defp check_token_expiry(jwt) do
    auth = Authorization.new(jwt || "")

    case Fluminus.API.name(auth) do
      {:ok, _} -> :ok
      {:error, :expired_token} -> {:error, :expired}
    end
  end

  defp schedule_update({chat_id, time}) do
    {:ok, now} = DateTime.now("Etc/UTC")

    diff =
      case time do
        nil ->
          1_000

        _ ->
          case DateTime.diff(time, now, :millisecond) do
            x when x <= 0 -> 1_000
            x -> x
          end
      end

    Logger.info("TokenRefresher: Scheduling for #{time}, after #{diff} ms")
    Process.send_after(self(), {:update, chat_id}, diff)
  end

  # CLIENT

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec add_new_chat_id(integer(), DateTime.t()) :: {:ok, :new} | {:ok, :existing}
  def add_new_chat_id(chat_id, expiry) when is_integer(chat_id) do
    GenServer.call(__MODULE__, {:add, {chat_id, expiry}})
  end

  @spec all_chat_ids :: {:ok, [integer()]}
  def all_chat_ids do
    GenServer.call(__MODULE__, :list)
  end
end
