defmodule Corner.Optimizer.Pipe do
  @moduledoc false
  import Kernel, except: [|>: 2]
  alias Corner.Optimizer.{EnumMap}
  @optimizer [EnumMap]
  defmacro left |> right do
    [{h, _} | t] = Macro.unpipe({:|>, [], [left, right]})

    fun = fn {x, pos}, acc ->
      Macro.pipe(acc, x, pos)
    end

    t = Enum.reduce(@optimizer, t, &apply(&1, :optimize, [&1, &2]))
    :lists.foldl(fun, h, t)
  end
end
