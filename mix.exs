defmodule Carmen.Mixfile do
  use Mix.Project

  def project do
    [
      app: :carmen,
      version: "0.1.0",
      elixir: "~> 1.5",
      description: description(),
      package: package(),
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Carmen, []},
      extra_applications: [
        :logger,
        :poolboy,
        :geo,
        :uuid,
        :topo]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:geo, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:topo, "~> 0.1.2"},
      {:spatial_hash, "~> 0.1.2"},
      {:swarm, "~> 3.0"},
      {:benchfella, "~> 0.3.5", only: :dev},
      {:poison, "~> 2.0", only: [:test, :dev]}
    ]
  end

  defp description do
    """
    TODO
    """
  end

  defp package do
    [
      files: ["lib/carmen.ex", "lib/carmen", "mix.exs", "README*"],
      maintainers: ["Powell Kinney"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pkinney/topo"}
    ]
  end
end
