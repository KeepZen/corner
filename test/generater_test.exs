defmodule GeneraterTest do
  use ExUnit.Case, async: true
  import Corner.Generater

  test "defgen create fn" do
    defgen my_generater do
      a, b when a > b ->
        c = yield(a)
        d = yield(c + b)
        yield(d)

      a, b ->
        yield(a)
        yield(b)
        yield(a + b)
    end

    assert true == :my_generater in (binding() |> Keyword.keys())
    assert is_function(my_generater, 2)
    g = my_generater.(4, 1)
    # set c to 2
    assert {:ok, 4} = next(g, 2)
    # set d to 3
    assert {:ok, 3} = next(g, 3)
    assert {:ok, 3} = next(g)
    assert :done = next(g)
    g = my_generater.(1, 4)
    assert 3 == Enum.count(g)

    g = my_generater.(1, 4)
    assert true == Enum.member?(g, 5)
    assert done?(g)
  end
end
