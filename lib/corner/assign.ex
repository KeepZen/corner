defmodule Corner.Assign do
  defmacro assign(value, to: pattern) do
    quote do
      unquote(pattern) = unquote(value)
    end
  end

  defmacro assign(value, to: pattern, do: expression) do
    quote generated: true do
      unquote(pattern) = unquote(value)
      unquote(expression)
    end
  end
end
