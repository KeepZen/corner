defmodule Corner.Try do
  @moduledoc """
  Define macro `try!/1`.
  
  `try!/1` is similarly as `try/1`, but in the `rescue` caluses of `try!/1`,
  the pattern match not just by name, but have the full power of  pattern match,
  just like in the caluses of `case`.
  """
  @doc """
  Enhance the `rescue` caluse.
  
  `try!/1` will traseform the code:
  ```elixir
  rescue
    %ErrorType1{filed: filed} -> filed
    %ErrorType2{filed_name: filed} -> filed
  ```
  to:
  ```elixir
  rescue
     v -> case v do
      %MatchError{term: term} -> term
      %Error2{field: f} -> v
  ```
  
  ## Example
  ```elixir
  iex> import Corner.Try, only: [try!: 1]
  iex> try! do
  ...>   {:ok, 1} = {:bad, 1}
  ...> rescue
  ...>  %MatchError{term: term} -> term
  ...> end
  {:bad,1}
  ```
  """
  defmacro try!(do_block)

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
  # `
  defp walker({:rescue, rescue_block}) do
    {:rescue,
     [
       {:->, [],
        [
          [{:V, [], nil}],
          {:case, [], [{:V, [], nil}, [do: rescue_block]]}
        ]}
     ]}
  end

  defp walker(ast), do: ast

  defp make_try(block) do
    {:try, [], [block]}
  end
end
