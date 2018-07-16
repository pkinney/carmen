defmodule Carmen.Example.Interface do
  require Logger

  @behaviour Carmen.Interface

  def start_storage() do
    # :mnesia.create_schema([node()])
    :mnesia.start()

    :ok
  end

  def load_zones() do
    features =
      Path.join([ "bench", "shapes", "blocks_nyc.json" ])
      |> File.read!
      |> Poison.decode!
      |> Map.fetch!("features")
      |> Enum.map(&(&1["geometry"]))
      |> Enum.map(&Geo.JSON.decode/1)

    IO.puts("Adding #{length(features)} features...")

    features
  end

  def object_state(id) do
    Logger.debug(fn -> "attempting to load previous state from long term storage for object #{id}" end)
    {_shape = %Geo.Point{}, _inters = [], _meta = %{id: id}}
  end

  def objects_state() do
    Logger.debug(fn -> "attempting to load previous states for all objects" end)
    []
  end

  def enter(id, zone_id, meta) do
    Logger.debug(fn -> "enter event emitted for object #{id} and zone #{zone_id} with meta #{meta}" end)
  end

  def exit(id, zone_id, meta) do
    Logger.debug(fn -> "exit event emitted for object #{id} and zone #{zone_id} with meta #{meta}" end)
  end

  def lookup(id) do
    # Swarm.whereis_name({:via, :swarm, {:carmen, id}})
    case Registry.lookup(Carmen.Registry, id) do
      [{pid, _}] -> pid
      _ -> :undefined
    end
  end

  def register(id) do
    # Swarm.register_name({:via, :swarm, {:carmen, id}}, Carmen.Object.Supervisor, :register, [id])
    Carmen.Object.Supervisor.register(id, [name: {:via, Registry, {Carmen.Registry, id}}])
  end

  def handle_msg(:call, {:swarm, :begin_handoff}, _from, {name, delay}), do: {:reply, {:resume, delay}, {name, delay}}
  def handle_msg(:cast, {:swarm, :end_handoff, delay}, {name, _}), do: {:noreply, {name, delay}}
  def handle_msg(:cast, {:swarm, :resolve_conflict, _delay}, state), do: {:noreply, state}
  def handle_msg(:info, {:swarm, :die}, state), do: {:stop, :shutdown, state}
end
