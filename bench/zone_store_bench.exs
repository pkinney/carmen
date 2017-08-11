defmodule Carmen.Zone.StoreBench do
  use Benchfella
  import Topo

  setup_all do
    Application.ensure_all_started(:carmen)
    {:ok, []}
  end

  after_each_bench _ do
    [Zone, ZoneEnv, MapCell] |> Enum.map(&:mnesia.clear_table/1)
  end

  @shape1 %Geo.Polygon{ coordinates: [
          [
            { 136.883908, 35.172133 },
            { 136.884101, 35.171878 },
            { 136.884782, 35.171646 },
            { 136.885035, 35.171703 },
            { 136.885035, 35.171927 },
            { 136.884648, 35.171975 },
            { 136.884702, 35.172313 },
            { 136.885040, 35.172304 },
            { 136.885045, 35.172567 },
            { 136.884723, 35.172562 },
            { 136.883908, 35.172133 }
          ]
        ]
      }

  @shape2 %Geo.Polygon{ coordinates: [
          [
              { 136.883817, 35.172479 },
              { 136.883779, 35.171567 },
              { 136.884423, 35.172111 },
              { 136.883817, 35.172479 }
          ]
        ]
      }

  bench "Insert a single poly" do
    Carmen.Zone.Store.put_zone(@shape1)
    :ok
  end

  bench "Insert a single poly overlaping with another poly" do
    Carmen.Zone.Store.put_zone(@shape1)
    Carmen.Zone.Store.put_zone(@shape2)
    :ok
  end

  bench "Update a single poly" do
    id = Carmen.Zone.Store.put_zone(@shape1)
    Carmen.Zone.Store.put_zone(id, @shape2)
    :ok
  end
end