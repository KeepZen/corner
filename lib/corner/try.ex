defmodule Corner.Try do
  @moduledoc """
  Define macro `try!/1`.
  
  `try!/1` is similarly as `try/1`, but in the `rescue` caluses of `try!/1`,
  the pattern match not just by name, but have the full power of  pattern match,
  juse like in the caluses of `case`.
  """
  defmacro try!(asts) do
    Macro.postwalk(asts, &walker/1)
    |> make_try()

    # |> tap(&(Macro.to_string(&1) |> IO.puts()))
  end

  # tramseform
  # `rescue
  #     %MatchError{term: term} -> term
  #     %Error2{field: f} -> v
  # `
  # to
  # `rescue
  #    v -> case v do
  #     %MatchError{term: term} -> term
  #     %Error2{field: f} -> v
  #    end
  defp walker({:rescue, rescue_block}) do
    {:rescue,
     [
       {:->, [],
        [
          [{:v, [], nil}],
          {:case, [], [{:v, [], nil}, [do: rescue_block]]}
        ]}
     ]}
  end

  defp walker(ast), do: ast

  defp make_try(block) do
    {:try, [], [block]}
  end
end
