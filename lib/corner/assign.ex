defmodule Corner.Assign do
  @moduledoc """
  Define the macro `assing/2` and `to/2-3` make the code more clean.
  
  ## Example
  ```elixir
  require Corner.Assign, as: Assign
  function_return_tag_value()
  |> Assign.to({:ok, v}, do: v + 1)
  |> go_on_work_with_v_plus_one()
  ```
  Or if you more like `import`:
  ```elixir
  import Corner.Assign, only: [assign: 2]
  function_return_tag_value()
  |> assign(to: {:ok, v}, do: v + 1)
  |> go_on_work_with_v_plus_one()
  ```
  """
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

  @doc """
  Assign `value` to the variable(s) in the `pattern`.
  
  The `keyword` shold be `[to: pattern]` or `[to: pattern, do: expression]`.
  
  If the `keyword` is `[to: pattern]` the value of this function is the `value`.
  
  If the `keyword` have the option `:do`, the value of the `expression` will
  be return.
  """
  defmacro assign(value, keyword)
  defmacro assign(value, to: pattern), do: do_assign(value, pattern)

  defmacro assign(value, to: pattern, do: block),
    do: do_assign(value, pattern, block)

  @doc """
  Same as `assign(value, to: pattern)`.
  """
  defmacro to(value, pattern), do: do_assign(value, pattern)

  @doc """
  Same as `assgin(value, to: pattern, do: block)`.
  """
  defmacro to(value, pattern, do_block)
  defmacro to(value, pattern, do: block), do: do_assign(value, pattern, block)
end
