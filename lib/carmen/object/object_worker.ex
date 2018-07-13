defmodule Carmen.Object.Worker do
  use GenServer

  ##############################
  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  ##############################
  # Server Callbacks

  def init(_opts) do
    # TODO: load state from store
    {:ok, {nil, []}}
  end

  def handle_call({:update, shape}, _from, {_, inters}) do
    new_inters = Carmen.Zone.Store.intersections(shape)
    #TODO: if changed, update Mnesia
    {:reply, {new_inters -- inters, inters -- new_inters}, {shape, new_inters}}
  end

  def handle_call({:intersecting?, zone_id}, _from, {shape, inters}) do
    {:reply, Enum.member?(inters, zone_id), {shape, inters}}
  end

  # called when a handoff has been initiated due to changes
  # in cluster topology, valid response values are:
  #
  #   - `:restart`, to simply restart the process on the new node
  #   - `{:resume, state}`, to hand off some state to the new process
  #   - `:ignore`, to leave the process running on it's current node
  #
  def handle_call({:swarm, :begin_handoff}, _from, {name, delay}) do
    {:reply, {:resume, delay}, {name, delay}}
  end

  # called after the process has been restarted on it's new node,
  # and the old process's state is being handed off. This is only
  # sent if the return to `begin_handoff` was `{:resume, state}`.
  # **NOTE**: This is called *after* the process is successfully started,
  # so make sure to design your processes around this caveat if you
  # wish to hand off state like this.
  def handle_cast({:swarm, :end_handoff, delay}, {name, _}) do
    {:noreply, {name, delay}}
  end

  # called when a network split is healed and the local process
  # should continue running, but a duplicate process on the other
  # side of the split is handing off it's state to us. You can choose
  # to ignore the handoff state, or apply your own conflict resolution
  # strategy
  def handle_cast({:swarm, :resolve_conflict, _delay}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, {name, delay}) do
    IO.puts "#{inspect name} says hi!"
    Process.send_after(self(), :timeout, delay)
    {:noreply, {name, delay}}
  end
  # this message is sent when this process should die
  # because it's being moved, use this as an opportunity
  # to clean up
  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end
end
