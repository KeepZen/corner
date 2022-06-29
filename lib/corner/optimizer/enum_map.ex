defmodule Corner.Optimizer.EnumMap do
  alias Corner.Optimizer
  @behaviour Optimizer

  @impl Optimizer
  def optimize(__MODULE__, list) do
    reduce_map(list)
  end

  defp reduce_map(ast_list) do
    ast_list
    |> group_function_calls()
    |> Enum.map(&tranceform_group/1)
  end

  defp group_function_calls(fun_call_list) do
    for fun_call <- fun_call_list, reduce: [] do
      [] = acc ->
        if is_map_call(fun_call) do
          [[fun_call] | acc]
        else
          [fun_call | acc]
        end

      [ele | rest] = acc ->
        fun_is_map? = is_map_call(fun_call)

        cond do
          fun_is_map? and is_list(ele) ->
            [[fun_call | ele] | rest]

          fun_is_map? ->
            [[fun_call] | acc]

          true ->
            [fun_call | acc]
        end
    end
    |> Enum.reverse()
  end

  defp is_map_call({{{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}, 0}),
    do: true

  defp is_map_call(_), do: false

  defp tranceform_group(map_calls) when is_list(map_calls) do
    composed_fun =
      map_calls
      |> Enum.map(&get_fun/1)
      |> compose()

    {{{:., [], [{:__aliases__, [], [:Enum]}, :map]}, [], [composed_fun]}, 0}
  end

  defp tranceform_group(other_ast), do: other_ast

  defp get_fun(
         {{
            {:., _, [{:__aliases__, _, [:Enum]}, :map]},
            _,
            [fun]
          }, 0}
       ) do
    fun
  end

  defp compose(list, acc \\ nil)

  defp compose([fun | funs], nil) do
    acc =
      quote do
        unquote(fun).()
      end

    compose(funs, acc)
  end

  defp compose([fun | funs], acc) do
    acc =
      quote do
        unquote(fun).() |> unquote(acc)
      end

    compose(funs, acc)
  end

  defp compose([], acc) do
    quote do
      fn v -> v |> unquote(acc) end
    end
  end
end
