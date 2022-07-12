defmodule Corner.Async do
  @moduledoc """
  This Module can be use to define the async function.
  
  A async function return a `Promise`.
  
  About the `Promise` see more at `Corner.Promise`.
  """

  @doc """
  async support for `fn`.
  
  ## Example
  ```elixir
  iex> import Corner.Async, only: [async: 1]
  iex> f = async fn a, b -> a + b end
  iex> p = f.(1,2)
  iex> is_struct(p, Corner.Promise)
  true
  iex> Corner.Promise.await(p)
  {:resolved, 3}
  ```
  """
  defmacro async({:fn, meta, ast}) do
    new_ast = arrow_return_promise(ast)

    {:fn, meta, new_ast}
    # |> tap(&(Macro.to_string(&1) |> IO.puts()))
  end

  @doc """
  async for `def`, `defp` or `defgen`.
  
  About `defgen` see `Corner.Generater`.
  
  ## Example
  ```
  iex> defmodule AsyncFunction do
  ...>   import Corner.Async
  ...>   async def sum(a,b) do
  ...>     a + b
  ...>   end
  ...> end
  iex> alias Corner.Promise
  iex> v = AsyncFunction.sum(1,2)
  iex> is_struct(v, Promise)
  true
  iex> Promise.await(v)
  {:resolved, 3}
  ```
  """
  defmacro async({atom, _meta, args}, do: body) when atom in [:def, :defp] do
    new_body = return_promise(body)

    case atom do
      :def ->
        quote do
          alias Corner.Promise
          import Corner.Promise, only: [await: 1]
          def(unquote_splicing(args), do: unquote(new_body))
        end

      :defp ->
        quote do
          alias Corner.Promise
          import Corner.Promise, only: [await: 1]
          defp(unquote_splicing(args), do: unquote(new_body))
        end
    end

    # |> tap(&(Macro.to_string(&1) |> IO.puts()))
  end

  defmacro async({:defgen, _, [fun_name]}, do: block) do
    new_block = arrow_return_promise(block)

    quote do
      import Corner.Generater
      alias Corner.Promise
      import Corner.Promise, only: [await: 1]
      defgen(unquote(fun_name), true, do: unquote(new_block))
    end

    # |> tap(&(Macro.to_string(&1) |> IO.puts()))
  end

  defp return_promise(ast) do
    quote do
      try do
        unquote(ast)
      rescue
        err ->
          Corner.Promise.reject({err, __STACKTRACE__})
      else
        v ->
          if is_struct(v, Corner.Promise) do
            v
          else
            Corner.Promise.resolve(v)
          end
      end
    end
  end

  defp arrow_return_promise(abs) do
    walker = fn
      {:->, meta, [args, body]} ->
        new_body = return_promise(body)
        {:->, meta, [args, new_body]}

      ast ->
        ast
    end

    Macro.postwalk(abs, walker)
  end
end
