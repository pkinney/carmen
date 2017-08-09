defmodule Carmen.Zone.Store do
  use Supervisor
  alias :mnesia, as: Mnesia

  @pool_name :zone_worker_pool
  @pool_size 2
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

  def put_zone(shape), do: put_zone(UUID.uuid4(), shape)
  def put_zone(id, shape) do
    :poolboy.transaction(
      @pool_name,
      fn(pid) -> GenServer.call(pid, {:put_zone, id, shape}) end,
      :infinity
    )
  end

  def get_zone(id) do
    :poolboy.transaction(
      @pool_name,
      fn(pid) -> GenServer.call(pid, {:get_zone, id}) end,
      :infinity
    )
  end

  def intersections(shape) do
    :poolboy.transaction(
      @pool_name,
      fn(pid) -> GenServer.call(pid, {:intersections, shape}) end,
      :infinity
    )
  end
end