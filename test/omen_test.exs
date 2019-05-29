defmodule OmenTest do
  use ExUnit.Case
  doctest Omen

  test "greets the world" do
    assert Omen.hello() == :world
  end
end
