defmodule Mix.Tasks.Carmen.Demo do
  use Mix.Task

  def run([objects]) do
    Application.ensure_all_started(:carmen)
    Carmen.Demo.do_all(String.to_integer(objects))
  end
  def run(_), do: Mix.shell.error("Please provide an integer number of moving objects you wish to demo")
end

defmodule Carmen.Demo do
  def do_all(num_objects) do
    clear_all()
    env = load()

    Meter.start_link()

    run(env, num_objects)
  end

  def load() do
    features =
      Path.join([ "bench", "shapes", "blocks_nyc.json" ])
      |> File.read!
      |> Poison.decode!
      |> Map.fetch!("features")
      |> Enum.map(&(&1["geometry"]))
      |> Enum.map(&Geo.JSON.decode/1)

    IO.puts("Adding #{length(features)} features...")

    Enum.map(features, &Carmen.Zone.Store.put_zone(&1))

    IO.puts("Features added.")

    env =
      features
      |> Enum.reduce(Envelope.empty(), fn shape, acc ->
        Envelope.expand(acc, Envelope.from_geo(shape))
      end)

    IO.puts("Envelope Calculated: #{inspect env}")
    env
  end

  def random_point(env) do
    %Geo.Point{coordinates: { random_between(env.max_x, env.min_x),
      random_between(env.max_y, env.min_y) }}
  end

  def run(env, num_objects) do
    objects = Enum.map(1..num_objects, fn _ -> UUID.uuid4() end)

    objects
    |> Enum.map(fn object ->
        Task.async(fn ->
          :timer.sleep(:rand.uniform(1000) + 1)
          %{coordinates: {x0, y0}} = random_point(env)
          %{coordinates: {x1, y1}} = random_point(env)
          steps = 300

          d_x = 0.0001 * (x1 - x0) / abs(x1 - x0) # ~10m/s
          d_y = 0.0001 * (y1 - y0) / abs(y1 - y0)

          Enum.map(1..steps, fn i ->
            GenServer.cast(:meter, {:tap, :in})
            Task.async(fn ->
              point = %Geo.Point{coordinates: {x0 + i * d_x, y0 + i * d_y}}
              {time, {entered, left}} = :timer.tc(fn -> Carmen.Object.update(object, point) end)

              case entered do
                [] -> nil
                _ -> GenServer.cast(:meter, {:tap, :enter})
              end

              case left do
                [] -> nil
                _ -> GenServer.cast(:meter, {:tap, :leave})
              end
              GenServer.cast(:meter, {:tap, :out})
              GenServer.cast(:meter, {:measure, time})
            end)

            # sleep_time = Enum.max([1000 - time/1000, 1]) |> round
            # :timer.sleep(sleep_time)
            :timer.sleep(1000)
          end)
        end)
      end)
    |> Enum.map(&(Task.await(&1, :infinity)))

    :ok
  end

  defp random_between(a, b) when a > b, do: :rand.uniform() * (a - b) + b
  defp random_between(a, b), do: :rand.uniform() * (b - a) + a

  def clear_all() do
    [Zone, ZoneEnv, MapCell] |>
      Enum.map(&:mnesia.clear_table/1)
  end
end

defmodule Meter do
  use GenServer

  @interval 1000

  ##############################
  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: :meter)
  end

  ##############################
  # Server Callbacks

  def init(_opts) do
    Process.send_after(self(), :print_stats, @interval)
    {:ok, %{
      in: [0],
      out: [0],
      enter: [0],
      leave: [0],
      proc_time: []
    }}
  end

  def handle_cast({:tap, field}, state) do
    [cur | rest] = state[field]
    {:noreply, state |> Map.put(field, [cur + 1 | rest])}
  end

  def handle_cast({:measure, time}, %{proc_time: times} = state) do
    new_times =  [time] ++ Enum.take(times, 9)
    {:noreply, state |> Map.put(:proc_time, new_times)}
  end

  def handle_info(:print_stats, state) do
    in_rate = state.in |> calc_average
    out_rate = state.out |> calc_average
    enter_rate = state.enter |> calc_average
    leave_rate = state.leave |> calc_average
    ave_time = state.proc_time |> calc_average

    IO.puts("In: #{in_rate}/s | Out: #{out_rate}/s | Time: #{ave_time}us -> Enter: #{enter_rate}/s | Leave: #{leave_rate}/s")
    Process.send_after(self(), :print_stats, @interval)

    new_in = [0] ++ state.in |> Enum.take(3)
    new_out = [0] ++ state.out |> Enum.take(3)
    new_enter = [0] ++ state.enter |> Enum.take(3)
    new_leave = [0] ++ state.leave |> Enum.take(3)

    {:noreply, %{in: new_in, out: new_out, enter: new_enter, leave: new_leave, proc_time: state.proc_time}}
  end

  defp calc_average([]), do: 0
  defp calc_average(values), do: Enum.sum(values) * 1.0 / length(values) |> round
end
