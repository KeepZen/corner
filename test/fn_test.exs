defmodule FnTest do
  use ExUnit.Case, async: true
  import Corner.Fn

  test "fn! sum_one_to(n)" do
    fn! sum_one_to do
      0 -> 0
      n when n > 0 -> n + sum_one_to.(n - 1)
    end

    assert is_function(sum_one_to, 1)
    assert sum_one_to.(10) === 1..10 |> Enum.sum()
    assert sum_one_to.(100) === 5050
  end
end
