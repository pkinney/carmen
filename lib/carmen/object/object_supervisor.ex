defmodule Carmen.Object.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      worker(Carmen.Object.Worker, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one, name: __MODULE__)
  end

  def register(id, opts \\ nil) do
    Supervisor.start_child(__MODULE__, [{id, opts}])
  end
end
