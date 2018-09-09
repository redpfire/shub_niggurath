# Bot

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bot, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bot](https://hexdocs.pm/bot).

## Dependencies

simply `mix deps.get`

## Database

Prepare database:<br>
```
mix ecto.create -r Repo
mix ecto.gen.migration initial
mix ecto.migrate
```
