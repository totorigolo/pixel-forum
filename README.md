# PixelForum

## How to run it in dev mode?

To start PixelForum locally:

  * Install Elixir/Erlang/etc: https://hexdocs.pm/phoenix/installation.html
  * Install dependencies with `mix deps.get`.
  * Create and migrate your database with `mix ecto.setup` (checkout `config/`).
  * Install Node.js dependencies with `npm install` inside the `assets` directory.
  * Start Phoenix endpoint with `mix phx.server` or `iex -S mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## How to create a new release?

TODO: Explain bumping versions.

```bash
# Run this if you need to create the database or execute migrations.
$ MIX_ENV=prod mix ecto.migrate

$ mix deps.get --only prod
$ MIX_ENV=prod mix compile
$ npm run deploy --prefix assets
$ MIX_ENV=prod mix phx.digest

$ make build
$ docker tag ...
$ docker push ...
```

## TBD

```bash
docker swarm init
docker swarm leave --force

docker network create pixel_forum-network
docker node update --label-add pixel_forum.db-data=true $PIXEL_FORUM_NODE_ID

docker run --network pixel-forum-network pixel-forum:x.y.z
bin/docker_swarm_prod eval "PixelForum.Release.create_repos"
bin/docker_swarm_prod eval "PixelForum.Release.migrate"
```

## How to find documentation?

* Elixir
  * Official website: https://elixir-lang.org/
* The Phoenix framework
  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
* Any dependency in general:
  * Hex.pm: https://hex.pm/
  * Hexdocs.pm https://hexdocs.pm/
