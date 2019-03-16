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

    reply_markup = create_inline([[%{text: "Login", url: url(chat_id)}]])

    answer(cnt, "Welcome to Fluminus Bot, #{first_name}! Let's get you set up.",
      reply_markup: reply_markup
    )
  end

  def handle(message, cnt) do
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end

  defp url(chat_id) do
    [scheme: scheme, hostname: hostname, port: port] = Application.get_env(:fluminus_bot, :url)
    scheme = Atom.to_string(scheme)
    query = URI.encode_query(%{chat_id: chat_id})

    URI.to_string(%URI{
      scheme: scheme,
      host: hostname,
      port: port,
      path: "/",
      query: query
    })
  end
end
