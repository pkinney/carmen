# Carmen

Carmen is a streaming database for location events. As an object moves through zones
(geofences) events are emitted for that object. The object state is maintained in a
process so it is very performant for the case where frequent messages are received
for each object.

It is highly configurable. Out of the box it assumes that messages are ordered and partitioned
by `id` before reaching Carmen (the messages for an object will go to the same node) but
by configuring a process registry such as Swarm it can handle mixed messages (messages for any
object can arrive at any node).

The demo can be ran via `mix carmen.demo 5000` where `5000` is the number of moving objects.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `carmen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:carmen, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/carmen](https://hexdocs.pm/carmen).

