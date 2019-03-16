defmodule FluminusBot.TokenRefresher do
  use GenServer

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:add, chat_id}, _from, state) when is_integer(chat_id) and is_map(state) do
    if Map.has_key?(state, chat_id) do
      {:reply, {:ok, :existing}, state}
    else
      {:reply, {:ok, :new}, Map.put(state, chat_id, true)}
    end
  end

  @impl true
  def handle_call(:list, _from, state) when is_map(state) do
    {:reply, {:ok, Map.keys(state)}, state}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def add_new_chat_id(chat_id) when is_integer(chat_id) do
    case Registry.register(@registry_name, chat_id, true) do
      {:ok, pid} ->
        {:ok, pid}

      other ->
        other
    end
  end
end
