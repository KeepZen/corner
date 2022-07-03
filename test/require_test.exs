defmodule M.A.B do
  def hello, do: :hello
end

defmodule RequireTest do
  use ExUnit.Case
  import Corner.Require

  test "require!" do
    require!(M.A.B)
    assert B === M.A.B
    require!(M.A.B, as: C)
    assert C === B and B === M.A.B
  end
end
