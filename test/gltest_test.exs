defmodule GltestTest do
  use ExUnit.Case
  doctest Gltest

  test "greets the world" do
    assert Gltest.hello() == :world
  end
end
