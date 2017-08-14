defmodule Carmen.Object do
  def update(id, shape) do
    case Swarm.whereis_name(id) do
      :undefined -> Swarm.register_name(id, Carmen.Object.Supervisor, :register, [id])
      _ -> nil
    end
    GenServer.call({:via, :swarm, id}, {:update, shape})
  end

  def intersecting?(id, zone_id) do
    case Swarm.whereis_name(id) do
      :undefined -> false
      _ -> GenServer.call({:via, :swarm, id}, {:intersecting?, zone_id})
    end
  end
end