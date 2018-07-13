defmodule Carmen.ObjectTest do
  use ExUnit.Case
  doctest Carmen.Object

  alias Carmen.Object
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

  @triangle_in_both %Geo.Polygon{ coordinates: [
          [
            { 136.88402116298676, 35.171269409724786 },
            { 136.88427329063416, 35.171269409724786 },
            { 136.88427329063416, 35.17257176117876 },
            { 136.88402116298676, 35.171269409724786 }
          ]
        ]
      }


  setup do
    [Zone, ZoneEnv, MapCell] |>
      Enum.map(&:mnesia.clear_table/1)

    [ id1: Store.put_zone(@shape1),
      id2: Store.put_zone(@shape2) ]
  end

  test "adding a new object outside of a zone should not generate an event" do
    assert Object.update(UUID.uuid4(), @in_concavity) == {[], []}
  end

  test "adding a new object inside of a zone should generate an event", %{id1: id1} do
    assert Object.update(UUID.uuid4(), @in_shape1) == {[id1], []}
  end

  test "moving and object from one zone to another generates an event", %{id1: id1, id2: id2} do
    id = UUID.uuid4()
    Object.update(id, @in_shape1)
    assert Object.update(id, @in_both) == {[id2], []}
    assert Object.update(id, @in_shape1) == {[], [id2]}
    id3 = Store.put_zone(@shape3)
    assert Object.update(id, @in_shape3) == {[id3], [id1]}
  end

  test "changing shape and object from one zone to another generates an event", %{id2: id2} do
    id = UUID.uuid4()
    Object.update(id, @in_shape1)
    assert Object.update(id, @triangle_in_both) == {[id2], []}
  end

  test "get current relationship between object and shape", %{id1: id1, id2: id2} do
    id = UUID.uuid4()
    Object.update(id, @in_shape1)

    assert Object.intersecting?(id, id1)
    refute Object.intersecting?(id, id2)
  end

  test "return false for relationship between unknown object and shape", %{id1: id1, id2: _} do
    id = UUID.uuid4()
    refute Object.intersecting?(id, id1)
  end
end
