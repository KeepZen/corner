defmodule Corner.PatternExtracter do
  @moduledoc """
  This module can help to extracte value base on pattern.

  This module define macro `<~/2`. We can use it extract value base on pattern.

  ## Example
  ```
  iex> import Corner.PatternExtracter
  iex> {:ok, [a,b,c]} <~ {:ok, [1]}
  iex> a
  iex> 1
  iex> b
  iex> nil
  iex> c
  iex> nil
  ```
  """
  alias Corner.{Ast, SyntaxError, Tuple}
  alias __MODULE__.Helpers

  defmacro pattern <~ value do
    my_destructure(pattern, value)
  end

  defp my_destructure(pattern, value) do
    cond do
      is_list(pattern) ->
        destructure_list(pattern, value)

      Ast.is_tuple?(pattern) ->
        destructure_tuple(pattern, value)

      not Ast.is_struct?(pattern) and Ast.is_map?(pattern) ->
        destructure_map(pattern, value)

      true ->
        raise_syntax_error(pattern)
    end
  end

  defp destructure_list(pattern, value) when is_list(pattern) do
    {
      var_patterns,
      nest_destructure_ast
    } = Helpers.split_nest_pattern(pattern, &my_destructure/2)

    quote generated: true do
      destructure(unquote(var_patterns), unquote(value))
      unquote_splicing(nest_destructure_ast)
    end
  end

  defp destructure_tuple(pattern, tuple) do
    pattern_size = Ast.tuple_size(pattern)

    {patterns, nest_destruct_ast} =
      Ast.tuple_to_list(pattern)
      |> Helpers.split_nest_pattern(&my_destructure/2)

    pattern = {:{}, [], patterns}

    quote do
      tuple = unquote(tuple)
      m = unquote(__MODULE__).Helpers
      patch_right = m.make(tuple, to_size: unquote(pattern_size))
      unquote(pattern) = patch_right
      unquote_splicing(nest_destruct_ast)
    end
  end

  defp destructure_map(pattern, value) do
    keys = Ast.map_keys(pattern)

    {values, nest_destruct_ast} =
      Ast.map_values(pattern)
      |> Helpers.split_nest_pattern(&my_destructure/2)

    map = Ast.make_map(keys, values)
    default_value = make_default(pattern)

    quote do
      unquote(map) = Map.merge(unquote(default_value), unquote(value))
      unquote_splicing(nest_destruct_ast)
    end
  end

  defp make_default(ast) do
    Macro.postwalk(ast, &variable_to_nil/1)
  end

  defp variable_to_nil({atom, _, context})
       when is_atom(atom) and context in [Elixir, nil],
       do: nil

  defp variable_to_nil(v), do: v

  defp raise_syntax_error(pattern) do
    descript =
      cond do
        Ast.is_variable?(pattern) ->
          "a variable: `#{elem(pattern, 0)}`"

        Ast.is_pin?(pattern) ->
          "a pin :`" <> Macro.to_string(pattern) <> "`"

        true ->
          "`#{Macro.to_string(pattern)}`"
      end

    message =
      "The first parame should be a list, tuple or map, " <>
        "but get #{descript}."

    raise SyntaxError, message
  end

  defmodule Helpers do
    def split_nest_pattern(ast, fun) do
      {var_patterns, map} = change_composed_pattern_to_variable(ast)

      nest_destruct_ast = Enum.map(map, &fun.(elem(&1, 0), elem(&1, 1)))

      {var_patterns, nest_destruct_ast}
    end

    defp change_composed_pattern_to_variable(ast) do
      {patterns, map} =
        for ele <- ast, reduce: {[], %{}} do
          {patterns, map} ->
            if Ast.is_composed_type?(ele) do
              mid_var = Macro.unique_var(:var_for_destruct, __MODULE__)
              patterns = [mid_var | patterns]
              map = Map.put(map, ele, mid_var)
              {patterns, map}
            else
              {[ele | patterns], map}
            end
        end

      {Enum.reverse(patterns), map}
    end

    def make(tuple, to_size: size) do
      diff = tuple_size(tuple) - size

      case diff do
        0 -> tuple
        n when n > 0 -> Tuple.drop(tuple, n, at: :tail)
        n when n < 0 -> Tuple.padding(tuple, -n, at: :tail)
      end
    end
  end
end
