defmodule Carmen.Object do

  @interface Application.get_env(:carmen, :interface, Carmen.Example.Interface)

  def update(id, shape) do
    id
    |> @interface.lookup()
    |> case do
      :undefined ->
        @interface.register(id)
      pid ->
        {:ok, pid}
    end
    |> case do
      {:ok, pid} -> pid
      {:error, {:already_registered, pid}} -> pid
    end
    |> GenServer.call({:update, id, shape})
  end

  def intersecting?(id, zone_id) do
    id
    |> @interface.lookup()
    |> case do
      :undefined ->
        false
      pid ->
        GenServer.call(pid, {:intersecting?, zone_id})
    end
  end
end
