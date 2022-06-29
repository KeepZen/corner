defmodule Corner.Try do
  defmacro try!(asts) do
    Macro.postwalk(asts, &walker/1)
    |> make_try()
    |> tap(&(Macro.to_string(&1) |> IO.puts()))
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
