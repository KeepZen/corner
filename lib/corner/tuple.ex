defmodule Corner.Tuple do
  @padding_opt [value: nil, at: :tail]
  def padding(t, number, opt \\ [])
  def padding(t, n, opt), do: do_padding(t, n, Keyword.merge(@padding_opt, opt))
  defp do_padding(t, 0, _), do: t

  defp do_padding(t, n, [value: v, at: :tail] = opt)
       when is_tuple(t) and n > 0 do
    do_padding(Tuple.append(t, v), n - 1, opt)
  end

  defp do_padding(t, n, [value: v, at: :head] = opt)
       when is_tuple(t) and n > 0 do
    do_padding(Tuple.insert_at(t, 0, v), n - 1, opt)
  end

  def drop(t, 0, _at), do: t

  def drop(t, n, [at: :tail] = opt) when n > 0 and tuple_size(t) >= n do
    Tuple.delete_at(t, tuple_size(t) - 1)
    |> drop(n - 1, opt)
  end

  def drop(t, n, [at: :head] = opt) when n > 0 and tuple_size(t) >= n do
    Tuple.delete_at(t, 0)
    |> drop(n + 1, opt)
  end
end
