# pgEdge Control Plane -- Get Running Fast

In this walkthrough you create a 3-node distributed PostgreSQL database
with active-active multi-master replication, all orchestrated by pgEdge
Control Plane.

Click the **Run** button on any code block to execute it directly in
the terminal.

## Prerequisites

- Docker (with host networking enabled)
- curl and jq
- psql (optional but recommended)

## Step 1: Start Control Plane

Initialize Docker Swarm (if not already active):

```bash
docker swarm init 2>/dev/null || echo "Swarm already active"
```

Create the data directory:

```bash
mkdir -p ~/pgedge/control-plane
```

Start the Control Plane container:

```bash
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

Initialize the cluster:

```bash
curl http://localhost:3000/v1/cluster/init
```

Wait for the API to become ready:

```bash
until curl -sf http://localhost:3000/v1/cluster/init >/dev/null 2>&1; do sleep 2; done
echo "Control Plane is ready"
```

## Step 2: Create a Distributed Database

Create a 3-node database with an admin user. Multi-master replication
via Spock is configured automatically:

```bash
curl -X POST http://localhost:3000/v1/databases \
    -H 'Content-Type: application/json' \
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
                { "name": "n1", "port": 6432, "host_ids": ["host-1"] },
                { "name": "n2", "port": 6433, "host_ids": ["host-1"] },
                { "name": "n3", "port": 6434, "host_ids": ["host-1"] }
            ]
        }
    }'
```

Database creation is asynchronous. Poll until the state is `available`:

```bash
while true; do
  state=$(curl -s http://localhost:3000/v1/databases/example | jq -r '.state')
  echo "State: $state"
  [ "$state" = "available" ] && break
  sleep 3
done
echo "Database is ready!"
```

Connect to verify PostgreSQL is running:

```bash
PGPASSWORD=password psql -h localhost -p 6432 -U admin example -c "SELECT version();"
```

## Step 3: Verify Multi-Master Replication

Create a table on n1:

```bash
PGPASSWORD=password psql -h localhost -p 6432 -U admin example -c "CREATE TABLE example (id int primary key, data text);"
```

Insert a row on n2:

```bash
PGPASSWORD=password psql -h localhost -p 6433 -U admin example -c "INSERT INTO example (id, data) VALUES (1, 'Hello from n2!');"
```

Read it back from n1 -- replicated via Spock:

```bash
PGPASSWORD=password psql -h localhost -p 6432 -U admin example -c "SELECT * FROM example;"
```

Write on n3, read from n1:

```bash
PGPASSWORD=password psql -h localhost -p 6434 -U admin example -c "INSERT INTO example (id, data) VALUES (2, 'Hello from n3!');"
PGPASSWORD=password psql -h localhost -p 6432 -U admin example -c "SELECT * FROM example;"
```

## Cleanup

Delete the database:

```bash
curl -X DELETE http://localhost:3000/v1/databases/example
```

Wait for deletion to complete, then stop the Control Plane:

```bash
# Wait for database deletion
while curl -sf http://localhost:3000/v1/databases/example >/dev/null 2>&1; do sleep 2; done

docker stop host-1
docker rm host-1
rm -rf ~/pgedge/control-plane
```

## What's Next

- **Browse all packages:**
  [Package Catalog](https://antthelimey.github.io/try-pgedge-enterprise/package-catalog/)
- **Try bare metal:** Run `../bare-metal/guide.sh`
- **Documentation:** https://docs.pgedge.com/enterprise/
