defmodule Glory.MixProject do
  use Mix.Project

  def project do
    [
      app: :glory,
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
      mod: {Glory.Application, []}
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
