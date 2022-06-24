defmodule MaybeTest do
  use ExUnit.Case, async: true
  import Corner.Maybe

  test "maybe do .. end" do
    v =
      maybe do
        {:ok, a} = {:ok, 1}
        v = {:error, a + 1}
        {:ok, b} = v
        b
      end

    assert v == {:error, 2}
    t = :b not in (binding() |> Keyword.keys())
    assert t == true
  end
end
