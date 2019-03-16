defmodule FluminusBot do
  @moduledoc """
  Documentation for FluminusBot.
  """
  @bot :fluminus_bot
  def bot, do: @bot

  use ExGram.Bot, name: @bot

  require Logger

  command("start")

  def handle(message, cnt) do
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end
end
