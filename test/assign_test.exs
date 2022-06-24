defmodule AssignTest do
  use ExUnit.Case, async: true
  import Corner.Assign

  test "assign value , to: v" do
    assign(10, to: v)
    assert v == 10
  end

  test "value |> assgin to: v" do
    10
    |> assign(to: v)

    assert v === 10
  end

  test "value |> assing to: v, do: v+1" do
    {:ok, 10}
    |> assign(
      to: {:ok, v},
      do:
        (
          v = v + 1
          v
        )
    )

    assert v == 11
  end
end
