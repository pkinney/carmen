defmodule Carmen.Interface do

  @callback load_zones() :: List.t
  @callback object_state(arg :: any) :: Map.t
  @callback objects_state() :: List.t
  @callback enter(arg :: any, arg :: any) :: any
  @callback exit(arg :: any, arg :: any) :: any

end
