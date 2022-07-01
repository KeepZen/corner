defmodule Corner.Ast do
  @moduledoc """
  Helpers for operating AST.
  
  The first parameter suggested to be an ast for all of functions
  exception of `make_map/2` in this module.
  """
  import Kernel, except: [tuple_size: 1]

  @doc """
  Check if the `ast` is the ast of a variable.
  """
  def is_variable?(ast)

  def is_variable?({atom, _, _})
      when is_atom(atom) and atom not in [:%, :{}, :%{}, :^],
      do: true

  def is_variable?(_), do: false

  @doc """
  Check if the ast is compsed type.
  
  Map, tuple, and struct and list are reconized as compsed type.
  """
  def is_composed_type?({atom, _, _}) when atom in [:%, :{}, :%{}], do: true

  def is_composed_type?(ast),
    do:
      is_list(ast) or
        (is_tuple(ast) and tuple_size(ast) < 3)

  @doc """
  Check if the ast is a tuple.
  """
  def is_tuple?({:{}, _, _}), do: true
  def is_tuple?({_, _}), do: true
  def is_tuple?(_), do: false

  @doc """
  Check if the ast is a Regex.
  
  `sigil_r/1` and `sigile_R/1` are reconized as regex.
  
  But a variable whicn biding a Regex strcut not regconized as a regex.
  """
  def is_regex?({atom, _, _}) when atom in [:sigil_r, :sigil_R], do: true
  def is_regex?(_), do: false

  @doc """
  If the ast is a tuple, return the size of the tuple.
  """
  def tuple_size({_, _}), do: 2

  def tuple_size(ast) do
    if is_tuple?(ast) do
      length(elem(ast, 2))
    else
      {:error, :not_tuple_ast}
    end
  end

  @doc """
  Convert tuple to list.
  """
  def tuple_to_list(ast) do
    if tuple_size(ast) == 2 do
      Tuple.to_list(ast)
    else
      elem(ast, 2)
    end
  end

  @doc """
  Convert list to tuple.
  """
  def list_to_tuple(ast) when is_list(ast) do
    {:{}, [], ast}
  end

  @doc """
  Check if the ast is a map.
  
  An ast of a struct is also reconized as a map,
  but a variable which binding a value of map or struct is not.
  """
  def is_map?({atom, _meta, _kvs}) when atom in [:%, :%{}], do: true
  def is_map?(_ast), do: false

  @doc """
  Check if the ast is a struct.
  
  A variable which bidnding a value of one struct is recongized as variable
  not a struct.
  """
  def is_struct?({:%, _, _}), do: true
  def is_struct?(_ast), do: false

  @doc """
  Check if the ast is a pin expression.
  """
  def is_pin?({:^, _, _}), do: true
  def is_pin?(_ast), do: false

  @doc """
  Get the keys in the ast of the map.
  """
  def map_keys({:%{}, _meta, key_value}) do
    key_value |> Enum.map(&elem(&1, 0))
  end

  def map_values({:%{}, _meta, key_values}) do
    key_values |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Make a map for the give `keys` and `values`.
  """
  def make_map(keys, values) do
    {:%{}, [], Enum.zip(keys, values)}
  end

  @doc """
  Get the real arguments after return from `Macro.decompose_call/1`.
  """
  def get_args([{:when, _, args}]) do
    {_, args} = List.pop_at(args, -1)
    args
  end

  def get_args(ast) when is_list(ast), do: ast

  @doc """
  Check if the clauses have the same arity.
  
  If all caluses have some arity, return `{:ok, arity}`,
  else return `:error`.
  """
  def clauses_arity_check([{:->, _, [args | _]} | others]) do
    args = get_args(args)
    check_args_length(others, length(args))
  end

  defp check_args_length([], len) do
    {:ok, len}
  end

  defp check_args_length([{:->, _, [args | _]} | others], len) do
    args = get_args(args)

    if len == length(args) do
      check_args_length(others, len)
    else
      :error
    end
  end

  @doc false
  def make_recursive_fn(name, body, correct_args_fun) do
    new_body = Enum.map(body, &clause_handler(correct_args_fun, name, &1))
    {:fn, [], new_body}
  end

  defp clause_handler(
         correct_args_fun,
         name_ast = {atom, _, _},
         {:->, meta, [args | body]}
       ) do
    new_body = Macro.postwalk(body, &correct_recursive_call(atom, &1))

    new_args =
      if new_body != body do
        correct_args_fun.(args, name_ast)
      else
        name_atom = "_#{atom}" |> String.to_atom()
        correct_args_fun.(args, {name_atom, [], nil})
      end

    {:->, meta, [new_args | new_body]}
  end

  # ast of `atom.(...args)` -> ast of `atom.(atom, ...args)`.
  defp correct_recursive_call(atom, {{:., m1, [{atom, _, _} = fun]}, m2, args}) do
    {{:., m1, [fun]}, m2, [fun | args]}
  end

  defp correct_recursive_call(_, ast), do: ast
end
