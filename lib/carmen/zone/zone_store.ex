defmodule Carmen.Zone.Store do
  @pool_name :zone_worker_pool

  @doc false
  def put_zone(shape), do: put_zone(UUID.uuid4(), shape)

  def put_zone(id, shape, meta \\ nil) do
    :poolboy.transaction(
      @pool_name,
      fn pid -> GenServer.call(pid, {:put_zone, id, shape, meta}, 30_000) end,
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

  def get_meta(id) do
    case :mnesia.dirty_read({Zone, id}) do
      [{Zone, ^id, _shape, meta}] -> meta
      [] -> nil
    end
  end

  def intersections(shape) do
    :poolboy.transaction(
      @pool_name,
      fn pid -> GenServer.call(pid, {:intersections, shape}) end,
      :infinity
    )
  end

  def cell_count_estimate(shape) do
    :poolboy.transaction(
      @pool_name,
      fn pid -> GenServer.call(pid, {:cell_count, shape}) end,
      :infinity
    )
  end
end
