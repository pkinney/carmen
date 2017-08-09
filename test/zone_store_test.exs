defmodule Carmen.ZoneStoreTest do
  use ExUnit.Case
  doctest Carmen.Zone.Store

  alias Carmen.Zone.Store

  @in_shape1 %Geo.Point{coordinates: {136.884723, 35.171848}}
  @in_both %Geo.Point{coordinates: {136.884149, 35.172102}}
  @in_concavity %Geo.Point{coordinates: {136.884831, 35.172137}}

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


  setup do
    [id: UUID.uuid4()]
  end

  test "put and get shape", %{id: id} do
    Store.put_zone(id, @shape1)
    assert Store.get_zone(id) == @shape1
  end

  test "update a shape", %{id: id} do
    Store.put_zone(id, @shape1)
    Store.put_zone(id, @shape2)
    assert Store.get_zone(id) == @shape2
  end

  test "get a shape that doesn't exist", %{id: id} do
    assert Store.get_zone(id) == nil
  end

  test "intersecting zones for a given point", %{id: id1} do
    id2 = UUID.uuid4()

    IO.inspect Store.put_zone(id1, @shape1)
    Store.put_zone(id2, @shape2)

    assert Store.intersections(@in_shape1) == [id1]
    assert Store.intersections(@in_both) == [id1, id2]
  end

  test "intersecting zones for a point inside concavity", %{id: id} do
    Store.put_zone(id, @shape1)
    assert Store.intersections(@in_concavity) == []
  end
end