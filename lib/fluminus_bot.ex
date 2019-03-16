defmodule FluminusBot do
  @moduledoc """
  Documentation for FluminusBot.
  """
  @bot :fluminus_bot

  use ExGram.Bot, name: @bot

  require Logger

  command("start")

  def handle(
        {:command, :start, %{from: from = %{id: chat_id, first_name: first_name}}},
        cnt
      ) do
    FluminusBot.Accounts.create_or_update_user(%{
      chat_id: chat_id,
      first_name: first_name,
      last_name: from[:last_name],
      username: from[:username]
    })

    reply_markup = create_inline([[%{text: "Login", url: "https://new.indocomsoft.com"}]])

    answer(cnt, "Welcome to Fluminus Bot, #{first_name}! Let's get you set up.",
      reply_markup: reply_markup
    )
  end

  def handle(message, cnt) do
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end
end
