defmodule Carmen.Object.Worker do
  use GenStateMachine

  @interface Application.get_env(:carmen, :interface, Carmen.Example.Interface)

  defmodule(Data, do: defstruct([:id, :shape, inters: [], meta: %{}, processed: 0]))

  def start_link({id, opts}) do
    GenStateMachine.start_link(__MODULE__, id, opts)
  end

  def init(id) do
    actions = [{:state_timeout, 10, :load_object_state}]
    {:ok, :starting, %Data{id: id}, actions}
  end

  def handle_event(:state_timeout, :load_object_state, :starting, %Data{id: id}) do
    case @interface.load_object_state(id) do
      {shape, inters, meta} ->
        {:next_state, :running, %Data{id: id, shape: shape, inters: inters, meta: meta}}

      _ ->
        {:next_state, :running, :not_found}
    end
  end

  def handle_event({:call, from}, {:put_state, {id, {shape, inters, meta}}}, _state, _data) do
    actions = [{:reply, from, :ok}]
    {:next_state, :running, %Data{id: id, shape: shape, inters: inters, meta: meta}, actions}
  end

  def handle_event({:call, _from}, _, :starting, _data) do
    {:keep_state_and_data, [:postpone]}
  end

  def handle_event(
        {:call, from},
        {:update, id, shape, new_meta},
        :running,
        %Data{inters: inters, meta: old_meta, processed: processed} = data
      ) do
    if (id && new_meta == :omitted) || (id && @interface.valid?(new_meta, old_meta)) do
      new_inters = Carmen.Zone.Store.intersections(shape)

      enters = new_inters -- inters
      exits = inters -- new_inters
      {:ok, meta} = @interface.events(id, shape, enters, exits, new_meta, old_meta)

      data = %Data{data | shape: shape, inters: new_inters, meta: meta, processed: processed + 1}

      cond do
        @interface.sync_after_count() == :every ->
          :ok = @interface.save_object_state(id, shape, inters, meta)

          actions = [
            {:reply, from, {enters, exits}},
            {:state_timeout, @interface.die_after_ms(), :shutdown},
          ]

          {:keep_state, data, actions}

        processed + 1 >= @interface.sync_after_count() ->
          actions = [
            {:reply, from, {enters, exits}},
            {:timeout, :infinity, :saving_object_state},
            {:next_event, :internal, :saving_object_state},
            {:state_timeout, @interface.die_after_ms(), :shutdown}
          ]

          {:keep_state, data, actions}

        true ->
          actions = [
            {:reply, from, {enters, exits}},
            {:state_timeout, @interface.die_after_ms(), :shutdown},
            {:timeout, @interface.sync_after_ms(), :saving_object_state}
          ]

          {:keep_state, data, actions}
      end
    else
      {:keep_state_and_data, [{:reply, from, :dropped}]}
    end
  end

  def handle_event({:call, from}, {:update, _, _, _}, :running, :not_found) do
    {:keep_state_and_data, [{:reply, from, :not_found}]}
  end

  def handle_event({:call, from}, {:intersecting?, zone_id}, _state, %Data{inters: inters}) do
    {:keep_state_and_data, [{:reply, from, Enum.member?(inters, zone_id)}]}
  end

  def handle_event({:call, from}, :get_meta, _state, %Data{meta: meta}) do
    {:keep_state_and_data, [{:reply, from, meta}]}
  end

  def handle_event({:call, from}, :get_shape, _state, %Data{shape: shape}) do
    {:keep_state_and_data, [{:reply, from, shape}]}
  end

  def handle_event(event, :saving_object_state, _state, %Data{id: id, shape: shape, inters: inters, meta: meta} = data)
      when event in [:internal, :timeout] do
    :ok = @interface.save_object_state(id, shape, inters, meta)
    {:next_state, :running, %{data | processed: 0}}
  end

  def handle_event(:state_timeout, :shutdown, _state, data) do
    shutdown(data)
  end

  # either I'm missing something obvious or there's a bug in gen_statem because timeouts should show
  # up as a gen_statem event and be caught by the function above but occasionally this :info shows up
  def handle_event(:info, {:timeout, _, :shutdown}, _state, data) do
    shutdown(data)
  end

  def handle_event(_, _, _, :not_found) do
    :keep_state_and_data
  end

  def handle_event({:call, from}, msg, _state, data), do: @interface.handle_msg({:call, from}, msg, data)
  def handle_event(:cast, msg, _state, data), do: @interface.handle_msg(:cast, msg, data)
  def handle_event(:info, msg, _state, data), do: @interface.handle_msg(:info, msg, data)

  defp shutdown(%Data{id: id, shape: shape, inters: inters, meta: meta}) do
    :ok = @interface.save_object_state(id, shape, inters, meta)
    :stop
  end
end
