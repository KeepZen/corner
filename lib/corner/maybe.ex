defmodule Corner.Maybe do
  defmacro maybe(do: body) do
    quote generated: true do
      try do
        unquote(body)
      catch
        :error, {:badmatch, v} -> v
      end
    end

    # |> then(&(Macro.to_string(&1) |> IO.puts()))
  end

  defmacro maybe(do: body, else: tail) do
    quote do
      try do
        unquote(body)
      catch
        :error, {:badmatch, v} ->
          case v do
            unquote(tail)
          end
      end
    end
  end
end
