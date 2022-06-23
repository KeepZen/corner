defmodule PatternConfirmerTest do
  use ExUnit.Case, async: true
  doctest Corner.PatternConfirmer
  use Corner.PatternConfirmer
  defstruct name: nil, age: nil

  defmodule M do
    defstruct name: nil, age: nil
  end

  test "string =~ regex" do
    t = "hello" =~ ~r/hell/
    assert t == true
    f = "hello" =~ ~r/wolrd/
    refute f
    regex = ~r/hel{1,2}o/
    t = "hello" =~ regex
    t2 = "helo" =~ regex
    assert t and t2
    f = "world" =~ regex
    refute f
  end

  test "regex =~ string" do
    t = ~r/hel{1,2}o$/ =~ "hello"
    assert t == true
    t = ~R/hel{1,2}o$/ =~ "helo"
    assert t
    f = ~r/hel{1,2}o$/ =~ "world"
    refute f
  end

  test "pattern_just_a_varibal" do
    a = "hello"
    t = a =~ ~r/hello/
    assert t
    regex = ~r/hel{1,2}o/
    regex =~ "hello"
  rescue
    _e ->
      assert true
  else
    _e ->
      refute true
  end

  test "other_patter =~ value " do
    t = [a, b] =~ [1, 2]
    assert t
    a = 1
    array = {1, 2}
    f = {^a, b} =~ array
    assert f
    t1 = 1 =~ 1
    assert t1
    t = {1, _} =~ {1, 2}
    assert t

    t = [1, {a, b}] =~ [1, {:ok, :b}]
    assert t
    t = %{a: a, b: b} =~ %{a: 1, b: :b}
    assert t
    a = 6
    t = [{1, _c}, ^a] =~ [{1, :ok}, 6]
    assert t
    t = %M{name: a, age: b} =~ %__MODULE__{name: "hell", age: 1}
    assert t == false
    t = %{name: a, age: b} =~ %__MODULE__{name: "hell", age: 1}
    assert t == true

    f1 = 1 =~ 2
    refute f1
    f2 = [1, _] =~ {1, 2}
    refute f2
  end
end
