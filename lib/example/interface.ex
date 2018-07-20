defmodule Carmen.Example.Interface do
  require Logger

  @behaviour Carmen.Interface

  @die_after_ms if Mix.env() == :test, do: 500, else: 60_000

  def sync_after_ms, do: 10
  def sync_after_count, do: 2
  def die_after_ms, do: @die_after_ms

  def start_storage() do
    # :mnesia.create_schema([node()])
    :mnesia.start()

    # used for tests
    :ets.new(:carmen_tests, [:named_table, :public])

    :ok
  end

  def load_zones() do
    :ok
  end

  def load_object_state(name) do
    Logger.debug(fn -> "attempting to load previous state from long term storage for object #{name}" end)
    # to make it easy to test we have a static id "missing" that won't return anything
    unless name == "missing" do
      {_shape = %Geo.Point{}, _inters = [], _meta = %{name: name}}
    end
  end

  def save_object_state(name, shape, intersecting_zones, meta) do
    Logger.debug(fn -> "attempting to save state to long term storage for object #{name}" end)
    :ets.insert(:carmen_tests, {name, shape, intersecting_zones, meta})
    :ok
  end

  def valid?(_new_meta, _old_meta) do
    true
  end

  # events that are emitted each time the object moves, there will only be one
  # except in the case of an object entering or leaving multiple zones at once
  def events(id, shape, enters, exits, :omitted, meta), do: events(id, shape, enters, exits, meta)
  def events(id, shape, enters, exits, new_meta, meta), do: events(id, shape, enters, exits, Map.merge(meta, new_meta))

  def events(id, _triggering_shape, enters, exits, meta) do
    Enum.each(enters, fn zone_id ->
      Logger.debug(fn -> "enter event emitted for object #{id} and zone #{zone_id} with meta #{meta}" end)
    end)

    Enum.each(exits, fn zone_id ->
      Logger.debug(fn -> "exit event emitted for object #{id} and zone #{zone_id} with meta #{meta}" end)
    end)

    {:ok, meta}
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
    Carmen.Object.Supervisor.register(id, name: {:via, Registry, {Carmen.Registry, id}})
  end

  def handle_msg({:call, _from}, {:swarm, :begin_handoff}, {name, delay}), do: {:reply, {:resume, delay}, {name, delay}}
  def handle_msg(:cast, {:swarm, :end_handoff, delay}, {name, _}), do: {:noreply, {name, delay}}
  def handle_msg(:cast, {:swarm, :resolve_conflict, _delay}, state), do: {:noreply, state}
  def handle_msg(:info, {:swarm, :die}, state), do: {:stop, :shutdown, state}
end
