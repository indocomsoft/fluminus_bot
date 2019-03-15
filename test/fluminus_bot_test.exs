defmodule FluminusBotTest do
  use ExUnit.Case
  doctest FluminusBot

  test "greets the world" do
    assert FluminusBot.hello() == :world
  end
end
