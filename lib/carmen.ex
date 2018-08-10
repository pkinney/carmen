defmodule Carmen do
  @moduledoc false
  use Application

  @interface Application.get_env(:carmen, :interface, Carmen.InterfaceExample)

  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: Carmen.Registry]},
      {Carmen.Zone.Pool, [{-180, 180, 0.001}, {-90, 90, 0.001}]},
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
