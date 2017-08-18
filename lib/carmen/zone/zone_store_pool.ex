defmodule Carmen.Zone.Pool do
  use Supervisor
  alias :mnesia, as: Mnesia

  @pool_name :zone_worker_pool
  @pool_size 100
  @pool_max_overflow 0

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Mnesia.create_schema([node()])
    Mnesia.start()

    Mnesia.create_table(Zone, [attributes: [:id, :shape]])
    Mnesia.create_table(ZoneEnv, [attributes: [:id, :envelope]])
    Mnesia.create_table(MapCell, [attributes: [:hash, :objects]])

    pool_opts = [
      name: {:local, @pool_name},
      worker_module: Carmen.Zone.Worker,
      size: @pool_size,
      max_overflow: @pool_max_overflow
    ]

    children = [
      :poolboy.child_spec(
        @pool_name,
        pool_opts,
        opts
      )
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end
end