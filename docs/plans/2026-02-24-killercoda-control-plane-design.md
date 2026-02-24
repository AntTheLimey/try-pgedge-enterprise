# Killercoda Control Plane Tutorial Design

## Goal

Build a Killercoda interactive tutorial for pgEdge Control Plane that
mirrors the structure of the existing Helm Killercoda scenario. Users
progressively build a distributed PostgreSQL cluster using the Control
Plane REST API, then learn backup and restore.

## Architecture

The tutorial runs on a Killercoda `ubuntu-2204` environment (Docker
pre-installed, no Kubernetes). The Control Plane runs as a Docker
container with host networking. Users interact via curl (REST API) and
psql (database). The background script pulls the CP image while the
user reads the intro (~30s).

**Location:** `try-pgedge-enterprise/killercoda/control-plane/`

## Environment

- **Killercoda image:** `ubuntu-2204`
- **Docker image:** `ghcr.io/pgedge/control-plane`
- **Networking:** `--network host` (CP on port 3000, PG on
  auto-assigned ports)
- **Volumes:** `/var/lib/pgedge` for data, `/var/run/docker.sock` for
  Docker API access

## Step Progression

| Step | Title | User Action | Verify |
|------|-------|-------------|--------|
| Intro | Welcome | Read while image pulls | wait-background.sh |
| 1 | Inspect Environment | Check Docker, image | `docker image ls` grep |
| 2 | Start Control Plane | `docker run` CP, health check | curl health endpoint |
| 3 | Create Single-Node DB | POST /v1/databases (1 node) | GET status = available |
| 4 | Go Multi-Master | POST update (add n2) | Both nodes available |
| 5 | Prove Replication | psql write n1, read n2 and vice versa | Row count |
| 6 | Backup & Restore | Full backup, point-in-time restore | Backup task complete |
| 7 | Explore & Next Steps | Links, useful commands | None |

## File Structure

    killercoda/control-plane/
    +-- index.json
    +-- intro/
    |   +-- text.md
    |   +-- background.sh
    |   +-- foreground.sh
    +-- step1/
    |   +-- text.md
    |   +-- verify.sh
    +-- step2/
    |   +-- text.md
    |   +-- verify.sh
    +-- step3/
    |   +-- text.md
    |   +-- verify.sh
    +-- step4/
    |   +-- text.md
    |   +-- verify.sh
    +-- step5/
    |   +-- text.md
    |   +-- verify.sh
    +-- step6/
    |   +-- text.md
    |   +-- verify.sh
    +-- step7/
    |   +-- text.md
    +-- finish/
    |   +-- text.md
    +-- assets/
        +-- wait-background.sh
        +-- wait-for-db.sh

## Background Setup (intro/background.sh)

- `docker swarm init`
- `docker pull ghcr.io/pgedge/control-plane`
- Install jq and psql client (`apt-get install -y jq postgresql-client`)
- Touch `/tmp/.background-done`

Estimated time: ~30 seconds (image pull dominates).

## API Payloads

### Step 3: Create Single-Node Database

    POST /v1/databases
    {
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
    }

Poll `GET /v1/databases/demo` until `state: available`. Ports are
auto-assigned; read from the status response.

### Step 4: Add Second Node for Multi-Master

    POST /v1/databases/demo
    {
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
    }

Full spec required (n1 + n2), not just the delta.

### Step 5: Prove Replication

    PGPASSWORD=secret psql -h localhost -p <n1_port> -U admin demo \
      -c "CREATE TABLE cities (id int primary key, name text, country text);"

    PGPASSWORD=secret psql -h localhost -p <n2_port> -U admin demo \
      -c "INSERT INTO cities VALUES (1, 'Tokyo', 'Japan');"

    PGPASSWORD=secret psql -h localhost -p <n1_port> -U admin demo \
      -c "SELECT * FROM cities;"

Ports extracted from GET /v1/databases/demo response.

### Step 6: Backup & Restore

**Take backup:**

    POST /v1/databases/demo/nodes/n1/backups
    { "type": "full" }

Poll task until complete.

**Restore:**

    POST /v1/databases/demo/restore
    {
      "restore_config": {
        "source_database_id": "demo",
        "source_node_name": "n1",
        "source_database_name": "demo",
        "repository": {
          "type": "posix",
          "base_path": "/var/lib/pgedge/backups"
        }
      }
    }

## Assets

- **wait-background.sh** — Spinner that polls `/tmp/.background-done`
  (reuse from Helm killercoda)
- **wait-for-db.sh** — Helper that polls `GET /v1/databases/$1` until
  `state: available` with a spinner, to avoid users manually retrying

## Key Differences from Helm Killercoda

| Aspect | Helm | Control Plane |
|--------|------|---------------|
| Environment | kubernetes-kubeadm-1node-4GB | ubuntu-2204 |
| Setup time | ~2 min | ~30 sec |
| Interaction | kubectl + helm CLI | curl + psql |
| Config format | YAML values files | JSON API payloads |
| Replication | Via CNPG operator + Spock | Via CP API (Spock automatic) |
| Backup/restore | Not covered | Covered (step 6) |
| Read replicas | Covered (step 3) | Skipped (needs multi-host) |

## Open Questions

1. **Backup base_path** — Need to confirm the default posix backup
   path the CP uses. May need to set `backup_config` in the database
   spec before taking a backup.
2. **psql client** — Need to confirm `postgresql-client` package is
   available in `ubuntu-2204` apt repos, or install from pgdg.
3. **Port discovery** — Exact jq path to extract ports from the
   database status response needs verification against real API output.
