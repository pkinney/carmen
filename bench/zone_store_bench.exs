defmodule Carmen.Zone.StoreBench do
  use Benchfella

  setup_all do
    Application.ensure_all_started(:carmen)
    {:ok, []}
  end

  after_each_bench _ do
    [Zone, ZoneEnv, MapCell] |> Enum.map(&:mnesia.clear_table/1)
  end

  @shape1 %Geo.Polygon{
    coordinates: [
      [
        {136.883908, 35.172133},
        {136.884101, 35.171878},
        {136.884782, 35.171646},
        {136.885035, 35.171703},
        {136.885035, 35.171927},
        {136.884648, 35.171975},
        {136.884702, 35.172313},
        {136.885040, 35.172304},
        {136.885045, 35.172567},
        {136.884723, 35.172562},
        {136.883908, 35.172133}
      ]
    ]
  }

  @shape2 %Geo.Polygon{
    coordinates: [
      [
        {136.883817, 35.172479},
        {136.883779, 35.171567},
        {136.884423, 35.172111},
        {136.883817, 35.172479}
      ]
    ]
  }

  @shape3 %Geo.Polygon{
    coordinates: [
      [
        {
          -100.8544921875,
          27.176469131898898
        },
        {
          -98.173828125,
          26.391869671769022
        },
        {
          -94.4384765625,
          26.62781822639305
        },
        {
          -91.0546875,
          28.38173504322308
        },
        {
          -89.736328125,
          31.052933985705163
        },
        {
          -89.736328125,
          34.23451236236987
        },
        {
          -91.2744140625,
          36.80928470205937
        },
        {
          -93.8232421875,
          38.20365531807149
        },
        {
          -97.3828125,
          38.20365531807149
        },
        {
          -100.45898437499999,
          37.78808138412046
        },
        {
          -103.0517578125,
          36.06686213257888
        },
        {
          -104.3701171875,
          33.211116472416855
        },
        {
          -103.5791015625,
          29.76437737516313
        },
        {
          -100.8544921875,
          27.176469131898898
        }
      ]
    ]
  }

  bench "Insert a single poly" do
    Carmen.Zone.Store.put_zone(@shape1)
    :ok
  end

  bench "Insert a single poly that is nearly round" do
    Carmen.Zone.Store.put_zone(@shape3)
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
