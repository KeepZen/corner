defmodule Corner.Module.Explorer do
  @moduledoc """
  Explore the module informations.
  """
  @doc """
  Get all functions in `module`.
  
  Include private functions.
  """
  def funs(module) do
    module.module_info(:functions)
    |> Enum.reject(&macro?/1)
  end

  @doc """
  Get all public functions in `module`.
  """
  def pub_funs(module) do
    module.module_info(:exports)
    |> Enum.reject(&macro?/1)
  end

  @doc """
  Get all private functions in `module`.
  """
  def priv_funs(module) do
    funs(module) -- pub_funs(module)
  end

  defp macro?({atom, _}) do
    "#{atom}" =~ ~r/MACRO-/
  end

  @doc """
  Get all macros defined in the `module`.
  """
  def macros(module) do
    module.module_info(:functions)
    |> Enum.filter(&macro?/1)
    |> Enum.map(&fun_2_macro/1)
  end

  @doc """
  Get all public macros in the `module`.
  """
  def pub_macros(module) do
    module.__info__(:macros)
  rescue
    _ -> []
  end

  @doc """
  Get all private macros in the `module`.
  """
  def priv_macros(module) do
    macros(module) -- pub_macros(module)
  end

  defp fun_2_macro({atom, arity}) do
    "MACRO-" <> name = "#{atom}"
    {String.to_atom(name), arity - 1}
  end

  for {name, doc} <- [md5: " information ", compile: " information "] do
    message = "Get #{name}#{doc} of the `module`."
    @doc message
    def unquote(name)(module) do
      module.module_info(unquote(name))
    end
  end

  @doc """
  Get persisted attributes in the `module`.
  """
  def attributes(module) do
    module.module_info(:attributes)
  end

  @doc """
  Get the name of the `module`.
  """
  def name(module) do
    module.module_info(:module)
  end
end
