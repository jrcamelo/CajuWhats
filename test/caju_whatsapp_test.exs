defmodule CajuWhatsTest do
  use ExUnit.Case
  doctest CajuWhats

  test "greets the world" do
    assert CajuWhats.hello() == :world
  end
end
