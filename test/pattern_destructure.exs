defmodule PatternDesctructureTest do
  use ExUnit.Case, async: true
  import Corner.PatternDestructure

  test "list_not_nest <~ list" do
    [a, b] <~ [1, 2, 3]
    assert a == 1
    assert b == 2
    array = [1, 2, 3]
    [a, b] <~ array
    assert a == 1
    assert b == 2
    [a, b, c] <~ [1]
    assert a == 1
    assert b == nil
    assert c == nil
  end

  test "list_nest <~ list" do
    [a, [b, c]] <~ [1, [2], 3]
    assert a == 1
    assert b == 2
    assert c == nil
  end

  test "list_nest <~ not_a_list" do
    quote do
      [a] <~ 1
    end
    |> Code.eval_quoted()
  rescue
    _err ->
      # IO.inspect(err)
      assert 1 == 1
  else
    _ ->
      assert 1 == 2
  end

  test "tuple_not_nest <~ tuple" do
    {a, b} <~ {1, 2}
    assert a == 1
    assert b == 2
    {a, b} <~ {1}
    assert a == 1
    assert b == nil

    {a} <~ {1, 2}
    assert a == 1
  end

  test "tuple_nest <~ tuple" do
    {a, {b, c}} <~ {1, {2}, 3}
    assert a == 1 and b == 2 and c == nil
    {a, {b, c}} <~ {1, {2, 3, 4}, 5}
    assert a == 1 and b == 2 and c == 3
  end

  test "map_no_nest <~ map" do
    %{a: a, b: b} <~ %{a: 1, c: 3}
    assert a == 1 and b == nil
    map = %{a: 1, c: 2}
    %{a: a, b: b} <~ map
    assert a == 1 and b == nil
    %{:a => b} <~ map
    assert b == 1
  end

  test "map_nest <~ map" do
    %{a: a, b: %{b: b}} <~ %{a: 1, b: %{}, c: 3}
    assert a == 1 and b == nil

    %{
      a: a,
      b: %{b: b}
    }
    <~ %{
      %{a: :nest_a} => 2,
      a: 1,
      b: %{b: 1},
      c: 3
    }

    assert b == 1 and a == 1
  end

  test "other <~ value" do
    array = [1, 2, 3]
    a = 1
    [^a, b, c, d, e] <~ array
    assert a == 1 and b == 2 and c == 3 and d == nil and e == nil

    quote do
      a <~ 1
    end
    |> Code.eval_quoted()
  rescue
    e in Corner.PatternDestructure.SyntaxError ->
      IO.inspect(e.message)
      assert 1 == 1
  end
end
