defmodule Corner.Maybe do
  @moduledoc """
  Define macro `maybe/1`.
  
  `maybe/1` can be used to replace `with`.
  
  ## Example
  ```elixir
  import Corner.Maybe
  maybe do
    {:ok, v} = a_function_return_tab_result() # {:ok|:error, any}
    # do work with v
  else
    {:error, v} -> # error handler
  end
  ```
  """
  @doc """
  This is samilary as Eralng future of `maybe`.
  
  `do_block` can have a `:else` option.
  """
  defmacro maybe(do_block)

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
