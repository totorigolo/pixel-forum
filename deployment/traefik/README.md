# Reverse proxy and load balancing with Traefik

See: https://dockerswarm.rocks/traefik/

## Prerequisites

### DNS zone

Create a new subdomain named `TRAEFIK_DOMAIN`, pointing to the server. Create
`WHOAMI_DOMAIN` as well if you want to do debugging.

## Preparation

On the manager node hosting Traefik:

```bash
docker network create --driver=overlay traefik-public

export TRAEFIK_NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add traefik-public.traefik-public-certificates=true $TRAEFIK_NODE_ID

export TRAEFIK_ACME_EMAIL=YOUR_ACME_EMAIL@example.com
export TRAEFIK_DOMAIN=TRAEFIK_DOMAIN
export TRAEFIK_USERNAME=admin
export TRAEFIK_HASHED_PASSWORD=$(openssl passwd -apr1) # Then write the password twice

export WHOAMI_DOMAIN=WHOAMI_DOMAIN
```

## Deploy

```bash
docker stack deploy -c docker-compose.yml traefik
```
