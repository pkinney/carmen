defmodule Carmen.Example.Interface do
  require Logger

  @behaviour Carmen.Interface

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
    {shape = nil, inters = []}
  end

  def objects_state() do
    Logger.debug(fn -> "attempting to load previous states for all objects" end)
    [object_state(nil)]
  end

  def enter(id, zone_id) do
    Logger.debug(fn -> "enter event emitted for object #{id} and zone #{zone_id}" end)
  end

  def exit(id, zone_id) do
    Logger.debug(fn -> "exit event emitted for object #{id} and zone #{zone_id}" end)
  end
end
