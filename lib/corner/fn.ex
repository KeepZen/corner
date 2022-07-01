defmodule Corner.Fn do
  @moduledoc """
  This module define macro `fn!/2`.
  
  `fn!/2` can be use to define recursivable anonymous function.
  
  ## Example
  ```
  iex> import Corner.Fn
  iex> fn! sum_to do
  ...>   0 -> 0
  ...>  n when is_integer(n) and n > 0  -> n + sum_to.(n - 1)
  ...> end
  iex> sum_to.(100)
  iex> 5050
  ```
  """
  alias Corner.{SyntaxError, Ast}

  @doc """
  Define recursivalbe anonymous function.
  
  `name` is the name of  the anonymous function.
  
  `block` is the caluses of the function, same as in `fn`.
  
  This macro will inject variable `name` to caller's context.
  """
  defmacro fn!(name, do: block) do
    case Ast.clauses_arity_check(block) do
      {:ok, arity} ->
        var = {:TEM_fun, [], nil}
        tem_fun = Ast.make_recursive_fn(name, block, &correct_args/2)
        params = Macro.generate_arguments(arity, nil)

        quote do
          unquote(name) = fn unquote_splicing(params) ->
            unquote(var) = unquote(tem_fun)
            unquote(var).(unquote(var), unquote_splicing(params))
          end
        end

      :error ->
        raise SyntaxError, "the clauses must have the same arity."
    end
  end

  defp correct_args([{:when, meta, args}], fun) do
    [{:when, meta, [fun | args]}]
  end

  defp correct_args(args, fun) do
    [fun | args]
  end
end
