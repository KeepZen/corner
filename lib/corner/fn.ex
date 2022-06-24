defmodule Corner.Fn do
  alias Corner.{SyntaxError, Ast}

  defmacro fn!(name, do: block) do
    case syntax_check(block) do
      {:ok, arity} ->
        var = {:TEM_fun, [], nil}
        tem_fun = make_fn(name, block)
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

  defp syntax_check([{:->, _, [args | _]} | others]) do
    args = Ast.get_args(args)
    check_args_length(others, length(args))
  end

  defp check_args_length([], len) do
    {:ok, len}
  end

  defp check_args_length([{:->, _, [args | _]} | others], len) do
    args = Ast.get_args(args)

    if len == length(args) do
      check_args_length(others, len)
    else
      :error
    end
  end

  defp make_fn(name, body) do
    new_body = Enum.map(body, &clause_handler(name, &1))
    {:fn, [], new_body}
  end

  defp clause_handler(name_ast = {atom, _, _}, {:->, meta, [args | body]}) do
    new_body = Macro.postwalk(body, &correct_recursive_call(atom, &1))

    new_args =
      if new_body != body do
        make_args(args, name_ast)
      else
        name_ast = "_#{atom}" |> String.to_atom()
        make_args(args, {name_ast, [], nil})
      end

    {:->, meta, [new_args | new_body]}
  end

  # ast of `name_atom.(...args)`.
  defp correct_recursive_call(
         atom,
         call = {{:., _, [{atom, _, _} = fun]}, _, args}
       ) do
    call
    |> Tuple.delete_at(2)
    |> Tuple.append([fun | args])
  end

  defp correct_recursive_call(_, ast), do: ast

  defp make_args([{:when, meta, args}], fun) do
    [{:when, meta, [fun | args]}]
  end

  defp make_args(args, fun) do
    [fun | args]
  end
end
