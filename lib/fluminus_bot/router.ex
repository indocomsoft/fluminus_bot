defmodule FluminusBot.Router do
  @templates_location "lib/fluminus_bot/templates/"
  use Plug.Router

  alias FluminusBot.Accounts
  alias Plug.Conn

  plug(Plug.Parsers, parsers: [:urlencoded], pass: ["text/*"])
  plug(:match)
  plug(:dispatch)

  match "/" do
    conn
    |> put_resp_header("Location", "https://github.com/indocomsoft/fluminus_bot")
    |> resp(302, "")
  end

  match "/login" do
    case conn.params do
      %{"chat_id" => chat_id} ->
        body =
          EEx.eval_file(Path.join(@templates_location, "login.eex"),
            chat_id: conn.params["chat_id"]
          )

        Conn.resp(conn, 200, body)

      _ ->
        serve_error(
          conn,
          400,
          "Invalid request",
          "Please only use the link given by the telegram bot."
        )
    end
  end

  match "/auth" do
    %{params: %{"nusnet" => nusnet, "password" => password, "chat_id" => chat_id}} = conn
    chat_id = String.to_integer(chat_id)

    case Fluminus.Authorization.jwt(nusnet, password) do
      {:ok, %{jwt: jwt, client: %{cookies: %{"idsrv" => idsrv}}}} ->
        Accounts.create_or_update_user(%{chat_id: chat_id, jwt: jwt, idsrv: idsrv})

        Conn.resp(conn, 200, "Logged in!")
        ExGram.send_message(chat_id, "You are logged in!")

      {:error, :invalid_credentials} ->
        serve_error(
          conn,
          403,
          "Forbidden",
          "You have entered an invalid credential",
          "/login?chat_id=#{chat_id}"
        )

      _ ->
        serve_error(
          conn,
          500,
          "Internal Server Error",
          "Either we have been banned, or LumiNUS server is flaky. Or they lied to me about Erlang's nine-nine's :("
        )
    end
  end

  match "fluminus.ico" do
    Conn.send_file(conn, 200, "priv/static/fluminus.ico")
  end

  match _ do
    serve_error(conn, 404, "Not found", "Uh-oh, something's missing")
  end

  defp serve_error(conn, status_code, error_title, error_message, back_url \\ nil) do
    body =
      EEx.eval_file(Path.join(@templates_location, "error.eex"),
        error_title: error_title,
        error_message: error_message,
        back_url: back_url
      )

    Conn.resp(conn, status_code, body)
  end
end
