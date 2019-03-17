defmodule FluminusBot do
  @moduledoc """
  Documentation for FluminusBot.
  """
  @bot :fluminus_bot

  use ExGram.Bot, name: @bot

  require Logger

  alias FluminusBot.Accounts

  command("start")
  command("delete")

  def handle(
        {:command, :start, %{from: from = %{id: chat_id, first_name: first_name}}},
        cnt
      )
      when is_integer(chat_id) and is_binary(first_name) do
    Accounts.create_or_update_user(%{
      chat_id: chat_id,
      first_name: first_name,
      last_name: from[:last_name],
      username: from[:username]
    })

    answer(cnt, "Welcome to Fluminus Bot, #{first_name}! Let's get you set up.",
      reply_markup: reply_markup(chat_id)
    )
  end

  def handle({:command, :delete, %{from: %{id: chat_id}}}, cnt) when is_integer(chat_id) do
    case Accounts.delete_user_by_chat_id(chat_id) do
      :ok ->
        answer(cnt, "Your account has been deleted.")

      :error ->
        answer(cnt, "Unable to delete your account. Please try again.")
    end
  end

  def handle(message, cnt) do
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end

  defp url(chat_id) do
    query = URI.encode_query(%{chat_id: chat_id})

    Application.get_env(:fluminus_bot, :base_login_url)
    |> URI.parse()
    |> Map.put(:path, "/login")
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  def reply_markup(chat_id) do
    create_inline([[%{text: "Login", url: url(chat_id)}]])
  end
end
