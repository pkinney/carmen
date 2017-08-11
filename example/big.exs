defmodule BigMapExample do
  def do_all(num_vehicles) do
    Meter.start_link()

    clear_all()
    load()
    |> run(num_vehicles)
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

    features
    |> Enum.with_index
    |> Enum.map(fn {feature, i} ->
      Carmen.Zone.Store.put_zone(feature)
    end)

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

  def run(env, num_vehicles) do
    vehicles = Enum.map(0..num_vehicles, fn _ -> UUID.uuid4() end)

    vehicles
    |> Enum.map(fn vehicle ->
        Task.async(fn ->
          :timer.sleep(:rand.uniform(1000)+1)
          Enum.map(0..1000, fn _ ->
            GenServer.cast(:meter, {:tap, :in})
            {time, _} = :timer.tc(fn -> Carmen.Object.update(vehicle, random_point(env)) end)

            GenServer.cast(:meter, {:tap, :out})

            sleep_time = Enum.max([1000 - time/1000, 1]) |> round
            :timer.sleep(sleep_time)
          end)
        end)
      end)
    |> Enum.map(&(Task.await(&1, :infinity)))
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

  def init(opts) do
    Process.send_after(self, :print_stats, @interval)
    {:ok, %{
      in: {[0], 0},
      out: {[0], 0},
      proc_time: []
    }}
  end

  def handle_cast({:tap, field}, state) do
    {[cur | rest], last_time} = state[field]
    {d, s, _} = :os.timestamp()
    this_time = d*1000000+s
    new_field = case this_time do
      ^last_time ->
        {[cur + 1 | rest], last_time}
      _ ->
        {[1, cur | (rest |> Enum.take(10))], this_time}
    end
    {:noreply, state |> Map.put(field, new_field)}
  end

  def handle_info(:print_stats, state) do
    {[_ | recent_in], _} = state.in
    {[_ | recent_out], _} = state.out

    in_rate = case recent_in do
      [] -> 0
      _ -> Enum.sum(recent_in) * 1.0 / length(recent_in)
    end

    out_rate = case recent_out do
      [] -> 0
      _ -> Enum.sum(recent_out) * 1.0 / length(recent_out)
    end
    IO.puts("In: #{in_rate} Out: #{out_rate}")
    Process.send_after(self, :print_stats, @interval)

    {:noreply, state}
  end
end