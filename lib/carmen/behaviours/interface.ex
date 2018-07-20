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

  @callback sync_after_ms() :: non_neg_integer()
  @callback sync_after_count() :: non_neg_integer() | :every
  @callback die_after_ms() :: non_neg_integer()
  @callback start_storage() :: :ok

  @callback load_zones() :: [{id(), closed_geo()}]
  @callback load_object_state(object_id :: id()) :: state()
  @callback save_object_state(id(), geo(), [id()], term()) :: :ok | :error

  @callback valid?(new_meta :: term(), meta :: term()) :: boolean()
  @callback events(
              object_id :: id(),
              triggering_shape :: geo(),
              [enters :: id()],
              [exits :: id()],
              new_meta :: term(),
              meta :: term()
            ) :: {:ok, term()}

  @callback lookup(object_id :: id()) :: pid() | :undefined
  @callback register(object_id :: id()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  @callback handle_msg({:call, from :: reference()} | :cast | :info, message :: term(), state :: term()) :: term()
end
