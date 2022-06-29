defmodule Corner.Assign do
  defp do_assign(value, pattern) do
    quote do
      unquote(pattern) = unquote(value)
    end
  end

  defp do_assign(value, pattern, block) do
    quote do
      unquote(pattern) = unquote(value)
      unquote(block)
    end
  end

  defmacro assign(value, to: pattern), do: do_assign(value, pattern)

  defmacro assign(value, to: pattern, do: block),
    do: do_assign(value, pattern, block)

  defmacro to(value, pattern), do: do_assign(value, pattern)
  defmacro to(value, p, do: block), do: do_assign(value, p, block)
end
