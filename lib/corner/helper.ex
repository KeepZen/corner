defmodule Corner.Helpers do
  def tuple_padding(t, n) when is_tuple(t) and is_integer(n) do
    do_tuple_padding(t, n)
  end

  defp do_tuple_padding(tuple, 0), do: tuple

  defp do_tuple_padding(t, a) when a > 0 do
    fun = fn
      _f, tuple, 0 -> tuple
      f, tuple, n -> f.(f, Tuple.append(tuple, nil), n - 1)
    end

    fun.(fun, t, a)
  end

  defp do_tuple_padding(tuple, a) when a < 0 do
    index = tuple_size(tuple) + a

    for _ <- 1..-a, reduce: tuple do
      t -> Tuple.delete_at(t, index)
    end
  end
end
