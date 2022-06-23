defmodule ASTTest do
  use ExUnit.Case, async: true
  alias Corner.Ast, as: M

  test "is_variable?" do
    t = M.is_variable?(quote do: a)
    assert t == true

    t = M.is_variable?(quote do: a)
    assert t
    f = M.is_variable?(quote do: [])
    refute f

    f = M.is_variable?(quote do: [a])
    refute f

    f = M.is_variable?(quote do: [a, b])
    refute f

    f = M.is_variable?(quote do: [a, b, c])
    refute f

    f = M.is_variable?(quote do: {})
    refute f

    f = M.is_variable?(quote do: {a})
    refute f

    f = M.is_variable?(quote do: {a, b})
    refute f

    f = M.is_variable?(quote do: {a, b, c})
    refute f

    f = M.is_variable?(quote do: %{a: 2})
    refute f

    f = M.is_variable?(quote do: %Str{a: 2})
    refute f
  end

  test "is_composed_type?(v)" do
    t = M.is_composed_type?(quote do: a)
    assert t == false

    t = M.is_composed_type?(quote do: a)
    assert t == false
    f = M.is_composed_type?(quote do: [])
    assert f

    f = M.is_composed_type?(quote do: [a])
    assert f

    f = M.is_composed_type?(quote do: [a, b])
    refute !f

    f = M.is_composed_type?(quote do: [a, b, c])
    refute !f

    f = M.is_composed_type?(quote do: {})
    refute !f

    f = M.is_composed_type?(quote do: {a})
    refute !f

    f = M.is_composed_type?(quote do: {a, b})
    assert f

    f = M.is_composed_type?(quote do: {a, b, c})
    refute !f

    f = M.is_composed_type?(quote do: %{a: 2})
    refute !f

    f = M.is_composed_type?(quote do: %Str{a: 2})
    refute !f
  end

  defmodule Struct do
    defstruct name: nil
  end

  test "is_map?(v)" do
    assert true ==
             quote(do: %{})
             |> M.is_map?()

    assert true ==
             quote(do: %{1 => 2})
             |> M.is_map?()

    assert true ==
             quote(do: %{age: 2})
             |> M.is_map?()

    assert true ==
             quote(do: %{"hello" => "world", :ok => 1, age: 1})
             |> M.is_map?()

    assert true ==
             quote(do: %Struct{})
             |> M.is_map?()

    assert false ==
             quote(do: {:a, :b, :c})
             |> M.is_map?()
  end

  test "is_struct?(ast)" do
    assert true ==
             quote(do: %Strct{})
             |> M.is_struct?()

    assert false ==
             quote(do: %{})
             |> M.is_struct?()
  end
end
