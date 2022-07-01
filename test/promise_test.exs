defmodule PromiseTest do
  # , async: true
  use ExUnit.Case
  alias Corner.Promise

  setup_all do
    fun = fn number, resolve, reject ->
      cond do
        number > 0 -> resolve.(number)
        number < 0 -> reject.(number)
        true -> raise "Bad zero"
      end
    end

    %{fun: fun}
  end

  test "Promise.resolve(v)" do
    p = Promise.resolve(10)
    assert p.state == :pending
  end

  test "Promise.reject(v)" do
    p = Promise.reject(10)
    assert p.state == :pending
  end

  test "Promise.of/2" do
    p = Promise.of(100)
    assert p.state == :pending
    p = Promise.of(100, :rejected)
    assert p.state == :pending
  end

  test "Promise.new(fun/2)", %{fun: fun} do
    %{state: state} = Promise.new(&fun.(10, &1, &2))
    assert state == :pending
    %{state: state} = Promise.new(&fun.(-10, &1, &2))
    assert state == :pending
    %{state: state} = Promise.new(&fun.(0, &1, &2))
    assert state == :pending
  end

  test "Promise.await(p)", %{fun: fun} do
    p = Promise.new(&fun.(10, &1, &2)) |> Promise.await()
    assert {:resolved, 10} == p

    p = Promise.new(&fun.(-10, &1, &2)) |> Promise.await()
    assert {:rejected, -10} == p

    p = Promise.new(&fun.(0, &1, &2)) |> Promise.await()
    {tag, {v, stack}} = p
    assert tag == :error and is_exception(v) == true and is_list(stack)

    # IO.inspect("=========", label: __ENV__.file <> ":#{__ENV__.line}")
    assert {:resolved, 1} = Promise.resolve(1) |> Promise.await()
    {tag, v} = Promise.new(fn _, _ -> :ok end) |> Promise.await()
    assert tag == :stop
    assert v == :done
  end

  test "Promise.map(fun/1)", %{fun: fun} do
    p = Promise.new(&fun.(10, &1, &2)) |> Promise.map(fn v -> v + 1 end)
    assert is_struct(p, Promise)
    assert p.state == :pending
    {tag, v} = p |> Promise.await()
    assert tag == :resolved
    assert v == 11

    p = Promise.new(&fun.(-10, &1, &2)) |> Promise.map(fn v -> v + 1 end)
    assert is_struct(p, Promise)
    assert p.state == :pending
    {tag, v} = p |> Promise.await()
    assert tag == :resolved
    assert v == -9

    p =
      Promise.new(&fun.(0, &1, &2))
      |> Promise.map(fn
        {:error, {error, stack}} ->
          assert is_exception(error)
          assert is_list(stack)
          :return_by_map
      end)

    assert is_struct(p, Promise)
    assert p.state == :pending
  end

  test "Promise.then(fun1/1,fun2/1)", %{fun: fun} do
    {tag, v} =
      Promise.new(&fun.(10, &1, &2))
      |> Promise.then(
        fn v ->
          assert v == 10
          v + 1
        end,
        fn e ->
          assert e
          :return_fun2
        end
      )
      |> Promise.await()

    assert tag == :resolved
    assert v == 11

    {tag, v} =
      Promise.new(&fun.(-10, &1, &2))
      |> Promise.then(
        fn v ->
          assert v == :return_fun1
        end,
        fn e ->
          assert e == -10
          e - 1
        end
      )
      |> Promise.await()

    assert tag == :resolved
    assert v == -11

    {tag, v} =
      Promise.new(&fun.(0, &1, &2))
      |> Promise.then(
        fn v ->
          assert v == :return_fun1
        end,
        fn {:error, {exp, stack}} ->
          assert is_exception(exp)
          assert is_list(stack)
          :return_by_error_handler
        end
      )
      |> Promise.await()

    assert tag == :resolved
    assert v == :return_by_error_handler
  end

  test "Promise.then(fun/1)", %{fun: fun} do
    {tag, v} =
      Promise.new(&fun.(10, &1, &2))
      |> Promise.then(fn v ->
        assert v == 10
        :return_by_fun
      end)
      |> Promise.await()

    assert tag == :resolved
    assert v == :return_by_fun

    {tag, v} =
      Promise.new(&fun.(-10, &1, &2))
      |> Promise.then(fn _v ->
        assert 11 == 10
        :return_by_fun
      end)
      |> Promise.await()

    assert tag == :rejected
    assert v == -10

    {tag, v} =
      Promise.new(&fun.(0, &1, &2))
      |> Promise.then(fn _v ->
        assert 11 == 10
        :return_by_fun
      end)
      |> Promise.await()

    assert tag == :error
    assert 2 == tuple_size(v)
  end

  test "Promise.on_error(fun/1)", %{fun: fun} do
    {tag, v} =
      Promise.new(&fun.(-10, &1, &2))
      |> Promise.on_error(fn v ->
        assert -10 == v
        v - 1
      end)
      |> Promise.await()

    assert tag == :resolved
    assert v == -11

    {tag, v} =
      Promise.new(&fun.(0, &1, &2))
      |> Promise.on_error(fn {:error, {exp, stack}} ->
        assert is_exception(exp)
        assert is_list(stack)
        :rescued_by_on_error
      end)
      |> Promise.await()

    assert tag == :resolved
    assert v == :rescued_by_on_error

    {tag, v} =
      Promise.new(&fun.(10, &1, &2))
      |> Promise.on_error(fn _v ->
        assert -10 == 10
        :can_not_run_here
      end)
      |> Promise.await()

    assert tag == :resolved
    assert v == 10
  end
end
