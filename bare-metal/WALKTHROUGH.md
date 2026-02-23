# pgEdge Enterprise -- Explore & Install (Bare Metal)

In this walkthrough you install pgEdge Enterprise Postgres on a Linux
VM, verify the included extensions, and optionally configure Spock
multi-master replication between two nodes.

Click the **Run** button on any code block to execute it directly in
the terminal.

## Prerequisites

- Linux VM (EL 9/10, Debian 11-13, or Ubuntu 22.04/24.04)
- sudo access
- 2+ VMs for the replication step (optional)

## Step 1: Explore What's Available

pgEdge Enterprise Postgres includes 30+ packages across 5 categories:

| Category | Packages |
|----------|----------|
| **Core** | PostgreSQL 17, Spock 5.0, lolor, Snowflake |
| **AI/ML** | pgVector, MCP Server, RAG Server, Vectorizer, Anonymizer, Docloader |
| **Management** | pgAdmin 4, pgBouncer, pgBackRest, ACE, Radar |
| **Extensions** | PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB, pg_hint_plan, PLV8, set_user |
| **HA** | Patroni, etcd |

Two meta-packages simplify installation:

| Meta-Package | RPM Name | DEB Name |
|--------------|----------|----------|
| **Full** (recommended) | `pgedge-enterprise-all_17` | `pgedge-enterprise-all-17` |
| **Minimal** | `pgedge-enterprise-postgres_17` | `pgedge-enterprise-postgres-17` |

## Step 2: Install Enterprise Postgres

The commands below are for **Enterprise Linux 9** (RHEL / Rocky /
Alma). The interactive `guide.sh` script auto-detects your OS and
adjusts commands accordingly.

Install prerequisites:

```bash
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf config-manager --set-enabled crb
```

Add the pgEdge repository:

```bash
sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm
```

Install the full Enterprise Postgres meta-package:

```bash
sudo dnf install -y pgedge-enterprise-all_17
```

Initialize the database and start PostgreSQL:

```bash
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable --now postgresql-17
```

## Step 3: Verify Extensions

Confirm that key extensions are available:

```bash
sudo -u postgres psql -c "SELECT name, default_version, comment
  FROM pg_available_extensions
  WHERE name IN ('spock','vector','postgis','pgaudit')
  ORDER BY name;"
```

These extensions are installed as shared libraries but not yet enabled.
Use `CREATE EXTENSION` in your database when you need them.

## Step 4: Set Up Replication (Optional)

This step requires 2+ VMs with pgEdge Enterprise installed. Replace
the IP placeholders with your actual node addresses.

Configure both nodes for logical replication:

```bash
sudo -u postgres psql -c "ALTER SYSTEM SET wal_level = 'logical';"
sudo -u postgres psql -c "ALTER SYSTEM SET max_worker_processes = 16;"
sudo -u postgres psql -c "ALTER SYSTEM SET max_replication_slots = 16;"
sudo -u postgres psql -c "ALTER SYSTEM SET shared_preload_libraries = 'spock';"
sudo systemctl restart postgresql-17
```

Create the database and enable Spock on both nodes:

```bash
sudo -u postgres createdb demo
sudo -u postgres psql -d demo -c "CREATE EXTENSION spock;"
```

Create the Spock node on node 1 (`NODE1_IP`):

```bash
sudo -u postgres psql -d demo -c "SELECT spock.node_create(
  node_name := 'n1',
  dsn := 'host=NODE1_IP dbname=demo');"
```

Create the Spock node on node 2 (`NODE2_IP`):

```bash
sudo -u postgres psql -d demo -c "SELECT spock.node_create(
  node_name := 'n2',
  dsn := 'host=NODE2_IP dbname=demo');"
```

Create bidirectional subscriptions. On node 1:

```bash
sudo -u postgres psql -d demo -c "SELECT spock.sub_create(
  subscription_name := 'n1_to_n2',
  provider_dsn := 'host=NODE2_IP dbname=demo');"
```

On node 2:

```bash
sudo -u postgres psql -d demo -c "SELECT spock.sub_create(
  subscription_name := 'n2_to_n1',
  provider_dsn := 'host=NODE1_IP dbname=demo');"
```

Verify replication -- insert on node 1, read on node 2:

```bash
sudo -u postgres psql -d demo -c "CREATE TABLE test (id int PRIMARY KEY, msg text);"
sudo -u postgres psql -d demo -c "INSERT INTO test VALUES (1, 'from n1');"
sudo -u postgres psql -h NODE2_IP -d demo -c "SELECT * FROM test;"
```

## What's Next

- **Browse all packages:** Run `../package-catalog/serve.sh` and
  open http://localhost:8080
- **Try Control Plane:** Run `../control-plane/guide.sh`
- **Documentation:** https://docs.pgedge.com/enterprise/

**Started with bare metal?** Add Control Plane to orchestrate what
you already have -- backups, failover, and scaling, all managed
through a single API.
