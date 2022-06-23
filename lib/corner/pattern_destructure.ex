defmodule Corner.PatternDestructure do
  alias Corner.{Ast, SyntaxError}
  alias __MODULE__.Helpers

  defmacro left <~ right do
    my_destruct(left, right)
  end

  defp my_destruct(left, right) do
    cond do
      is_list(left) ->
        destructure_list(left, right)

      Ast.is_tuple?(left) ->
        destructure_tuple(left, right)

      # map
      match?({:%{}, _, _}, left) ->
        destructure_map(left, right)

      true ->
        descript =
          if Ast.is_variable?(left) do
            "variable: `#{elem(left, 0)}`"
          else
            inspect(left)
          end

        message =
          "The first parame should be a list, tuple or map, " <>
            "but get a #{descript}."

        raise SyntaxError, message
    end
  end

  defp destructure_list(left, right) when is_list(left) do
    {
      var_patterns,
      nest_destructure_ast
    } = Helpers.split_nest_pattern(left, &my_destruct/2)

    quote generated: true do
      destructure(unquote(var_patterns), unquote(right))
      unquote_splicing(nest_destructure_ast)
    end
  end

  defp destructure_tuple(left, right) do
    left_size = Ast.tuple_size(left)

    {patterns, nest_destruct_ast} =
      Ast.tuple_to_list(left)
      |> Helpers.split_nest_pattern(&my_destruct/2)

    left = {:{}, [], patterns}

    quote do
      right = unquote(right)
      diff = unquote(left_size) - tuple_size(right)
      patch_right = Corner.Helpers.tuple_padding(right, diff)
      unquote(left) = patch_right
      unquote_splicing(nest_destruct_ast)
    end
  end

  defp destructure_map(left, right) do
    keys = Ast.map_keys(left)

    {values, nest_destruct_ast} =
      Ast.map_values(left)
      |> Helpers.split_nest_pattern(&my_destruct/2)

    map = Ast.make_map(keys, values)
    default_value = make_default(left)

    quote do
      unquote(map) = Map.merge(unquote(default_value), unquote(right))
      unquote_splicing(nest_destruct_ast)
    end
  end

  defp make_default(ast) do
    Macro.postwalk(ast, &varable_to_nil/1)
  end

  defp varable_to_nil({atom, _, context})
       when is_atom(atom) and context in [Elixir, nil],
       do: nil

  defp varable_to_nil(v), do: v

  defmodule Helpers do
    def split_nest_pattern(ast, fun) do
      {var_patterns, map} = change_composed_pattern_to_variable(ast)

      nest_destruct_ast = Enum.map(map, &fun.(elem(&1, 1), elem(&1, 0)))

      {var_patterns, nest_destruct_ast}
    end

    def change_composed_pattern_to_variable(ast) do
      {patterns, map} =
        for ele <- ast, reduce: {[], %{}} do
          {patterns, map} ->
            if Ast.is_composed_type?(ele) do
              var = Macro.unique_var(:var_for_destruct, __MODULE__)
              patterns = [var | patterns]
              map = Map.put(map, var, ele)
              {patterns, map}
            else
              {[ele | patterns], map}
            end
        end

      {Enum.reverse(patterns), map}
    end
  end
end
