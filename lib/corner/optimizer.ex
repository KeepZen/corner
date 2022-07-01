defmodule Corner.Optimizer do
  @moduledoc """
  Optimize expression `...|> Type.map(f1) |> ... |> Type.map(fn)`.
  
  Now it can optimzie `...|> Enum.map(f1) |> ... |> Enum.map(fn)`.
  
  Use the optimizer like fellow code:
  `use Corner.Optimizer`.
  """
  @doc """
  Optimize for `t`.
  """
  @callback optimize(t :: any, ast_list :: []) :: []

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [|>: 2]
      import Corner.Optimizer.Pipe, only: [|>: 2]
    end
  end
end
