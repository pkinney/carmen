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
          -96.63986860535047,
          33.1189
        },
        {
          -96.65028980458632,
          33.06940016819441
        },
        {
          -96.68029645186552,
          33.025870746644294
        },
        {
          -96.72626930267523,
          32.99356202601443
        },
        {
          -96.7826633527208,
          32.97637091483871
        },
        {
          -96.84267664727919,
          32.97637091483871
        },
        {
          -96.89907069732476,
          32.99356202601443
        },
        {
          -96.94504354813448,
          33.025870746644294
        },
        {
          -96.97505019541367,
          33.06940016819441
        },
        {
          -96.98547139464952,
          33.1189
        },
        {
          -96.97505019541367,
          33.16839983180558
        },
        {
          -96.94504354813448,
          33.2119292533557
        },
        {
          -96.89907069732476,
          33.24423797398556
        },
        {
          -96.84267664727919,
          33.26142908516128
        },
        {
          -96.7826633527208,
          33.26142908516128
        },
        {
          -96.72626930267523,
          33.24423797398556
        },
        {
          -96.68029645186552,
          33.2119292533557
        },
        {
          -96.65028980458632,
          33.16839983180558
        },
        {
          -96.63986860535047,
          33.1189
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
