defmodule Corner.Ast do
  import Kernel, except: [tuple_size: 1]

  def is_variable?({atom, _, _})
      when is_atom(atom) and atom not in [:%, :{}, :%{}, :^],
      do: true

  def is_variable?(_), do: false

  def is_composed_type?({atom, _, _}) when atom in [:%, :{}, :%{}], do: true

  def is_composed_type?(ast),
    do:
      is_list(ast) or
        (is_tuple(ast) and tuple_size(ast) < 3)

  def is_tuple?({:{}, _, _}), do: true
  def is_tuple?({_, _}), do: true
  def is_tuple?(_), do: false

  def is_regex?({atom, _, _}) when atom in [:sigil_r, :sigil_R], do: true
  def is_regex?(_), do: false

  def tuple_size({_, _}), do: 2

  def tuple_size(ast) do
    if is_tuple?(ast) do
      length(elem(ast, 2))
    else
      {:error, :not_tuple_ast}
    end
  end

  def tuple_to_list(ast) do
    if tuple_size(ast) == 2 do
      Tuple.to_list(ast)
    else
      elem(ast, 2)
    end
  end

  def list_to_tuple(ast) when is_list(ast) do
    {:{}, [], ast}
  end

  def map_keys({:%{}, _meta, key_value}) do
    key_value |> Enum.map(&elem(&1, 0))
  end

  def map_values({:%{}, _meta, key_values}) do
    key_values |> Enum.map(&elem(&1, 1))
  end

  def make_map(keys, values) do
    {:%{}, [], Enum.zip(keys, values)}
  end
end
