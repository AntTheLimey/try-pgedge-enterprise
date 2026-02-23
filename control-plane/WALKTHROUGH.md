# pgEdge Control Plane -- Get Running Fast

In this walkthrough you progressively build from a single PostgreSQL
primary through HA to full multi-master replication, all orchestrated
by pgEdge Control Plane.

Click the **Run** button on any code block to execute it directly in
the terminal.

## Prerequisites

- Docker (with host networking enabled)
- curl and jq

## Step 1: Start Control Plane

Initialize Docker Swarm (if not already active):

```bash
docker swarm init 2>/dev/null || echo "Swarm already active"
```

Start the Control Plane container:

```bash
docker run -d --name pgedge-cp \
    --network host \
    -v ~/pgedge/control-plane:/data \
    pgedge/control-plane:latest
```

Wait for it to become healthy:

```bash
until curl -sf http://localhost:3000/v1/cluster/init >/dev/null 2>&1; do sleep 2; done
echo "Control Plane is ready"
```

## Step 2: Deploy a Single Primary

Create a database with one node:

```bash
curl -s -X POST http://localhost:3000/v1/databases \
    -H 'Content-Type: application/json' \
    -d '{"name":"demo","nodes":[{"name":"n1","port":6432}]}' | jq .
```

Verify PostgreSQL is running:

```bash
psql -h localhost -p 6432 -U admin -d demo -c "SELECT version();"
```

## Step 3: Add Read Replicas & HA

Add a streaming replica with automatic failover:

```bash
curl -s -X PATCH http://localhost:3000/v1/databases/demo \
    -H 'Content-Type: application/json' \
    -d '{"nodes":[
      {"name":"n1","port":6432},
      {"name":"n2","port":6433,"role":"replica"}
    ]}' | jq .
```

Check cluster status:

```bash
curl -s http://localhost:3000/v1/databases/demo | jq '.nodes'
```

## Step 4: Go Multi-Master

Enable Spock active-active replication across three nodes:

```bash
curl -s -X PATCH http://localhost:3000/v1/databases/demo \
    -H 'Content-Type: application/json' \
    -d '{"nodes":[
      {"name":"n1","port":6432},
      {"name":"n2","port":6433},
      {"name":"n3","port":6434}
    ],"replication":"multi-master"}' | jq .
```

Prove replication works -- write on n1, read on n3:

```bash
psql -h localhost -p 6432 -d demo -c "CREATE TABLE IF NOT EXISTS test (id int, msg text);"
psql -h localhost -p 6432 -d demo -c "INSERT INTO test VALUES (1, 'from n1');"
psql -h localhost -p 6434 -d demo -c "SELECT * FROM test;"
```

Write on n3, read on n1:

```bash
psql -h localhost -p 6434 -d demo -c "INSERT INTO test VALUES (2, 'from n3');"
psql -h localhost -p 6432 -d demo -c "SELECT * FROM test;"
```

## Cleanup

```bash
docker rm -f pgedge-cp
```

## What's Next

- **Browse all packages:** Run `../package-catalog/serve.sh` and
  open http://localhost:8080
- **Try bare metal:** Run `../bare-metal/guide.sh`
- **Documentation:** https://docs.pgedge.com/enterprise/
