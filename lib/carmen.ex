defmodule Carmen do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Carmen.Redis.Pool, [[host: "localhost", port: 6379]]),
      supervisor(Carmen.Zone.Pool, [[{-180, 180, 0.001}, {-90, 90, 0.001}]]),
      supervisor(Carmen.Object.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Carmen.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
