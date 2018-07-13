defmodule Carmen.Object do
  def update(id, shape) do
    name = via_tuple(id)

    pid =
      name
      |> Swarm.whereis_name()
      |> case do
        :undefined ->
          Swarm.register_name(name, Carmen.Object.Supervisor, :register, [id])
        pid ->
          {:ok, pid}
      end
      |> case do
        {:ok, pid} -> pid
        {:error, {:already_registered, pid}} -> pid
      end

    GenServer.call(pid, {:update, id, shape})
  end

  def intersecting?(id, zone_id) do
    id
    |> via_tuple()
    |> Swarm.whereis_name()
    |> case do
      :undefined ->
        false
      pid ->
        GenServer.call(pid, {:intersecting?, zone_id})
    end
  end

  def via_tuple(id) do
    {:via, :swarm, {:carmen, id}}
  end
end
