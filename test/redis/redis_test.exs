defmodule Carmen.RedisTest do
  use ExUnit.Case
  doctest Carmen.Redis

  test "redis set and get" do
    key = "foo_#{:rand.uniform(10000000)}"
    value = "bar_#{:rand.uniform(10000000)}"
    Carmen.Redis.set(key, value)

    assert Carmen.Redis.get(key) == {:ok, value}
  end
end