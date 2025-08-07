defmodule GloryTest do
  use ExUnit.Case
  doctest Glory

  test "greets the world" do
    assert Glory.hello() == :world
  end
end
