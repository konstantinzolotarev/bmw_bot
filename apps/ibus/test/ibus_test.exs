defmodule IbusTest do
  use ExUnit.Case
  doctest Ibus

  test "greets the world" do
    assert Ibus.hello() == :world
  end
end
