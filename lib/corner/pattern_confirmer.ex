defmodule Corner.PatternConfirmer do
  @moduledoc """
  Pattern Confirmer.
  
  Define the macro `=~/2`, use to confirmer if a value match a pattern.
  
  Please use it as: `use Corner.PatternConfirmer`.
  """
  import Kernel, except: [=~: 2]
  alias Corner.Ast

  defmacro __using__(_opt) do
    quote do
      import Kernel, except: [=~: 2]
      import Corner.PatternConfirmer, only: [=~: 2]
    end
  end

  @doc """
  Check if `left` have the pattern of `right`.
  
  If `left` is a binary or a variable, it will same as `Kerner.=~/2`.
  """
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
        other_pattern_confirm(left, right)
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

  @excluded_atom [:^, :%{}, :%, :{}]
  defp prewalker({atom, meta, args}) when atom in @excluded_atom do
    args =
      Enum.map(
        args,
        fn
          {atom, meta, value} ->
            {atom, [:exclude | meta], value}

          {atom, other} when atom not in @excluded_atom ->
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
