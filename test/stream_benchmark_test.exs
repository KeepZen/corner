defmodule StreamBenchmarkTest do
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
    for _ <- 1..up do
      @range
      |> Stream.map(&(&1 + 1))
      |> Stream.map(&(&1 - 1))
      |> Enum.to_list()
    end
  end

  test "Enum.map vs Stream.map" do
    arg = [10000]
    task1 = Task.async(fn -> :timer.tc(&fun1/1, arg) end)
    task2 = Task.async(fn -> :timer.tc(&fun2/1, arg) end)

    [{t, v}, {t1, v1}] = Task.await_many([task1, task2], 60_000)
    IO.puts("Enum.map vs Stream.map #{(t - t1) / t * 100}%.")
    assert v == v1
  end
end
