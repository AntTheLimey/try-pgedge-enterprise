# pgEdge Control Plane -- Get Running Fast

Deploy a 3-node distributed PostgreSQL database with active-active
multi-master replication, all orchestrated by pgEdge Control Plane.

## How to use this guide

**Option A -- Runme (recommended):** Click the **Run** button on each
code block below. Install the
[Runme extension](https://marketplace.visualstudio.com/items?itemName=stateful.runme)
if you don't have it.

**Option B -- Terminal:** Run the interactive guide instead:

```bash
bash guides/guide.sh
```

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

```bash
mkdir -p ~/pgedge/control-plane
```

### Pull and start the Control Plane container

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
```

### Wait for the API

The API starts on port 3000. This block polls until it responds:

```bash
echo "Waiting for Control Plane API..."
until curl -sf http://localhost:3000/v1/version >/dev/null 2>&1; do
  sleep 2
done
echo "Control Plane is ready!"
```

### Initialize the cluster

This creates the cluster and saves the auth token to a file so
subsequent code blocks can use it:

```bash
RESPONSE=$(curl -sf http://localhost:3000/v1/cluster/init)
CP_TOKEN=$(echo "$RESPONSE" | jq -r '.token')
echo "CP_TOKEN=$CP_TOKEN" > /tmp/pgedge-env
echo "Cluster initialized. Token saved to /tmp/pgedge-env"
```

---

## Step 2: Create a Distributed Database

Control Plane uses a declarative model. You describe the database you
want -- name, users, and nodes -- and CP handles the rest. Spock
multi-master replication is configured automatically between all nodes.

### Create the database

This creates a 3-node database with an admin user. It takes a minute
or two while CP pulls the Postgres image and starts each node.

> **Tip:** Open a second terminal and run `watch docker ps` -- you
> will want this for the rest of the demo.

```bash
source /tmp/pgedge-env
curl -s -X POST http://localhost:3000/v1/databases \
    -H "Authorization: Bearer $CP_TOKEN" \
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

### Wait for the database

Database creation is asynchronous. Poll until the state is `available`:

```bash
source /tmp/pgedge-env
echo "Waiting for database..."
while true; do
  STATE=$(curl -sf -H "Authorization: Bearer $CP_TOKEN" \
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

You will kill n2, write data while it is down, and watch Control
Plane bring it back with all the data intact.

> **Important:** Control Plane recovers nodes fast. Run the next few
> blocks quickly in sequence to see the recovery in action. Make sure
> you have `watch docker ps` running in a second terminal.

### Kill n2

```bash
docker stop $(docker ps --format '{{.Names}}' \
    | grep 'postgres-example-n2-' | head -1)
echo "Node n2 stopped."
```

### Write on n1 while n2 is down

Run this immediately after stopping n2:

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

### Wait for Control Plane to recover n2

Control Plane detected that n2 went down and is automatically
recovering it. Watch your second terminal to see the container
reappear:

```bash
echo "Waiting for Control Plane to recover n2..."
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

The cluster survived a node failure, Control Plane auto-recovered n2,
and Spock replication caught everything up. Zero data loss.

---

## Cleanup

Delete the database, stop Control Plane, leave Swarm, and remove
data:

```bash
source /tmp/pgedge-env

# Delete the database via API
curl -sf -X DELETE -H "Authorization: Bearer $CP_TOKEN" \
    http://localhost:3000/v1/databases/example

# Wait for deletion
echo "Waiting for database deletion..."
while curl -sf -H "Authorization: Bearer $CP_TOKEN" \
    http://localhost:3000/v1/databases/example >/dev/null 2>&1; do
  sleep 2
done
echo "Database deleted."

# Stop Control Plane
docker rm -f host-1

# Leave Swarm
docker swarm leave --force

# Remove data
sudo rm -rf ~/pgedge/control-plane

# Clean up env file
rm -f /tmp/pgedge-env

echo "All cleaned up!"
```

---

## What's Next

- **Full documentation:**
  [docs.pgedge.com/enterprise](https://docs.pgedge.com/enterprise/)
- **Browse all packages:**
  [Package Catalog](https://docs.pgedge.com/enterprise/packages)
