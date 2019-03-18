defmodule FluminusBot.Worker.AnnouncementPoller do
  @moduledoc """
  The GenServer that is in charge of polling the announcements of different modules, and sending
  updates to the users who subscribed.
  """

  # 30 minutes
  @interval 30 * 60 * 1000

  use GenServer

  require Logger

  alias Fluminus.{API, Authorization}
  alias FluminusBot.Accounts
  alias FluminusBot.Accounts.{Module, User}

  @impl true
  def init(_) do
    Logger.info("AnnouncementPoller: loading all modules")
    ids = Accounts.get_all_module_luminus_ids()

    Enum.each(ids, &schedule_update/1)

    {:ok, MapSet.new(ids)}
  end

  @impl true
  def handle_call({:add, id}, _from, state = %MapSet{}) when is_binary(id) do
    if MapSet.member?(state, id) do
      {:reply, {:ok, :existing}, state}
    else
      schedule_update(id)
      {:reply, {:ok, :new}, MapSet.put(state, id)}
    end
  end

  @impl true
  def handle_call(:list, _from, state = %MapSet{}) do
    {:reply, {:ok, MapSet.to_list(state)}, state}
  end

  @impl true
  def handle_info({:update, id}, state = %MapSet{}) when is_binary(id) do
    Logger.info("AnnouncementPoller: #{id}")

    case Accounts.get_module_by_luminus_id_preload_subscribers(id) do
      module = %Module{users: users} ->
        if Enum.empty?(users) do
          Accounts.remove_module(module)
        else
          process_announcements(module, users)
        end

        {:noreply, state}

      nil ->
        {:noreply, MapSet.delete(state, id)}
    end
  end

  defp process_announcements(
         module = %Module{
           luminus_id: luminus_id,
           code: code,
           name: name,
           users: users,
           last_announcement_check: last_announcement_check
         },
         [%User{jwt: jwt, refresh_token: refresh_token} | other_users]
       ) do
    auth = Authorization.new(jwt, refresh_token)

    case API.Module.announcements(%API.Module{id: luminus_id}, auth) do
      {:ok, announcements} ->
        to_send =
          announcements
          |> Enum.filter(fn %{datetime: datetime} ->
            DateTime.compare(datetime, last_announcement_check) == :gt
          end)
          |> Enum.map(fn %{title: title, description: description} ->
            "#{code} - #{name}\n**#{title}**\n#{description}"
          end)

        for %User{chat_id: chat_id} <- users,
            announcement <- to_send do
          ExGram.send_message(chat_id, announcement, parse_mode: "markdown")
        end

        {:ok, now_datetime} = DateTime.now("Etc/UTC")

        Accounts.insert_or_update_module(%{
          luminus_id: luminus_id,
          last_announcement_check: now_datetime
        })

        schedule_update(luminus_id)

      {:error, _} ->
        process_announcements(module, other_users)
    end
  end

  defp process_announcements(%Module{luminus_id: luminus_id}, []) do
    schedule_update(luminus_id)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def add_modules([%Module{luminus_id: luminus_id} | xs]) do
    GenServer.call(__MODULE__, {:add, luminus_id})
    add_modules(xs)
  end

  def add_modules([]) do
    :ok
  end

  defp schedule_update(id) do
    time = Enum.random(100..@interval)
    Logger.info("AnnouncementPoller: Scheduling after #{time} ms")
    Process.send_after(self(), {:update, id}, time)
  end
end
