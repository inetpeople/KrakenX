defmodule KrakenXTest do
  use ExUnit.Case
  doctest KrakenX

  test "greets the world" do
    assert KrakenX.hello() == :world
  end
end
