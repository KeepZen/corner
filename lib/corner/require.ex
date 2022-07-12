defmodule Corner.Require do
  @moduledoc """
  Define `require!/1-2`.
  
  `require!/1-2` is same as `Kernel.requir/1-2`, the diffenrent is how to hanld
  default of opts `:as`. `require!` hanlde `:as` same as `alias`.
  """

  @doc """
  ### Example
  ```elixir
  import Corner.Require
  defmodule M.A do
    #... Code
  end
  require! M.A
  A == M.A
  true
  require! M.A, as: B
  B == M.A and A == B
  false
  ```
  """
  defmacro require!(module) do
    quote do
      require unquote(module)
      alias unquote(module)
    end
  end

  defmacro require!(module, as: as) do
    quote do
      require unquote(module), as: unquote(as)
    end
  end
end
