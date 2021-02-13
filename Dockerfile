# Inspired by: https://hexdocs.pm/phoenix/releases.html#containers
# Inspired by: https://hexdocs.pm/distillery/guides/working_with_docker.html

# The version of Alpine to use for the final image.
# This MUST match the version of Alpine that the builder image uses.
ARG ALPINE_VERSION=3.13.1

FROM hexpm/elixir:1.11.2-erlang-23.2.4-alpine-${ALPINE_VERSION} as deps

# prepare build dir
WORKDIR /app

# install build dependencies
RUN --mount=type=cache,sharing=locked,target=/var/cache/apk \
    apk add build-base git rust cargo make

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
RUN --mount=type=cache,target=/root/.hex \
    mix deps.get --only $MIX_ENV

FROM node:15.7.0-alpine3.10 as assets

# install build dependencies
RUN --mount=type=cache,sharing=locked,target=/var/cache/apk \
    apk add build-base python

# prepare build dir
WORKDIR /app

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
# install all npm dependencies from scratch
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY --from=deps /app/deps ./deps

COPY priv priv

# Note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation step
# down so that `lib` is available.
COPY assets assets
# use webpack to compile npm dependencies - https://www.npmjs.com/package/webpack-deploy
RUN npm run --prefix ./assets deploy

FROM deps as build

# prepare build dir
WORKDIR /app

RUN mkdir config
# Dependencies sometimes use compile-time configuration. Copying
# these compile-time config files before we compile dependencies
# ensures that any relevant config changes will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/$MIX_ENV.exs config/
RUN mix deps.compile

COPY --from=assets /app/priv ./priv
RUN mix phx.digest

# compile and build the release
ENV RUSTFLAGS='--codegen target-feature=-crt-static'
COPY lib lib
COPY native native
RUN mix compile
# changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/
COPY rel rel
RUN mix release docker_swarm_prod

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
# (libgcc is needed for Rust NIFs)
FROM alpine:${ALPINE_VERSION} AS app
RUN --mount=type=cache,sharing=locked,target=/var/cache/apk \
    apk add openssl ncurses-libs bash libgcc iputils

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

ENV MIX_ENV=prod

COPY --from=build --chown=nobody:nobody /app/_build/${MIX_ENV}/rel/docker_swarm_prod ./

ENV HOME=/app

ENTRYPOINT ["bin/docker_swarm_prod"]
CMD ["start"]
