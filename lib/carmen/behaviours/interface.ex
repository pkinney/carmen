defmodule Carmen.Interface do

  @type id :: <<_::288>> | pos_integer()
  @type geo ::
    %Geo.Point{}
    | %Geo.MultiPoint{}
    | %Geo.LineString{}
    | %Geo.MultiLineString{}
    | %Geo.Polygon{}
    | %Geo.MultiPolygon{}
  @type closed_geo ::
    %Geo.Polygon{}
    | %Geo.MultiPolygon{}
  @type state :: {geo(), [id()], term()}


  @callback load_zones() :: [{id(), closed_geo()} | {id(), closed_geo()}]
  @callback object_state(object_id :: id()) :: state()
  @callback objects_state() :: [state()]

  @callback enter(object_id :: id(), zone_id :: id(), meta :: term()) :: :ok
  @callback exit(object_id :: id(), zone_id :: id(), meta :: term()) :: :ok

  @callback lookup(object_id :: id()) :: pid() | :undefined
  @callback register(object_id :: id()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  @callback handle_msg(:call | :cast | :info, message :: term(), state :: term()) :: term()

end
