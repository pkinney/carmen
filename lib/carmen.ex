defmodule Carmen do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Carmen.Redis.Pool, [[host: "localhost", port: 6379]]),
      supervisor(Carmen.Zone.Store, [[{-180, 180, 0.001}, {-90, 90, 0.001}]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Carmen.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
