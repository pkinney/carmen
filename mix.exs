defmodule Carmen.Mixfile do
  use Mix.Project

  def project do
    [
      app: :carmen,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Carmen, []},
      extra_applications: [:logger, :poolboy, :redix]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:redix, "~> 0.6"},
      {:geo, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:topo, "~> 0.1.2"},
      {:envelope, "~> 0.4", override: true},
      {:spatial_hash, "~> 0.1.2"}
    ]
  end
end
