defmodule OptimizeBenchmarkTest do
  use ExUnit.Case, async: true
  @range 1..1000

  def fun1(up \\ 10) do
    for _ <- 1..up do
      @range
      |> Enum.map(&(&1 + 1))
      |> Enum.map(&(&1 - 1))
    end
  end

  def fun2(up \\ 10) do
    use Corner.Optimizer

    for _ <- 1..up do
      @range
      |> Enum.map(&(&1 + 1))
      |> Enum.map(&(&1 - 1))
    end
  end

  test "Optimizer of |> for Enum.map" do
    arg = [10000]
    task1 = Task.async(fn -> :timer.tc(&fun1/1, arg) end)
    task2 = Task.async(fn -> :timer.tc(&fun2/1, arg) end)

    [{t, v}, {t1, v1}] = Task.await_many([task1, task2], 60_000)
    IO.puts("After Optimize Enum.map speed up #{(t - t1) / t1 * 100}%.")
    assert v == v1
  end
end
