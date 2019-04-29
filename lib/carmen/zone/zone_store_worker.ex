defmodule Carmen.Zone.Worker do
  @moduledoc false
  use GenServer
  alias :mnesia, as: Mnesia

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_call({:put_zone, id, shape, meta}, _from, grid) do
    {:atomic, _} =
      Mnesia.transaction(fn ->
        case get_zone_by_id(id) do
          nil -> nil
          old_shape -> delete_shape_from_grid(id, old_shape, grid)
        end

        Mnesia.write({Zone, id, shape, meta})
        Mnesia.write({ZoneEnv, id, Envelope.from_geo(shape)})
        add_shape_to_grid(id, shape, grid)
      end)

    {:reply, id, grid}
  end

  def handle_call({:remove_zone, id}, _from, grid) do
    {:atomic, _} =
      Mnesia.transaction(fn ->
        case get_zone_by_id(id) do
          nil -> nil
          old_shape -> delete_shape_from_grid(id, old_shape, grid)
        end

        Mnesia.delete({Zone, id})
        Mnesia.delete({ZoneEnv, id})
      end)

    {:reply, :ok, grid}
  end

  def handle_call({:get_zone, id}, _from, grid) do
    case Mnesia.dirty_read({Zone, id}) do
      [{Zone, ^id, shape, _meta}] -> {:reply, shape, grid}
      [] -> {:reply, nil, grid}
    end
  end

  def handle_call({:intersections, shape}, _from, grid) do
    res =
      SpatialHash.hash_range(shape, grid)
      |> get_zone_ids_in_range
      |> filter_zones_by_envelope_check(shape)
      |> filter_zones_by_shape(shape)

    {:reply, res, grid}
  end

  def handle_call({:cell_count, shape}, _from, grid) do
    [x_range, y_range] = SpatialHash.hash_range(shape, grid)
    {:reply, Enum.count(x_range) * Enum.count(y_range), grid}
  end

  ##############################
  # Utility Functions

  defp add_shape_to_grid(id, shape, grid) do
    [x_range, y_range] = SpatialHash.hash_range(shape, grid)

    for x <- x_range do
      for y <- y_range do
        add_shape_to_cell(id, x, y)
      end
    end
  end

  defp add_shape_to_cell(id, x, y) do
    hash = cell_hash(x, y)

    case Mnesia.read({MapCell, hash}) do
      [{MapCell, _, objects}] ->
        Mnesia.write({MapCell, hash, objects ++ [id]})

      [] ->
        Mnesia.write({MapCell, hash, [id]})
    end
  end

  defp delete_shape_from_grid(id, shape, grid) do
    [x_range, y_range] = SpatialHash.hash_range(shape, grid)

    for x <- x_range do
      for y <- y_range do
        remove_shape_from_cell(id, x, y)
      end
    end
  end

  defp remove_shape_from_cell(id, x, y) do
    hash = cell_hash(x, y)

    case Mnesia.read({MapCell, hash}) do
      [{MapCell, _, objects}] ->
        Mnesia.write({MapCell, hash, objects -- [id]})

      [] ->
        nil
    end
  end

  defp get_zone_ids_in_range([x_range, y_range]) do
    Enum.reduce(x_range, [], fn x, acc1 ->
      column =
        Enum.reduce(y_range, [], fn y, acc2 ->
          (acc2 ++ get_shapes_in_cell(x, y))
          |> Enum.uniq()
        end)

      (acc1 ++ column) |> Enum.uniq()
    end)
  end

  defp get_shapes_in_cell(x, y) do
    case Mnesia.dirty_read({MapCell, cell_hash(x, y)}) do
      [{MapCell, _, objects}] -> objects
      [] -> []
    end
  end

  defp get_zone_by_id(id) do
    case Mnesia.dirty_read({Zone, id}) do
      [{Zone, _, zone, _meta}] -> zone
      [] -> nil
    end
  end

  defp get_zone_envelope_by_id(id) do
    case Mnesia.dirty_read({ZoneEnv, id}) do
      [{ZoneEnv, _, env}] -> env
      [] -> nil
    end
  end

  defp filter_zones_by_envelope_check(zones, shape) do
    env = Envelope.from_geo(shape)

    Enum.filter(zones, fn id ->
      case get_zone_envelope_by_id(id) do
        nil -> false
        zone_env -> Envelope.intersects?(zone_env, env)
      end
    end)
  end

  defp filter_zones_by_shape(zones, shape) do
    Enum.filter(zones, fn id ->
      case get_zone_by_id(id) do
        nil -> false
        zone -> Topo.intersects?(zone, shape)
      end
    end)
  end

  defp cell_hash(x, y), do: "#{x}-#{y}"
end
