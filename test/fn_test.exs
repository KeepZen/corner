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

    fn! produce_one_to do
      1, acc -> acc
      n, acc -> produce_one_to.(n - 1, n * acc)
    end

    assert produce_one_to.(3, 1) == 6
    assert is_function(produce_one_to, 2)
  end
end
