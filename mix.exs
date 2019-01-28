defmodule Carmen.Mixfile do
  use Mix.Project

  def project do
    [
      app: :carmen,
      version: "0.1.4",
      elixir: "~> 1.5",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Carmen, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:geo, "~> 1.0"},
      {:gen_state_machine, "~> 2.0"},
      {:poolboy, "~> 1.5"},
      {:spatial_hash, "~> 0.1.2"},
      {:topo, "~> 0.1.2"},
      {:uuid, "~> 1.1"},
      {:benchfella, "~> 0.3.5", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:poison, "~> 2.0", only: [:test, :dev]}
    ]
  end

  defp description do
    """
    A clustered, streaming database for location events
    """
  end

  defp package do
    [
      files: ["lib/carmen.ex", "lib/carmen", "mix.exs", "README*"],
      maintainers: ["Powell Kinney"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pkinney/carmen"}
    ]
  end
end
