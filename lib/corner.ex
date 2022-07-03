defmodule Corner do
  @moduledoc """
  This module is explort the corner of elixir and enhance of it, for writing
  more clean code.
  """
  defmacro __using__(_opt) do
    quote do
      alias Corner.{
        Assign,
        Ast,
        Async,
        Fn,
        Generater,
        Maybe,
        Module.Explorer,
        Optimizer,
        PatternConfirmer,
        PatternExtracter,
        Rename,
        Require,
        Try,
        Tuple
      }
    end
  end
end
