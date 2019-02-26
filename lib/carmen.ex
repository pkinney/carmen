defmodule Carmen do
  @moduledoc false
  use Application

  @interface Application.get_env(:carmen, :interface, Carmen.InterfaceExample)
  @default_opts %{pool_opts: [{-180, 180, 0.001}, {-90, 90, 0.001}]}

  def start(type, opts \\ @default_opts)
  def start(type, opts) when not is_map(opts), do: start(type, @default_opts)

  def start(_type, opts) do
    opts = Map.merge(@default_opts, opts)

    children = [
      {Registry, [keys: :unique, name: Carmen.Registry]},
      {Carmen.Zone.Pool, opts.pool_opts},
      {Carmen.Object.Supervisor, nil},
      Supervisor.child_spec({Task, &load_zones/0}, %{restart: :transient})
    ]

    opts = [strategy: :one_for_one, name: Carmen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp load_zones() do
    :ok = apply(@interface, :load_zones, [])
  end
end
