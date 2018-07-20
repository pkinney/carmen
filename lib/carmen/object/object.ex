defmodule Carmen.Object do
  @interface Application.get_env(:carmen, :interface, Carmen.Example.Interface)

  def update(id, shape), do: update(id, shape, :omitted)
  def update(id, shape, meta), do: safe_call(id, {:update, id, shape, meta})

  def put_state(id, state), do: safe_call(id, {:put_state, id, state})

  def get_shape(id), do: safe_call(id, :get_shape)

  def get_meta(id), do: safe_call(id, :get_meta)

  def intersecting?(id, zone_id), do: safe_call(id, {:intersecting?, zone_id})

  defp safe_call(id, msg) do
    pid =
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

    # since processes shut themselves down we run a risk of making a call at the instant
    # it exits :normal, by try/catching here we can handle this common edge case to prevent
    # needlessly crashing a calling process which is likely a busy parsing or message queue client
    try do
      GenStateMachine.call(pid, msg)
    catch
      :exit, {reason, _} when reason in [:noproc, :normal] ->
        safe_call(id, msg)
    end
  end
end
