defmodule Carmen.Zone.StoreIntersectionBench do
  use Benchfella

  @in_both %Geo.Point{coordinates: {136.884149, 35.172102}}
  @in_concavity %Geo.Point{coordinates: {136.884831, 35.172137}}
  @in_shape3 %Geo.Point{coordinates: {136.8844503, 35.172896}}
  @outside_all %Geo.Point{coordinates: {136.886633, 35.173913}}

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

  @shape3 %Geo.Polygon{ coordinates: [
          [
            { 136.8841016292572, 35.17281732005817 },
            { 136.88421428203583, 35.172694540711184 },
            { 136.88479363918304, 35.1729839488754 },
            { 136.88473999500275, 35.17311988265755 },
            { 136.8841016292572, 35.17281732005817 }
          ]
        ]
      }

  @triangle_in_both %Geo.Polygon{ coordinates: [
          [
            { 136.88402116298676, 35.171269409724786 },
            { 136.88427329063416, 35.171269409724786 },
            { 136.88427329063416, 35.17257176117876 },
            { 136.88402116298676, 35.171269409724786 }
          ]
        ]
      }



  setup_all do
    Application.ensure_all_started(:carmen)
    {:ok, []}
  end

  before_each_bench _ do
    [Zone, ZoneEnv, MapCell] |> Enum.map(&:mnesia.clear_table/1)
    Carmen.Zone.Store.put_zone(@shape1)
    Carmen.Zone.Store.put_zone(@shape2)
    Carmen.Zone.Store.put_zone(@shape3)

    {:ok, []}
  end

  after_each_bench _ do
    [Zone, ZoneEnv, MapCell] |> Enum.map(&:mnesia.clear_table/1)
  end

  bench "Intersect no zones" do
    [] = Carmen.Zone.Store.intersections(@outside_all)
  end

  bench "Intersect envelope but no zones" do
    Carmen.Zone.Store.intersections(@in_concavity)
  end

  bench "Intersect 1 zone" do
    Carmen.Zone.Store.intersections(@in_shape3)
  end

  bench "Intersect 2 zones" do
    Carmen.Zone.Store.intersections(@in_both)
  end

  bench "Triangle intersects 2 zones" do
    Carmen.Zone.Store.intersections(@triangle_in_both)
  end
end
