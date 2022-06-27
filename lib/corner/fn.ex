defmodule Corner.Fn do
  alias Corner.{SyntaxError, Ast}

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
