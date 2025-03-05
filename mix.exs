defmodule Pane.MixProject do
  use Mix.Project

  def project do
    [
      app: :pane,
      version: "0.1.6",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Escript configuration for executable
  defp escript do
    [
      main_module: Pane.CLI,
      name: :pane
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # For command-line argument parsing
      {:optimus, "~> 0.5"},
      # For YAML configuration parsing
      {:yaml_elixir, "~> 2.9"},
      # For dialyzer static analysis
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end
end
