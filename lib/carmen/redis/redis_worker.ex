defmodule Carmen.Redis.Worker do
  use GenServer

  ##############################
  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  ##############################
  # Server Callbacks

  def init(opts) do
    Redix.start_link(opts)
  end

  def handle_call({:command, command}, _from, conn) do
    resp = Redix.command(conn, command)
    {:reply, resp, conn}
  end

  def handle_call({:pipeline, command}, _from, conn) do
    resp = Redix.pipeline(conn, command)
    {:reply, resp, conn}
  end
end