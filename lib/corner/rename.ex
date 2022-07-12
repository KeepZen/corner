defmodule Corner.Rename do
  @moduledoc """
  Define macro `rename/2`.
  """

  @doc """
  `rename/2` is used to rename function in a module a  new name.
  
  `rename` suport two format:
  1. give function arity as: `reanme ModuleName.fun_name/2, to: new_fun_name`.
  2. not give the function arity, as: `rename ModuleName.fun_name, to: new_fun_name`.
  
  ## Example
  ```
  iex> defmodule M do
  ...>   import Corner.Rename, only: [rename: 2]
  ...>   rename String.length, to: str_len
  ...>   rename String.at/2, to: str_at
  ...>   def test() do
  ...>     str = "Hello"
  ...>     str_len(str) == String.length(str)
  ...>       and String.at(str,1) === str_at(str,1)
  ...>   end
  ...> end
  iex> M.test()
  true
  ```
  """
  defmacro rename(fun, to: new_name) do
    do_rename(fun, new_name)
    # |> tap(&(Macro.to_string(&1) |> IO.puts()))
  end

  defp do_rename({:/, _, [m_f, arity]}, {new_name, _, _}) do
    {{:., _, [module, fun]}, _, _} = m_f
    ast = make_private(module, fun, arity, new_name)

    quote do
      (unquote_splicing(ast))
    end
  end

  defp do_rename({{:., _, m_f}, _, _}, {new_name, _, _}) do
    [module, fun_name] = m_f
    aritys = get_aritys(module, fun_name)

    ast =
      for arity <- aritys do
        make_private(module, fun_name, arity, new_name)
      end
      |> List.flatten()

    quote do
      (unquote_splicing(ast))
    end
  end

  defp get_aritys(module, fun) do
    {aritys, _} =
      quote do
        unquote(module).module_info(:exports)
        |> Enum.filter(fn {key, _v} -> key == unquote(fun) end)
        |> Enum.map(fn {_key, value} -> value end)
      end
      |> Code.eval_quoted()

    aritys
  end

  defp make_private(module, fun, arity, new_name) do
    args = Macro.generate_arguments(arity, nil)

    {_, _, asts} =
      quote do
        @compile online: true
        defp unquote(new_name)(unquote_splicing(args)) do
          unquote(module).unquote(fun)(unquote_splicing(args))
        end
      end

    asts
  end
end
