defmodule Gltest.MixProject do
  use Mix.Project

  def project do
    [
      app: :gltest,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx],
      mod: {Gltest.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:image, "~> 0.37"},
      {:graphmath, "~> 2.0"}
    ]
  end
end
