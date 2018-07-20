defmodule Carmen.Zone.Store do
  @pool_name :zone_worker_pool

  def put_zone(shape), do: put_zone(UUID.uuid4(), shape)

  def put_zone(id, shape) do
    :poolboy.transaction(
      @pool_name,
      fn pid -> GenServer.call(pid, {:put_zone, id, shape}) end,
      :infinity
    )
  end

  def get_zone(id) do
    :poolboy.transaction(
      @pool_name,
      fn pid -> GenServer.call(pid, {:get_zone, id}) end,
      :infinity
    )
  end

  def intersections(shape) do
    :poolboy.transaction(
      @pool_name,
      fn pid -> GenServer.call(pid, {:intersections, shape}) end,
      :infinity
    )
  end
end
