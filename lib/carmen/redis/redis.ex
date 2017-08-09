defmodule Carmen.Redis do
  alias Carmen.Redis.Pool

  def set(key, value) do
    Pool.command(["set", key, value])
  end

  def get(key) do
    Pool.command(["get", key])
  end

  def command(command) do
    Pool.command(command)
  end

  def pipeline(commands) do
    Pool.pipeline(commands)
  end
end