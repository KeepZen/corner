defmodule Corner.Optimizer do
  @callback optimize(t :: any, ast_list :: List.t()) :: List.t()

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [|>: 2]
      import Corner.Optimizer.Pipe, only: [|>: 2]
    end
  end
end
