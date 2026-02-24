# Start the Control Plane

The pgEdge Control Plane runs as a Docker container. It uses Docker
Swarm to orchestrate Postgres instances, so it needs access to the
Docker socket.

## Run the Control Plane

```bash
docker run --detach \
  --env PGEDGE_HOST_ID=host-1 \
  --env PGEDGE_DATA_DIR=/var/lib/pgedge \
  --volume /var/lib/pgedge:/var/lib/pgedge \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --network host \
  --name host-1 \
  ghcr.io/pgedge/control-plane \
  run
```

Key flags:
- `--network host` — the CP and Postgres containers share the host
  network, so you can reach them on `localhost`
- `--volume /var/run/docker.sock` — gives the CP access to Docker so
  it can create and manage Postgres containers
- `PGEDGE_HOST_ID` — identifies this host in the cluster
- `PGEDGE_DATA_DIR` — where the CP stores its data

## Verify the CP is running

The CP exposes a REST API on port 3000. Let's hit the cluster
endpoint to confirm it's ready:

```bash
curl -s http://localhost:3000/v1/cluster/init | jq .
```

You should see a response with a `token` and `server_url`. The
Control Plane is running and ready to accept API calls.

## Check the API version

```bash
curl -s http://localhost:3000/v1/version | jq .
```
