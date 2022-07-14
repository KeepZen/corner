defmodule Corner.MixProject do
  use Mix.Project

  def project do
    [
      app: :corner,
      version: "0.1.3",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Enhance of Elixir, make code more clean.",
      package: package(),
      docs: [
        # The main page in the docs
        # main: "MyApp",
        # logo: "path/to/logo.png",
        # extras: [
        #   "../ch01.intruction.md",
        #   "../ch02.plus_and_minus.md",
        #   "../ch03.pattern_match.md",
        #   "../ch04.parenthese.md",
        #   "../ch05.new_constructor.md",
        #   "../ch06.async_programe.md",
        #   "../ch07.pipe.md",
        #   "../ch08.error_handle.md",
        #   "../ch09.module.md",
        #   "../ch10.protocol_and_behaviour.md",
        #   "../ch11.macro.md",
        #   "../ch12.cold_knowledge.md"
        # ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/KeepZen/corner.git"}
    ]
  end
end
