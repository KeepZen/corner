defmodule Corner.Tuple do
  @moduledoc """
  `Tuple` enhance module.
  """
  @padding_opt [value: nil, at: :tail]

  @doc """
  Padding `number` of `nil` or `value` to head or tail of the tuple `t`.
  ## Example
  ```
  iex> alias Corner.Tuple, as: T
  iex> T.padding({}, 2)
  iex> {nil,nil}
  iex> T.padding({:a}, 1, value: 1)
  iex> {:a, 1}
  iex> T.padding({:b}, 1,value: 1, at: :head)
  iex> {1,:b}
  iex> T.padding({:c}, 2, value: :e, at: :tail)
  iex> {:c, :e,:e}
  ```
  """
  def padding(t, number, opt \\ [])

  def padding(t, n, opt) do
    @padding_opt
    |> Enum.map(fn {key, value} -> {key, Keyword.get(opt, key, value)} end)
    |> then(&do_padding(t, n, &1))
  end

  defp do_padding(t, 0, _), do: t

  defp do_padding(t, n, [value: v, at: :tail] = opt)
       when is_tuple(t) and n > 0 do
    do_padding(Tuple.append(t, v), n - 1, opt)
  end

  defp do_padding(t, n, [value: v, at: :head] = opt)
       when is_tuple(t) and n > 0 do
    do_padding(Tuple.insert_at(t, 0, v), n - 1, opt)
  end

  @doc """
  Drop `number` of elements from `tuple`.
  
  Default value of the `:at` option is `:tail`, mean drop elements from tail,
  set it to `:head`, drop elementes from head.
  
  ## Example
  ```
  iex> alias Corner.Tuple,as: T
  iex> T.drop({:droped, :other}, 1, at: :head)
  iex> {:other}
  iex> T.drop({:keep, :droped, :deopred_also}, 2)
  ```
  """
  def drop(tuple, number, at_option \\ [at: :tail])
  def drop(t, 0, _at), do: t

  def drop(t, n, [at: :tail] = opt) when n > 0 and tuple_size(t) >= n do
    Tuple.delete_at(t, tuple_size(t) - 1)
    |> drop(n - 1, opt)
  end

  def drop(t, n, [at: :head] = opt) when n > 0 and tuple_size(t) >= n do
    Tuple.delete_at(t, 0)
    |> drop(n - 1, opt)
  end
end
