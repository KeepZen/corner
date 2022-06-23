defmodule Corner.PatternConfirmer do
  import Kernel, except: [=~: 2]
  alias Corner.Ast

  defmacro __using__(_opt) do
    quote do
      import Kernel, except: [=~: 2]
      import Corner.PatternConfirmer, only: [=~: 2]
    end
  end

  defmacro left =~ right do
    cond do
      is_binary(left) ->
        text_match(left, right)

      Ast.is_regex?(left) and
          is_binary(right) ->
        text_pattern_confirm(left, right)

      Ast.is_variable?(left) ->
        text_match(left, right)

      true ->
        ast = other_pattern_confirm(left, right)
        # IO.inspect(ast)
        # str = Macro.to_string(ast)
        # IO.puts("L27: #{str}")
        ast
    end
  end

  defp text_match(left, right) do
    quote do
      Kernel.=~(unquote(left), unquote(right))
    end
  end

  @compile online: true
  defp text_pattern_confirm(left, right) do
    text_match(right, left)
  end

  defp other_pattern_confirm(left, right) do
    new_left = Macro.prewalk(left, &prewalker/1)

    quote generated: true do
      match?(unquote(new_left), unquote(right))
    end
  end

  defp prewalker({atom, meta, args}) when atom in [:^, :%{}, :%, :{}] do
    args =
      Enum.map(
        args,
        fn
          {atom, meta, value} ->
            {atom, [:exclude | meta], value}

          {atom, other} when atom not in [:^, :%{}, :%, :{}] ->
            {atom, prewalker(other)}
        end
      )

    {atom, meta, args}
  end

  defp prewalker({atom, [:exclude | meta], value}),
    do: {atom, meta, value}

  defp prewalker({atom, meta, value} = ast) when is_atom(atom) do
    if "#{atom}" |> String.starts_with?("_") do
      ast
    else
      atom = "_#{atom}" |> String.to_atom()
      {atom, meta, value}
    end
  end

  defp prewalker(ast), do: ast
end
