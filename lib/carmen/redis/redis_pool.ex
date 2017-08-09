defmodule Carmen.Redis.Pool do
  use Supervisor

  @pool_name :redis_pool
  @pool_size 2
  @pool_max_overflow 0

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    pool_opts = [
      name: {:local, @pool_name},
      worker_module: Carmen.Redis.Worker,
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

  def command(command) do
    :poolboy.transaction(
      @pool_name,
      fn(pid) -> GenServer.call(pid, {:command, command}) end,
      :infinity
    )
  end

  def pipeline(commands) do
    :poolboy.transaction(
      @pool_name,
      fn(pid) -> GenServer.call(pid, {:pipeline, commands}) end,
      :infinity
    )
  end
end