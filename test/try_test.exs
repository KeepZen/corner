defmodule Maybe do
  defmacro maybe(do: block, else: else_block) do
    quote do
      import Corner.Try

      try! do
        unquote(block)
      rescue
        %MatchError{term: term} -> {term, binding[:V]}
      else
        unquote(else_block)
      end
    end
  end
  |> tap(&(Macro.to_string(&1) |> IO.puts()))
end

defmodule TryTest do
  use ExUnit.Case
  doctest Corner.Try

  test "try" do
    import Maybe

    t =
      maybe do
        {:ok, a} = {:ok, 1}
        {:ok, c} = [a, a + 1]
        c + 1
      else
        [a, b] -> [a, b]
      end

    assert {[1, 2], %MatchError{term: [1, 2]}} == t
  end
end
