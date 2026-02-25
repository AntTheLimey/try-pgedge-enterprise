# pgEdge Control Plane -- Get Running Fast

Deploy a 3-node distributed PostgreSQL database with active-active
multi-master replication, all orchestrated by pgEdge Control Plane.

## How to use this guide

**Option A -- Runme (recommended):** Click the **Run** button on each
code block below. Runme is pre-installed in GitHub Codespaces. If you
are running locally, install the
[Runme extension](https://marketplace.visualstudio.com/items?itemName=stateful.runme).

**Option B -- Terminal:** Copy and paste into your terminal:
`bash guides/guide.sh`

## What you will do

1. Start Control Plane
2. Create a distributed database
3. Verify multi-master replication
4. Prove automatic recovery from node failure

---

## Step 1: Start Control Plane

Control Plane is a lightweight orchestrator that manages your Postgres
instances. It runs as a single container and exposes a REST API.

### Initialize Docker Swarm

Control Plane uses Docker Swarm for container orchestration:

```bash
docker swarm init 2>/dev/null || echo "Swarm already active"
```

### Create the data directory

Control Plane persists configuration and database state to a host
directory that gets mounted into the container:

```bash
mkdir -p ~/pgedge/control-plane
echo "Data directory ready: ~/pgedge/control-plane"
```

### Pull and start the Control Plane container

This pulls the Control Plane image from the GitHub container registry
and starts it with host networking. The Docker socket is mounted so
that Control Plane can create and manage Postgres containers on your
behalf.

```bash
docker pull ghcr.io/pgedge/control-plane
docker run --detach \
    --env PGEDGE_HOST_ID=host-1 \
    --env PGEDGE_DATA_DIR=${HOME}/pgedge/control-plane \
    --volume ${HOME}/pgedge/control-plane:${HOME}/pgedge/control-plane \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --network host \
    --name host-1 \
    ghcr.io/pgedge/control-plane \
    run
echo "Waiting for Control Plane API..."
until curl -sf http://localhost:3000/v1/version >/dev/null 2>&1; do
  sleep 2
done
echo "Control Plane is ready!"
```

### Initialize the cluster

Cluster initialization tells Control Plane to set up its internal
state -- registering this host, initializing the metadata store, and
preparing to accept database definitions. This is a one-time
operation:

```bash
curl -sf http://localhost:3000/v1/cluster/init
echo "Cluster initialized."
```

---

## Step 2: Create a Distributed Database

Control Plane uses a declarative model. You describe the database you
want -- name, users, and nodes -- and Control Plane handles the rest.
Spock multi-master replication is configured automatically between all
nodes.

### Create the database

This creates a 3-node database with an admin user. It takes a minute
or two while Control Plane pulls the Postgres image and starts each
node.

> **Tip:** Split the VS Code terminal (Cmd+Shift+5 / Ctrl+Shift+5)
> and run `watch docker ps` in the new pane -- you will want this
> for the rest of the demo.

```bash
curl -s -X POST http://localhost:3000/v1/databases \
    -H "Content-Type: application/json" \
    --data '{
        "id": "example",
        "spec": {
            "database_name": "example",
            "database_users": [
                {
                    "username": "admin",
                    "password": "password",
                    "db_owner": true,
                    "attributes": ["SUPERUSER", "LOGIN"]
                }
            ],
            "nodes": [
                { "name": "n1", "port": 5432, "host_ids": ["host-1"] },
                { "name": "n2", "port": 5433, "host_ids": ["host-1"] },
                { "name": "n3", "port": 5434, "host_ids": ["host-1"] }
            ]
        }
    }'
```

The API returns a JSON task confirming that database creation has
started. Creation is asynchronous -- Control Plane is now pulling the
Postgres image and spinning up three containers in the background.

### Wait for the database

Database creation is asynchronous. Poll until the state is `available`:

```bash
echo "Waiting for database..."
while true; do
  STATE=$(curl -sf \
    http://localhost:3000/v1/databases/example | jq -r '.state')
  echo "  State: $STATE"
  [ "$STATE" = "available" ] && break
  sleep 3
done
echo "Database is ready!"
```

### Verify with psql

Connect to n1 on port 5432 to confirm Postgres is running:

```bash
PGPASSWORD=password psql -h localhost -p 5432 -U admin example \
    -c "SELECT version();"
```

---

## Step 3: Verify Multi-Master Replication

All three nodes have Spock bi-directional replication. Every node
accepts writes and changes propagate automatically.

### Create a table on n1

```bash
PGPASSWORD=password psql -h localhost -p 5432 -U admin example \
    -c "CREATE TABLE example (id int primary key, data text);"
```

### Insert a row on n2

```bash
PGPASSWORD=password psql -h localhost -p 5433 -U admin example \
    -c "INSERT INTO example (id, data) VALUES (1, 'Hello from n2!');"
```

### Read it back from n1

The row was written on n2 but is already on n1 via Spock replication:

```bash
PGPASSWORD=password psql -h localhost -p 5432 -U admin example \
    -c "SELECT * FROM example;"
```

### Write on n3

```bash
PGPASSWORD=password psql -h localhost -p 5434 -U admin example \
    -c "INSERT INTO example (id, data) VALUES (2, 'Hello from n3!');"
```

### Read from n1 again

Both rows should be here -- one replicated from n2, one from n3:

```bash
PGPASSWORD=password psql -h localhost -p 5432 -U admin example \
    -c "SELECT * FROM example;"
```

Both rows replicated to n1. Every node can read every other node's
writes.

---

## Step 4: Resilience

Active-active means every node accepts reads and writes. If a node
goes down, the others keep working -- and Control Plane automatically
detects the failure and recovers the node.

You will halt n2 using Docker service scaling, write data while it is
down, then bring it back and verify Spock catches everything up.

### Scale n2 to 0

Use Docker service scaling to cleanly halt the n2 container. This
prevents Control Plane from auto-recovering the node while you work
through the remaining steps:

```bash
N2_SERVICE=$(docker service ls --filter label=pgedge.component=postgres --filter label=pgedge.node.name=n2 --format '{{ .Name }}')
docker service scale "$N2_SERVICE"=0
echo "Node n2 scaled to 0."
```

### Write on n1 while n2 is down

```bash
PGPASSWORD=password psql -h localhost -p 5432 -U admin example \
    -c "INSERT INTO example (id, data) VALUES (3, 'Written while n2 is down!');"
```

### Read from n3 to confirm the cluster still works

```bash
PGPASSWORD=password psql -h localhost -p 5434 -U admin example \
    -c "SELECT * FROM example;"
```

The cluster kept working with a node down.

### Scale n2 back to 1

```bash
N2_SERVICE=$(docker service ls --filter label=pgedge.component=postgres --filter label=pgedge.node.name=n2 --format '{{ .Name }}')
docker service scale "$N2_SERVICE"=1
echo "Node n2 scaling back up."
```

### Wait for n2 to come back

Poll until the n2 container appears and is ready:

```bash
echo "Waiting for n2 container..."
until docker ps --format '{{.Names}}' \
    | grep -q 'postgres-example-n2-'; do
  sleep 3
done
echo "n2 is back! Waiting for replication sync..."
sleep 5
echo "Done."
```

### Read from n2 to verify recovery

Everything should be here, including the row written while n2 was
down:

```bash
PGPASSWORD=password psql -h localhost -p 5433 -U admin example \
    -c "SELECT * FROM example;"
```

The cluster survived a node failure, n2 came back via service
scaling, and Spock replication caught everything up. Zero data loss.

---

## Cleanup

If you are running in GitHub Codespaces, just delete the Codespace --
no cleanup needed.

If you are running locally, stop everything and remove the data:

    docker rm -f $(docker ps -aq --filter label=pgedge.database.id) host-1
    docker swarm leave --force
    sudo rm -rf ~/pgedge/control-plane

---

## What's Next

You have a working 3-node distributed database with automatic
failover. Here is where to go from here.

### Understand what you just deployed

| Topic | Description |
|-------|-------------|
| [Control Plane docs](https://docs.pgedge.com/control-plane) | Architecture, API reference, configuration options |
| [Core concepts](https://docs.pgedge.com/control-plane/prerequisites/concepts) | Hosts, clusters, databases, nodes, and instances |
| [Spock multi-master](https://docs.pgedge.com/spock-v5) | How active-active replication works under the hood -- conflict resolution, column-level control, tuning |

### Take it further

| Topic | Description |
|-------|-------------|
| [Create and manage databases](https://docs.pgedge.com/control-plane/using/create-db) | Multi-node topologies, user management, connection strings |
| [Backups and restore](https://docs.pgedge.com/control-plane/using/backup-restore) | pgBackRest integration for point-in-time recovery |
| [Read replicas](https://docs.pgedge.com/control-plane/using/read-replicas) | Scale reads without adding multi-master nodes |
| [High availability](https://docs.pgedge.com/control-plane/using-ha) | Connection strategies, failover best practices |
| [Upgrades](https://docs.pgedge.com/control-plane/using/upgrade-db) | Minor and major Postgres version upgrades |

### Explore the ecosystem

| Resource | Link |
|----------|------|
| **Package Catalog** -- browse all 30+ packages, pick your platform | [antthelimy.github.io/try-pgedge-enterprise/package-catalog](https://antthelimy.github.io/try-pgedge-enterprise/package-catalog/) |
| **Enterprise Postgres** -- full package details, troubleshooting, offline repos | [docs.pgedge.com/enterprise](https://docs.pgedge.com/enterprise/) |
| **API Reference** -- interactive OpenAPI docs for the Control Plane REST API | [docs.pgedge.com/control-plane/api/reference](https://docs.pgedge.com/control-plane/api/reference) |
