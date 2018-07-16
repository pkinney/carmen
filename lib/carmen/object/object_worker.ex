defmodule Carmen.Object.Worker do
  use GenServer

  @interface Application.get_env(:carmen, :interface, Carmen.Example.Interface)

  def start_link({id, opts}) do
    GenServer.start_link(__MODULE__, id, opts)
  end

  def init(id) do
    Process.send(self(), {:initialize, id}, [])
    {:ok, nil}
  end

  def handle_info({:initialize, id}, _state) do
    {_shape, _inters, _meta} = state = @interface.object_state(id)
    {:noreply, state}
  end

  def handle_info(msg, state), do: @interface.handle_msg(:info, msg, state)

  def handle_call({:update, id, shape}, _from, {_, inters, meta}) do
    new_inters = Carmen.Zone.Store.intersections(shape)

    enters = new_inters -- inters
    exits = inters -- new_inters

    Enum.each(enters, &(:ok = @interface.enter(id, &1, meta)))
    Enum.each(exits, &(:ok = @interface.exit(id, &1, meta)))

    {:reply, {enters, exits}, {shape, new_inters, meta}}
  end

  def handle_call({:intersecting?, zone_id}, _from, {_shape, inters, _meta} = state) do
    {:reply, Enum.member?(inters, zone_id), state}
  end

  def handle_call(msg, state), do: @interface.handle_msg(:call, msg, state)
  def handle_cast(msg, state), do: @interface.handle_msg(:cast, msg, state)
end
