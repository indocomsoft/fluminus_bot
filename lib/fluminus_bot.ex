defmodule FluminusBot do
  @moduledoc """
  Documentation for FluminusBot.
  """

  @help_message """
  `/start` to get the welcome message
  `/delete` to delete all your information from fluminus\\_bot
  `/push on` to enable push notification
  `/push off` to disable push notification
  `/help` to get help message
  """

  use ExGram.Bot, name: Application.get_env(:fluminus_bot, :name)

  require Logger

  alias Fluminus.{API, Authorization}
  alias FluminusBot.Accounts
  alias FluminusBot.Accounts.User

  command("start")
  command("delete")
  command("push")
  command("stat")
  command("help")

  def handle({:command, :stat, %{}}, cnt) do
    user_count = Accounts.user_count()
    user_push_enabled_count = Accounts.user_push_enabled_count()
    module_count = Accounts.module_count()

    answer(
      cnt,
      "There are #{user_count} users, #{user_push_enabled_count} with push enabled, and #{
        module_count
      } modules."
    )
  end

  def handle({:command, :help, %{}}, cnt) do
    answer(cnt, @help_message, parse_mode: "markdown")
  end

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

    answer(
      cnt,
      "Welcome to Fluminus Bot, #{first_name}! Let's get you set up. Send `/help` to get hel to get help.",
      reply_markup: reply_markup(chat_id),
      parse_mode: "markdown"
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
    answer(cnt, "Unknown command.")
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
    if push_enabled do
      answer(cnt, "Push notification is already enabled")
    else
      auth = Authorization.new(jwt, refresh_token)

      with {:ok, modules} <- API.modules(auth, true),
           {:ok, modules} <- Accounts.insert_or_update_modules(modules),
           modules <- Enum.map(modules, fn {_, v} -> v end),
           {:ok, _} <- Accounts.insert_or_update_user_modules(user, modules),
           {:ok, _} <- Accounts.insert_or_update_user(%{chat_id: chat_id, push_enabled: true}) do
        FluminusBot.Worker.AnnouncementPoller.add_modules(modules)
        answer(cnt, "Push notification has been **enabled**", parse_mode: "markdown")
      else
        {:error, :expired_token} ->
          answer(cnt, "Your token expired. Please login again!",
            reply_markup: reply_markup(chat_id)
          )

        {:error, error} ->
          answer(
            cnt,
            "Unexplainable error. Please contact @indocomsoft and tell him this:\n```#{error}\n```",
            parse_mode: "markdown"
          )
      end
    end
  end

  defp process_push("off", %User{chat_id: chat_id, push_enabled: push_enabled}, cnt) do
    if push_enabled do
      Accounts.disable_push_for_chat_id(chat_id)
      answer(cnt, "Push notification has been **disabled**", parse_mode: "markdown")
    else
      answer(cnt, "Push notification is already disabled")
    end
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
