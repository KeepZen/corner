defmodule AsyncTest do
  use ExUnit.Case, async: true
  import Corner.Async

  test "asyn defgen" do
    async defgen(fun) do
      a, b ->
        yield(Promise.resolve(3))
        yield(a)
        yield(b)
    end

    assert is_function(fun, 2)

    list =
      for v <- fun.(2, 1) do
        v
      end

    assert [3, 2, 1] == list
  end
end
