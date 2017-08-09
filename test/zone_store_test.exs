defmodule Carmen.ZoneStoreTest do
  use ExUnit.Case
  doctest Carmen.Zone.Store

  alias Carmen.Zone.Store

  @in_shape1 %Geo.Point{coordinates: {136.884723, 35.171848}}
  @in_both %Geo.Point{coordinates: {136.884149, 35.172102}}
  @in_concavity %Geo.Point{coordinates: {136.884831, 35.172137}}
  @in_shape3 %Geo.Point{coordinates: {136.8844503, 35.172896}}

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


  setup do
    [Zone, ZoneEnv, MapCell] |>
      Enum.map(&:mnesia.clear_table/1)

    [ id1: Store.put_zone(@shape1),
      id2: Store.put_zone(@shape2) ]
  end

  test "put and get shape", %{id1: id} do
    assert Store.get_zone(id) == @shape1
  end

  test "update a shape", %{id1: id} do
    Store.put_zone(id, @shape2)
    assert Store.get_zone(id) == @shape2
  end

  test "get a shape that doesn't exist" do
    assert Store.get_zone(UUID.uuid4()) == nil
  end

  test "intersecting zones for a given point", %{id1: id1, id2: id2} do
    assert Store.intersections(@in_shape1) == [id1]
    assert Store.intersections(@in_both) |> Enum.sort == [id1, id2] |> Enum.sort
  end

  test "intersecting zones for a point inside concavity", %{id1: id} do
    assert Store.intersections(@in_concavity) == []
  end

  test "updating zone and grid", %{id1: id1, id2: id2} do
    Store.put_zone(id1, @shape3)
    assert Store.intersections(@in_both) == [id2]
    assert Store.intersections(@in_shape1) == []
    assert Store.intersections(@in_shape3) == [id1]
  end
end