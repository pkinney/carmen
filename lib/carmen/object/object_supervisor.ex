defmodule Carmen.Object.Supervisor do
  use Supervisor
  alias :mnesia, as: Mnesia

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Mnesia.create_schema([node()])
    Mnesia.start()

    Mnesia.create_table(Object, [attributes: [:id, :shape, :in_zones]])

    children = [
      worker(Carmen.Object.Worker, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one, name: __MODULE__)
  end

  def register(worker_name) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [worker_name])
  end
end