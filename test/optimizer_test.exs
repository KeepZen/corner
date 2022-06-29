defmodule OptimizerTest do
  use ExUnit.Case, async: true
  use Corner.Optimizer

  test "Enum.map" do
    add_one = fn v ->
      IO.puts("+1")
      v + 1
    end

    sub_one = fn v ->
      IO.puts("-1")
      v - 1
    end

    t =
      1..5
      |> Enum.map(add_one)
      |> Enum.map(sub_one)
      |> IO.inspect(label: "after optimizer")

    assert t == [1, 2, 3, 4, 5]
  end
end
