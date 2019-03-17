defmodule FluminusBot do
  @moduledoc """
  Documentation for FluminusBot.
  """
  @bot :fluminus_bot

  use ExGram.Bot, name: @bot

  require Logger

  alias Fluminus.{API, Authorization}
  alias FluminusBot.Accounts
  alias FluminusBot.Accounts.{User, UserModule}

  command("start")
  command("delete")
  command("push")

  def handle(
        {:command, :start, %{from: from = %{id: chat_id, first_name: first_name}}},
        cnt
      )
      when is_integer(chat_id) and is_binary(first_name) do
    Accounts.insert_or_update_user(%{
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

  def handle({:command, :push, %{from: %{id: chat_id}, text: text}}, cnt)
      when text in ["on", "off"] do
    user = Accounts.get_user_by_chat_id(chat_id)
    process_push(text, user, cnt)
  end

  def handle({:command, :push, _}, cnt) do
    answer(cnt, "Invalid command. Valid command is either `/push on` or `/push off`",
      parse_mode: "markdown"
    )
  end

  def handle(message, cnt) do
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end

  defp process_push(
         "on",
         user = %User{
           chat_id: chat_id,
           jwt: jwt,
           refresh_token: refresh_token,
           push_enabled: push_enabled
         },
         cnt
       ) do
    auth = Authorization.new(jwt, refresh_token)
    modules = Fluminus.API.modules(auth, true)

    modules =
      modules
      |> Enum.map(fn %{id: luminus_id, code: code, name: name, term: term} ->
        %{luminus_id: luminus_id, code: code, name: name, term: term}
      end)
      |> Enum.map(fn attrs ->
        {:ok, module} = Accounts.insert_or_update_module(attrs)
        module
      end)

    if not push_enabled do
      Accounts.insert_or_update_user(%{chat_id: chat_id, push: true})
    end

    Accounts.insert_or_update_user_modules(user, modules)
  end

  defp process_push("off", user = %User{}, cnt) do
  end

  defp process_push(_, nil, cnt) do
    answer(cnt, "Please login first by sending /start")
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
