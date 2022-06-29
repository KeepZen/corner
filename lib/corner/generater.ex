defmodule Corner.Generater do
  defstruct ref: nil, pid: nil, async: false
  alias Corner.Ast

  defmacro defgen(name, async \\ false, do: block) do
    case Ast.clauses_arity_check(block) do
      {:ok, arity} ->
        tem_fun = {:TEM_fun, [], nil}
        tem_fun_ast = Ast.make_recursive_fn(name, block, &make_args/2)
        params = Macro.generate_arguments(arity, nil)

        quote do
          unquote(name) = fn unquote_splicing(params) ->
            unquote(tem_fun) = unquote(tem_fun_ast)
            # async = unquote(async)
            me = self()

            ref = make_ref()

            fun = fn ->
              try do
                unquote(tem_fun).(unquote(tem_fun), me, ref, unquote_splicing(params))
              rescue
                error -> send(me, {ref, {:error, error, __STACKTRACE__}})
              end
            end

            pid = spawn(fun)
            struct(unquote(__MODULE__), pid: pid, ref: ref, async: unquote(async))
          end
        end
        |> Macro.postwalk(&yield_to_send(async, &1))

      # |> tap(&(Macro.to_string(&1) |> IO.puts()))

      :error ->
        {:=, [name, {:fn, [], block}]}
    end
  end

  def next(%__MODULE__{} = m, v \\ nil) do
    if running?(m) do
      %{pid: pid, ref: ref} = m
      send(pid, v)

      receive do
        {^ref, [v]} -> {:ok, v}
        {^ref, v} -> v
      end
    else
      :done
    end
  end

  def running?(%__MODULE__{pid: pid}) do
    pid && Process.alive?(pid)
  end

  def done?(%__MODULE__{} = m), do: !running?(m)

  @pid {:pid, [], nil}
  @ref {:ref, [], nil}
  defp make_args([{:when, meta, args}], fun) do
    [{:when, meta, [fun, @pid, @ref | args]}]
  end

  defp make_args(args, fun) do
    [fun, @pid, @ref | args]
  end

  @doc """
       Transform `c = yield a`
       """ && false
  defp yield_to_send(async, {:=, m1, [left, {:yield, _, _} = yield_exp]}) do
    receive_and_send = yield_to_send(async, yield_exp)

    {:=, m1, [left, receive_and_send]}
  end

  @doc """
       Transform `yield a` to
       `
       receive do
         v -> send(pid,{ref,[a]})
         v
       end
       `
       """ && false
  defp yield_to_send(async, {:yield, _meta, exp}) do
    pid = @pid
    ref = @ref

    return_value =
      if async do
        quote do
          [t] = unquote(exp)

          if is_struct(t, Corner.Promise) do
            [t]
          else
            [Corner.Promise.resolve(t)]
          end
        end
      else
        quote do
          unquote(exp)
        end
      end

    quote do
      receive do
        v ->
          send(unquote(pid), {unquote(ref), unquote(return_value)})
          v
      end
    end
  end

  defp yield_to_send(_, a), do: a
end

defimpl Enumerable, for: Corner.Generater do
  alias Corner.Promise
  alias Corner.Generater, as: G
  require Corner.Assign, as: Assign

  def reduce(%G{}, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def reduce(%G{} = g, {:suspend, acc}, _fun) do
    {:suspended, acc, fn _acc -> Process.exit(g.pid, :kill) end}
  end

  def reduce(%G{} = g, {:cont, acc}, fun) do
    if G.done?(g) do
      {:done, acc}
    else
      get_next(g, acc, fun)
    end
  end

  defp get_next(%G{} = g, acc, fun) do
    case G.next(g) do
      {:ok, v} ->
        if g.async or is_struct(v, Promise) do
          {_tag, v} = Promise.await(v)
          if is_struct(v, Promise), do: Promise.await(v), else: v
        else
          v
        end
        |> Assign.to(new_v)

        reduce(g, fun.(new_v, acc), fun)

      {:error, error, stack} ->
        {:done, {:error, error: error, stack: stack}}

      :done ->
        {:done, acc}

      v ->
        IO.inspect(v, label: __ENV__.file <> ":163")
    end
  end

  @_ {:_, [if_undefined: :apply], Elixir}
  for {fun, args} <- [count: [@_], slice: [@_], member?: [@_, @_]] do
    def unquote(fun)(unquote_splicing(args)) do
      {:error, __MODULE__}
    end
  end
end
