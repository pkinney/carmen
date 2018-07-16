defmodule Carmen do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: Carmen.Registry]},
      {Carmen.Zone.Pool, [{-180, 180, 0.001}, {-90, 90, 0.001}]},
      {Carmen.Object.Supervisor, nil}
    ]

    opts = [strategy: :one_for_one, name: Carmen.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
