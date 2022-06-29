defmodule Corner.Module.Explore do
  def funs(m) do
    m.module_info(:functions)
    |> Enum.reject(&macro?/1)
  end

  def pub_funs(m) do
    m.module_info(:exports)
    |> Enum.reject(&macro?/1)
  end

  def priv_funs(m) do
    funs(m) -- pub_funs(m)
  end

  defp macro?({atom, _}) do
    "#{atom}" =~ ~r/MACRO-/
  end

  def macros(m) do
    m.module_info(:functions)
    |> Enum.filter(&macro?/1)
    |> Enum.map(&fun_2_macro/1)
  end

  def pub_macros(m) do
    m.__info__(:macros)
  rescue
    _ -> []
  end

  def priv_macros(m) do
    macros(m) -- pub_macros(m)
  end

  defp fun_2_macro({atom, arity}) do
    "MACRO-" <> name = "#{atom}"
    {String.to_atom(name), arity - 1}
  end

  for name <- [:md5, :compile, :attributes, :module] do
    def unquote(name)(m) do
      m.module_info(unquote(name))
    end
  end
end
