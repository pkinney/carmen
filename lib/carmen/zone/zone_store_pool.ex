defmodule Carmen.Zone.Pool do
  use Supervisor

  @pool_name :zone_worker_pool
  @pool_size 200
  @pool_max_overflow 0
  @interface Application.get_env(:carmen, :interface, Carmen.Example.Interface)

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    :ok = @interface.start_storage()
    :mnesia.create_table(Zone, [attributes: [:id, :shape]])
    :mnesia.create_table(ZoneEnv, [attributes: [:id, :envelope]])
    :mnesia.create_table(MapCell, [attributes: [:hash, :objects]])

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
