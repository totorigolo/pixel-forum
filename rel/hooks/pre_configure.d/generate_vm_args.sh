#!/usr/bin/env bash
# Export variables used in vm.args.
# See: https://anadea.info/blog/setting-up-an-elixir-cluster-in-docker-swarm-with-distillery-and-libcluster

# NB: `hostname -i` will return two IP addresses, because the container is part
# of two networks (Traefik and service). For now, there is no serene way to
# select the IP of a given network. We use the first one, which is working so
# far. Let's see if/when this breaks.
# Related GitHub issue: https://github.com/moby/moby/issues/25181
CONTAINER_IP=$(hostname -i | cut -d' ' -f1)
echo "Setting CONTAINER_IP to: ${CONTAINER_IP}"
export CONTAINER_IP
