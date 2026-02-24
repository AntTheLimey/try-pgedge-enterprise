# Inspect Your Environment

The background script installed several components while you were
reading the intro. Let's verify everything is ready.

## Check Docker

Your environment has Docker running in Swarm mode:

```bash
docker info --format '{{.Swarm.LocalNodeState}}'
```

You should see `active`.

## Check the Control Plane image

The pgEdge Control Plane image has been pulled:

```bash
docker image ls ghcr.io/pgedge/control-plane
```

You should see the image listed.

## Check tools

jq (for parsing JSON API responses) and psql (for connecting to
Postgres) are installed:

```bash
jq --version
psql --version
```

Everything looks good — let's start the Control Plane.
