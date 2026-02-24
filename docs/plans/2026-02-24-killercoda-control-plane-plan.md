# Killercoda Control Plane Tutorial Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task-by-task.

**Goal:** Build a 7-step Killercoda interactive tutorial for pgEdge
Control Plane that progressively builds a distributed PostgreSQL
cluster via REST API, then demonstrates backup and restore.

**Architecture:** Mirrors the Helm Killercoda scenario structure
(background.sh, step text.md + verify.sh, assets). Runs on
`ubuntu-2204` with Docker. Users interact via curl (REST API) and
psql (database connections). Background script pulls the CP Docker
image while the user reads the intro.

**Tech Stack:** Bash, curl, jq, psql, Docker, Killercoda scenario
format (index.json, markdown steps, verify scripts).

**Design doc:**
`docs/plans/2026-02-24-killercoda-control-plane-design.md`

**Reference implementation (Helm killercoda):**
`/Users/apegg/PROJECTS/try-pgedge-helm/killercoda/`

---

### Task 1: Create scenario skeleton and index.json

**Files:**
- Create: `killercoda/control-plane/index.json`

**Step 1: Create the index.json**

```json
{
  "title": "pgEdge Control Plane: Distributed Postgres",
  "description": "Deploy distributed active-active PostgreSQL using the pgEdge Control Plane REST API — single node to multi-master with backup & restore",
  "details": {
    "intro": {
      "text": "intro/text.md",
      "background": "intro/background.sh",
      "foreground": "intro/foreground.sh"
    },
    "steps": [
      { "title": "Inspect Your Environment", "text": "step1/text.md", "verify": "step1/verify.sh" },
      { "title": "Start the Control Plane", "text": "step2/text.md", "verify": "step2/verify.sh" },
      { "title": "Create a Single-Node Database", "text": "step3/text.md", "verify": "step3/verify.sh" },
      { "title": "Go Multi-Master", "text": "step4/text.md", "verify": "step4/verify.sh" },
      { "title": "Prove Replication", "text": "step5/text.md", "verify": "step5/verify.sh" },
      { "title": "Backup & Restore", "text": "step6/text.md", "verify": "step6/verify.sh" },
      { "title": "Explore & Next Steps", "text": "step7/text.md" }
    ],
    "finish": {
      "text": "finish/text.md"
    },
    "assets": {
      "host01": [
        { "file": "wait-background.sh", "target": "/usr/local/bin", "chmod": "+x" },
        { "file": "wait-for-db.sh", "target": "/usr/local/bin", "chmod": "+x" }
      ]
    }
  },
  "backend": {
    "imageid": "ubuntu-2204"
  }
}
```

**Step 2: Verify JSON is valid**

Run: `jq . killercoda/control-plane/index.json`
Expected: Pretty-printed JSON, no errors.

**Step 3: Commit**

```bash
git add killercoda/control-plane/index.json
git commit -m "feat(killercoda): add control plane scenario skeleton"
```

---

### Task 2: Create background setup and helper scripts

**Files:**
- Create: `killercoda/control-plane/intro/background.sh`
- Create: `killercoda/control-plane/intro/foreground.sh`
- Create: `killercoda/control-plane/assets/wait-background.sh`
- Create: `killercoda/control-plane/assets/wait-for-db.sh`

**Step 1: Create intro/background.sh**

```bash
#!/bin/bash
set -euo pipefail

# --- Killercoda background installer ---
# Pulls the Control Plane image and installs tools.
# The foreground script waits for /tmp/.background-done before proceeding.

echo "Initializing Docker Swarm..."
docker swarm init 2>/dev/null || true

echo "Pulling pgEdge Control Plane image..."
docker pull ghcr.io/pgedge/control-plane

echo "Installing tools..."
apt-get update -qq
apt-get install -y -qq jq postgresql-client > /dev/null 2>&1

echo "Creating backup directory..."
mkdir -p /var/lib/pgedge/backups

touch /tmp/.background-done
echo "Background setup complete!"
```

**Step 2: Create intro/foreground.sh**

```bash
#!/bin/bash
wait-background.sh
```

**Step 3: Create assets/wait-background.sh**

Reuse the Helm killercoda pattern. Reference:
`/Users/apegg/PROJECTS/try-pgedge-helm/killercoda/assets/wait-background.sh`

```bash
#!/bin/bash
# Waits for the background installer to finish.
# Killercoda copies this to /usr/local/bin with +x via index.json assets.

echo "Setting up your environment — this takes about 1 minute..."
echo ""

spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0
while [ ! -f /tmp/.background-done ]; do
  printf "\r  %s Installing components..." "${spinner[$i]}"
  i=$(( (i + 1) % ${#spinner[@]} ))
  sleep 0.3
done
printf "\r  ✓ All components installed.         \n"

echo ""
echo "Environment is ready! Click 'Next' to continue."
```

**Step 4: Create assets/wait-for-db.sh**

This helper polls the database status API until the database reaches
the `available` state. Used in steps 3, 4, and 6 to avoid users
manually retrying curl commands.

```bash
#!/bin/bash
# Waits for a database to reach "available" state.
# Usage: wait-for-db.sh <database_id> [timeout_seconds]
#
# Killercoda copies this to /usr/local/bin with +x via index.json assets.

DB_ID="${1:?Usage: wait-for-db.sh <database_id> [timeout_seconds]}"
TIMEOUT="${2:-180}"

spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0
elapsed=0

while [ "$elapsed" -lt "$TIMEOUT" ]; do
  state=$(curl -sf "http://localhost:3000/v1/databases/${DB_ID}" 2>/dev/null | jq -r '.state // empty')

  if [ "$state" = "available" ]; then
    printf "\r  ✓ Database '%s' is available.         \n" "$DB_ID"
    exit 0
  fi

  printf "\r  %s Waiting for database '%s' (state: %s)..." "${spinner[$i]}" "$DB_ID" "${state:-pending}"
  i=$(( (i + 1) % ${#spinner[@]} ))
  sleep 3
  elapsed=$((elapsed + 3))
done

echo ""
echo "  ✗ Timed out after ${TIMEOUT}s waiting for database '${DB_ID}'"
exit 1
```

**Step 5: Make scripts executable**

Run: `chmod +x killercoda/control-plane/intro/background.sh killercoda/control-plane/intro/foreground.sh killercoda/control-plane/assets/wait-background.sh killercoda/control-plane/assets/wait-for-db.sh`

**Step 6: Verify scripts pass shellcheck**

Run: `shellcheck killercoda/control-plane/intro/background.sh killercoda/control-plane/intro/foreground.sh killercoda/control-plane/assets/wait-background.sh killercoda/control-plane/assets/wait-for-db.sh`
Expected: No errors.

**Step 7: Commit**

```bash
git add killercoda/control-plane/intro/ killercoda/control-plane/assets/
git commit -m "feat(killercoda): add background setup and helper scripts"
```

---

### Task 3: Create intro and step 1 (Inspect Environment)

**Files:**
- Create: `killercoda/control-plane/intro/text.md`
- Create: `killercoda/control-plane/step1/text.md`
- Create: `killercoda/control-plane/step1/verify.sh`

**Step 1: Create intro/text.md**

```markdown
# pgEdge Control Plane: Distributed Postgres

In this scenario you'll progressively build a **distributed PostgreSQL
cluster** using the pgEdge Control Plane REST API. Instead of deploying
everything at once, you'll evolve the architecture step-by-step:

| Step | What you'll do |
|------|---------------|
| **Start Control Plane** | Run the CP container on Docker |
| **Single-Node Database** | Create a database with one Postgres node |
| **Multi-Master** | Add a second node with Spock active-active replication |
| **Prove It Works** | Write data on one node, read it on the other |
| **Backup & Restore** | Take a full backup and restore from it |

The Control Plane is a lightweight orchestrator that manages Postgres
instances via a declarative REST API. You describe what you want
(nodes, users, replication) and the CP handles container orchestration,
Spock configuration, and lifecycle management.

## What's being installed

While you read this, a background script is:

- Initializing **Docker Swarm** mode
- Pulling the **pgEdge Control Plane** image
- Installing **jq** and **psql** client tools

This takes about 1 minute. You'll see a confirmation when it's ready.
```

**Step 2: Create step1/text.md**

```markdown
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
```

**Step 3: Create step1/verify.sh**

```bash
#!/bin/bash
# Verify Docker Swarm is active and CP image is pulled
docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q active && \
docker image ls ghcr.io/pgedge/control-plane --format '{{.Repository}}' | grep -q control-plane && \
command -v jq > /dev/null 2>&1 && \
command -v psql > /dev/null 2>&1
```

**Step 4: Make verify script executable**

Run: `chmod +x killercoda/control-plane/step1/verify.sh`

**Step 5: Commit**

```bash
git add killercoda/control-plane/intro/text.md killercoda/control-plane/step1/
git commit -m "feat(killercoda): add intro and step 1 (inspect environment)"
```

---

### Task 4: Create step 2 (Start the Control Plane)

**Files:**
- Create: `killercoda/control-plane/step2/text.md`
- Create: `killercoda/control-plane/step2/verify.sh`

**Step 1: Create step2/text.md**

```markdown
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
```

**Step 2: Create step2/verify.sh**

```bash
#!/bin/bash
# Verify Control Plane is responding
curl -sf http://localhost:3000/v1/cluster/init > /dev/null 2>&1
```

**Step 3: Make executable and commit**

```bash
chmod +x killercoda/control-plane/step2/verify.sh
git add killercoda/control-plane/step2/
git commit -m "feat(killercoda): add step 2 (start control plane)"
```

---

### Task 5: Create step 3 (Create Single-Node Database)

**Files:**
- Create: `killercoda/control-plane/step3/text.md`
- Create: `killercoda/control-plane/step3/verify.sh`

**Step 1: Create step3/text.md**

```markdown
# Create a Single-Node Database

Let's create a database with a single Postgres node. The Control Plane
API is declarative — you describe what you want and it handles the
rest.

## Create the database

This POST creates a database called `demo` with one node (`n1`)
running on our host:

```bash
curl -s -X POST http://localhost:3000/v1/databases \
  -H "Content-Type: application/json" \
  -d '{
    "id": "demo",
    "spec": {
      "database_name": "demo",
      "nodes": [
        { "name": "n1", "host_ids": ["host-1"] }
      ],
      "database_users": [
        { "username": "admin", "password": "secret", "db_owner": true }
      ]
    }
  }' | jq .
```

The response includes a `task` object — database creation is
asynchronous. The CP is now pulling the Postgres image and
configuring the instance.

## Wait for it to be ready

A helper script polls the API until the database reaches `available`
state:

```bash
wait-for-db.sh demo
```

This typically takes 30-60 seconds.

## Check the database status

Now let's see the full database status:

```bash
curl -s http://localhost:3000/v1/databases/demo | jq .
```

Note the `instances` array — it shows your node `n1` with its
connection info including the **port number**. Let's extract it:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
echo "n1 is running on port $N1_PORT"
```

## Connect with psql

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "SELECT version();"
```

You now have a single Postgres node managed by the Control Plane.

**Next:** Let's add a second node for active-active multi-master
replication.
```

**Step 2: Create step3/verify.sh**

```bash
#!/bin/bash
# Verify the database is available with 1 node
curl -sf http://localhost:3000/v1/databases/demo 2>/dev/null | \
  jq -e '.state == "available"' > /dev/null 2>&1
```

**Step 3: Make executable and commit**

```bash
chmod +x killercoda/control-plane/step3/verify.sh
git add killercoda/control-plane/step3/
git commit -m "feat(killercoda): add step 3 (create single-node database)"
```

---

### Task 6: Create step 4 (Go Multi-Master)

**Files:**
- Create: `killercoda/control-plane/step4/text.md`
- Create: `killercoda/control-plane/step4/verify.sh`

**Step 1: Create step4/text.md**

```markdown
# Go Multi-Master

This is where pgEdge shines. You'll add a **second node** (`n2`) with
**Spock active-active replication**. Both nodes will accept writes, and
changes replicate bidirectionally.

## Update the database

To add a node, POST the updated spec to the database endpoint. The
spec must include **all** nodes (existing + new):

```bash
curl -s -X POST http://localhost:3000/v1/databases/demo \
  -H "Content-Type: application/json" \
  -d '{
    "spec": {
      "database_name": "demo",
      "nodes": [
        { "name": "n1", "host_ids": ["host-1"] },
        { "name": "n2", "host_ids": ["host-1"], "source_node": "n1" }
      ],
      "database_users": [
        { "username": "admin", "password": "secret", "db_owner": true }
      ]
    }
  }' | jq .
```

Key points:
- `source_node: "n1"` tells the CP to sync n2's data from n1
- The full spec is required (n1 + n2), not just the delta
- Both nodes run on the same host — in production, you'd use
  different hosts for geographic distribution

## Wait for the update

```bash
wait-for-db.sh demo
```

## Check both nodes

```bash
curl -s http://localhost:3000/v1/databases/demo | jq '.instances[] | {node_name, state, role: .postgres.role, port: .connection_info.port}'
```

You should see two instances — both with `role: "primary"`. That's
active-active: both nodes accept reads and writes.

## Verify Spock subscriptions

```bash
curl -s http://localhost:3000/v1/databases/demo | jq '.instances[] | {node_name, subscriptions: .spock.subscriptions}'
```

Each node should show a subscription to the other with status
`replicating`.

**Next:** Let's prove it works with real data.
```

**Step 2: Create step4/verify.sh**

```bash
#!/bin/bash
# Verify both nodes are available
curl -sf http://localhost:3000/v1/databases/demo 2>/dev/null | \
  jq -e '.state == "available" and ([.instances[] | select(.node_name == "n1" or .node_name == "n2")] | length == 2)' > /dev/null 2>&1
```

**Step 3: Make executable and commit**

```bash
chmod +x killercoda/control-plane/step4/verify.sh
git add killercoda/control-plane/step4/
git commit -m "feat(killercoda): add step 4 (go multi-master)"
```

---

### Task 7: Create step 5 (Prove Replication)

**Files:**
- Create: `killercoda/control-plane/step5/text.md`
- Create: `killercoda/control-plane/step5/verify.sh`

**Step 1: Create step5/text.md**

```markdown
# Prove Replication

Let's verify that active-active replication is working by writing data
on one node and reading it on the other.

## Get the ports

First, grab the port for each node:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
echo "n1: port $N1_PORT  |  n2: port $N2_PORT"
```

## Create a table on n1

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "
CREATE TABLE cities (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  country TEXT NOT NULL
);"
```

## Insert data on n1

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "
INSERT INTO cities (id, name, country) VALUES
  (1, 'New York', 'USA'),
  (2, 'London', 'UK'),
  (3, 'Tokyo', 'Japan');"
```

## Read on n2

These rows were written on n1 but are already replicated to n2:

```bash
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N2_PORT" -U admin demo -c "SELECT * FROM cities;"
```

You should see all 3 cities.

## Write on n2

This is the active-active part — n2 can accept writes too:

```bash
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N2_PORT" -U admin demo -c "
INSERT INTO cities (id, name, country) VALUES
  (4, 'Sydney', 'Australia'),
  (5, 'Berlin', 'Germany');"
```

## Read back on n1

All 5 rows should be here — 3 written locally and 2 replicated
from n2:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "SELECT * FROM cities ORDER BY id;"
```

**Bidirectional active-active replication confirmed.**

**Next:** Let's protect this data with backup and restore.
```

**Step 2: Create step5/verify.sh**

```bash
#!/bin/bash
# Verify data replicated to both nodes (5 rows each)
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -tAc "SELECT count(*) FROM cities;" 2>/dev/null | grep -q "5" && \
PGPASSWORD=secret psql -h localhost -p "$N2_PORT" -U admin demo -tAc "SELECT count(*) FROM cities;" 2>/dev/null | grep -q "5"
```

**Step 3: Make executable and commit**

```bash
chmod +x killercoda/control-plane/step5/verify.sh
git add killercoda/control-plane/step5/
git commit -m "feat(killercoda): add step 5 (prove replication)"
```

---

### Task 8: Create step 6 (Backup & Restore)

**Files:**
- Create: `killercoda/control-plane/step6/text.md`
- Create: `killercoda/control-plane/step6/verify.sh`

**Step 1: Create step6/text.md**

The backup step requires updating the database spec to add
`backup_config` and `orchestrator_opts.swarm.extra_volumes`, then
taking a backup, inserting more data, and restoring to prove the
backup works.

```markdown
# Backup & Restore

Let's protect our data. The Control Plane supports full, differential,
and incremental backups via pgBackRest. We'll configure a local
(posix) backup repository, take a full backup, and then restore
from it.

## Configure backups

First, update the database spec to add backup configuration. This
mounts a backup directory into the Postgres containers and tells
pgBackRest where to store backups:

```bash
curl -s -X POST http://localhost:3000/v1/databases/demo \
  -H "Content-Type: application/json" \
  -d '{
    "spec": {
      "database_name": "demo",
      "nodes": [
        { "name": "n1", "host_ids": ["host-1"] },
        { "name": "n2", "host_ids": ["host-1"] }
      ],
      "database_users": [
        { "username": "admin", "password": "secret", "db_owner": true }
      ],
      "orchestrator_opts": {
        "swarm": {
          "extra_volumes": [
            {
              "host_path": "/var/lib/pgedge/backups",
              "destination_path": "/backups"
            }
          ]
        }
      },
      "backup_config": {
        "repositories": [
          {
            "id": "local-repo",
            "type": "posix",
            "base_path": "/backups"
          }
        ]
      }
    }
  }' | jq .
```

Wait for the update:

```bash
wait-for-db.sh demo
```

## Take a full backup

Now take a full backup of node n1:

```bash
curl -s -X POST http://localhost:3000/v1/databases/demo/nodes/n1/backups \
  -H "Content-Type: application/json" \
  -d '{ "type": "full" }' | jq .
```

The response includes a `task` object. Let's wait for it to complete:

```bash
TASK_ID=$(curl -s -X POST http://localhost:3000/v1/databases/demo/nodes/n1/backups \
  -H "Content-Type: application/json" \
  -d '{ "type": "full" }' | jq -r '.task.task_id')
echo "Backup task: $TASK_ID"
```

Wait a moment and check the task status:

```bash
sleep 15
curl -s "http://localhost:3000/v1/databases/demo/tasks/$TASK_ID" | jq '{status, type}'
```

> **Note:** If the status is still `running`, wait a few more seconds
> and check again. Full backups typically complete in under a minute.

## Add data after the backup

Let's add more data so we can prove the restore works:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "
INSERT INTO cities (id, name, country) VALUES
  (6, 'Paris', 'France'),
  (7, 'Mumbai', 'India');"
```

Verify we now have 7 rows:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "SELECT count(*) FROM cities;"
```

## Restore from backup

Now restore the database to the state at backup time. This will
remove the 2 rows we just added:

```bash
curl -s -X POST http://localhost:3000/v1/databases/demo/restore \
  -H "Content-Type: application/json" \
  -d '{
    "restore_config": {
      "source_database_id": "demo",
      "source_node_name": "n1",
      "source_database_name": "demo",
      "repository": {
        "id": "local-repo",
        "type": "posix",
        "base_path": "/backups"
      }
    }
  }' | jq .
```

Wait for the restore to complete:

```bash
wait-for-db.sh demo
```

## Verify the restore

The 2 rows added after the backup (Paris, Mumbai) should be gone:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "SELECT * FROM cities ORDER BY id;"
```

You should see 5 rows (the original cities), confirming the restore
worked.

**Backup and restore confirmed!**
```

**Step 2: Create step6/verify.sh**

```bash
#!/bin/bash
# Verify backup config is set on the database
curl -sf http://localhost:3000/v1/databases/demo 2>/dev/null | \
  jq -e '.spec.backup_config.repositories | length > 0' > /dev/null 2>&1
```

**Step 3: Make executable and commit**

```bash
chmod +x killercoda/control-plane/step6/verify.sh
git add killercoda/control-plane/step6/
git commit -m "feat(killercoda): add step 6 (backup and restore)"
```

---

### Task 9: Create step 7 (Explore & Next Steps) and finish

**Files:**
- Create: `killercoda/control-plane/step7/text.md`
- Create: `killercoda/control-plane/finish/text.md`

**Step 1: Create step7/text.md**

```markdown
# Explore & Next Steps

Congratulations — you have a working distributed PostgreSQL cluster
with backup and restore! Here are some things to try.

## Useful API endpoints

| Endpoint | What it does |
|----------|-------------|
| `GET /v1/databases` | List all databases |
| `GET /v1/databases/demo` | Full database status |
| `GET /v1/databases/demo/tasks` | List database tasks |
| `DELETE /v1/databases/demo` | Delete the database |
| `GET /v1/cluster` | Cluster info |
| `GET /v1/hosts` | List hosts |
| `GET /v1/version` | API version |

## Useful psql commands

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')

# Open a psql shell
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo

# Check Spock replication status
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo \
  -c "SELECT * FROM spock.sub_show_status();"

# Check Spock nodes
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo \
  -c "SELECT * FROM spock.node;"
```

## Add a third node

You can scale to three nodes with another API call:

```bash
curl -s -X POST http://localhost:3000/v1/databases/demo \
  -H "Content-Type: application/json" \
  -d '{
    "spec": {
      "database_name": "demo",
      "nodes": [
        { "name": "n1", "host_ids": ["host-1"] },
        { "name": "n2", "host_ids": ["host-1"] },
        { "name": "n3", "host_ids": ["host-1"], "source_node": "n1" }
      ],
      "database_users": [
        { "username": "admin", "password": "secret", "db_owner": true }
      ]
    }
  }' | jq .
```

Then wait: `wait-for-db.sh demo`

## What's different in production

In this tutorial, all nodes run on a single host. In production:
- Each node runs on a separate host (different regions/AZs)
- Multiple `host_ids` per node enable read replicas within a node
- S3/GCS/Azure backup repositories replace local posix storage
- Scheduled backups run automatically via cron expressions
```

**Step 2: Create finish/text.md**

```markdown
# Congratulations!

You've successfully deployed a **distributed, active-active PostgreSQL
cluster** using the pgEdge Control Plane — and protected it with
backup and restore.

## What you built

1. **Control Plane** — Lightweight orchestrator managing Postgres via
   REST API
2. **Single-Node Database** — One Postgres instance, API-driven
3. **Multi-Master** — Added a second node with Spock active-active
   replication
4. **Proved Replication** — Wrote on one node, read on the other
5. **Backup & Restore** — Full backup with pgBackRest, point-in-time
   restore

## Keep exploring

- **Kubernetes deployment** — Deploy pgEdge on K8s with Helm:
  [try-pgedge-helm](https://github.com/AntTheLimey/try-pgedge-helm)

- **pgEdge Documentation** — Spock replication, conflict resolution,
  and more: [docs.pgedge.com](https://docs.pgedge.com)

- **pgEdge Cloud** — Managed distributed PostgreSQL:
  [pgedge.com](https://www.pgedge.com)
```

**Step 3: Commit**

```bash
git add killercoda/control-plane/step7/ killercoda/control-plane/finish/
git commit -m "feat(killercoda): add step 7 (explore) and finish page"
```

---

### Task 10: Final validation

**Step 1: Verify all files exist**

Run: `find killercoda/control-plane -type f | sort`

Expected output:
```
killercoda/control-plane/assets/wait-background.sh
killercoda/control-plane/assets/wait-for-db.sh
killercoda/control-plane/finish/text.md
killercoda/control-plane/index.json
killercoda/control-plane/intro/background.sh
killercoda/control-plane/intro/foreground.sh
killercoda/control-plane/intro/text.md
killercoda/control-plane/step1/text.md
killercoda/control-plane/step1/verify.sh
killercoda/control-plane/step2/text.md
killercoda/control-plane/step2/verify.sh
killercoda/control-plane/step3/text.md
killercoda/control-plane/step3/verify.sh
killercoda/control-plane/step4/text.md
killercoda/control-plane/step4/verify.sh
killercoda/control-plane/step5/text.md
killercoda/control-plane/step5/verify.sh
killercoda/control-plane/step6/text.md
killercoda/control-plane/step6/verify.sh
killercoda/control-plane/step7/text.md
```

**Step 2: Validate JSON**

Run: `jq . killercoda/control-plane/index.json`
Expected: Valid JSON, no errors.

**Step 3: Run shellcheck on all scripts**

Run: `shellcheck killercoda/control-plane/**/*.sh`
Expected: No errors.

**Step 4: Verify all verify.sh scripts are executable**

Run: `ls -la killercoda/control-plane/step*/verify.sh`
Expected: All have `x` permission.

**Step 5: Commit any fixes**

If shellcheck found issues, fix them and commit:
```bash
git add killercoda/control-plane/
git commit -m "fix(killercoda): address shellcheck findings"
```
