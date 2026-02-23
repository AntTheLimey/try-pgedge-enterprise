# pgEdge Enterprise Quickstart — Design Document

**Date:** 2026-02-23
**Status:** Draft
**Project:** try-pgedge-enterprise (new repo)

---

## Problem Statement

pgEdge Enterprise has a rich ecosystem — a package repository with 30+ components
(PostgreSQL, Spock, pgVector, PostGIS, pgAdmin, pgBackRest, AI toolkit, and more)
plus Control Plane for orchestrating Postgres instances from single primary through
HA to multi-master. But there is no coherent, low-friction way for evaluators to
discover and experience it.

Today's pain points:

- **Control Plane quickstart** requires crafting raw cURL/JSON commands, uses Docker
  Swarm (unusual for a quickstart), and jumps straight to 3-node replication with
  no graduated journey.
- **Enterprise package quickstart** has a 6-variant OS prerequisite matrix that
  creates cognitive overload, only gets you to a single running node, and provides
  no path to replication.
- **The deprecated Distributed CLI** was the only tool that bridged single-node
  installs to multi-master replication. With it gone, there is no guided bare-metal
  replication experience.
- **Package discovery is nonexistent.** Evaluators cannot see what's available in
  the repo without installing the repo config and running `dnf repoquery`.
- **No connection between the two worlds.** Control Plane uses container images;
  the package repo serves bare-metal VMs. An evaluator encountering both has no
  mental model for how they relate.

## Goals

1. Create a low-friction quickstart for Control Plane that demonstrates the full
   journey: single primary → HA / read replicas → multi-master.
2. Make the pgEdge package ecosystem discoverable through an interactive web-based
   catalog page (postgresql.org style).
3. Provide a guided bare-metal walkthrough for users with existing Linux VMs.
4. Update the ant-dev-experience prototype to reflect both paths with clear,
   outcome-based framing.

## Non-Goals

- Building a CLI wrapper around apt/dnf (feedback: "don't reinvent apt/dnf").
- Building a local GUI application for package management.
- Designing for Phase 2 (Control Plane SystemD support) beyond acknowledging it
  exists. Phase 1 must stand on its own.
- Supporting the deprecated Distributed CLI.

## Target Audience

1. **Primary: Evaluators** — someone researching pgEdge who wants to see the full
   breadth of the ecosystem and understand what pgEdge offers before committing.
2. **Secondary: New users** — someone ready to install pgEdge Enterprise and
   wanting a fast, clear path to a running instance.

## Competitive Context

Research across CrunchyData, EnterpriseDB, Neon, and Percona revealed:

| Dimension | Best-in-class | Gap pgEdge can fill |
|---|---|---|
| Package discovery UI | Neon Extension Explorer (19 categories) | Nobody has an interactive command generator + catalog combined |
| CLI repo management | Percona `percona-release` meta-tool | N/A (boss: don't reinvent apt/dnf) |
| Graduated tutorial | CrunchyData PGO (14-step progression) | Nobody does single → HA → multi-master in one guided flow |
| Web package browser | EDB Repos 2.0 (gated behind Enterprise sub) | An open, ungated catalog page |
| Interactive command generator | postgresql.org download page | Absorbs OS-variant complexity into dropdowns |

---

## Architecture

### New Repository: `try-pgedge-enterprise`

```
try-pgedge-enterprise/
├── README.md                          # Landing page with both paths
│
├── control-plane/                     # "Get Running Fast" path
│   ├── guide.sh                       # Interactive walkthrough
│   ├── WALKTHROUGH.md                 # Runme-compatible steps
│   └── scripts/
│       └── setup.sh                   # Bootstrap CP, configure, health checks
│
├── package-catalog/                   # Interactive web page
│   ├── index.html                     # Single-page app (vanilla JS, no framework)
│   ├── catalog.json                   # Package metadata: names, categories,
│   │                                  #   descriptions, PG versions, install cmds
│   └── serve.sh                       # python3 -m http.server 8080
│
├── bare-metal/                        # "Explore & Install" path
│   ├── guide.sh                       # Interactive walkthrough
│   ├── WALKTHROUGH.md                 # Runme-compatible steps
│   └── scripts/
│       └── setup-replication.sh       # Manual Spock replication setup helper
│
├── vagrant/                           # Stretch goal: VM provisioning
│   └── Vagrantfile                    # Spins up 1-3 RHEL/Alma VMs locally
│
└── docs/
    └── plans/
        └── 2026-02-23-enterprise-quickstart-design.md  (this file)
```

### Two Paths, One Repo

The repo serves two complementary quickstart paths for pgEdge Enterprise:

- **"Get Running Fast"** — Control Plane orchestrates everything (containers today).
- **"Explore & Install"** — Browse the package catalog, install on bare-metal VMs.

These are honest, separate experiences. Control Plane uses container images from
the GitHub image repo. The package repo serves RPM/DEB packages for bare-metal.
They are two different deployment models for the same ecosystem.

The bridge between them is messaging, not technology: after completing the
bare-metal walkthrough, users see *"Started with bare metal? Add Control Plane
to orchestrate what you already have."*

---

## Deliverable 1: Control Plane Quickstart

**Location:** `control-plane/`
**Prerequisites:** Docker (with host networking enabled), curl
**Delivery:** Interactive `guide.sh` (like try-pgedge-helm), Runme-compatible
`WALKTHROUGH.md`, curl-pipe `install.sh` for local use.

### Journey (4 Steps)

**Step 1: Start Control Plane**

```bash
$ docker swarm init
$ docker run -d --name pgedge-cp \
    --network host \
    -v ~/pgedge/control-plane:/data \
    pgedge/control-plane:latest
$ curl http://localhost:3000/v1/cluster/init
✓ Control Plane running on localhost:3000
```

*What's happening: Control Plane is a lightweight orchestrator that manages your
Postgres instances. It runs as a single container and exposes a REST API for all
operations.*

**Step 2: Deploy a Single Primary**

```bash
$ curl -X POST http://localhost:3000/v1/databases \
    -d '{"name":"demo","nodes":[{"name":"n1","port":6432}]}'
  ⠋ Creating database...
✓ PostgreSQL 17 running on port 6432

$ psql -h localhost -p 6432 -U admin -d demo \
    -c "SELECT version();"
  PostgreSQL 17.2 (pgEdge Enterprise)
```

*What's happening: Control Plane pulled a pgEdge Enterprise container image,
configured PostgreSQL, and started it. You have a production-ready single primary
with pgBackRest backups already configured.*

**Step 3: Add Read Replicas & HA**

```bash
$ curl -X PATCH http://localhost:3000/v1/databases/demo \
    -d '{"nodes":[
      {"name":"n1","port":6432},
      {"name":"n2","port":6433,"role":"replica"}
    ]}'
  ⠋ Adding replica...
✓ n2 streaming from n1 (lag: 0ms)

$ curl http://localhost:3000/v1/databases/demo | jq '.nodes'
  n1: primary  | port 6432 | healthy
  n2: replica  | port 6433 | healthy | lag: 0ms
```

*What's happening: Control Plane added a streaming replica with automatic failover
via Patroni. If n1 goes down, n2 promotes automatically. pgBackRest handles backup
coordination across both nodes.*

**Step 4: Go Multi-Master**

```bash
$ curl -X PATCH http://localhost:3000/v1/databases/demo \
    -d '{"nodes":[
      {"name":"n1","port":6432},
      {"name":"n2","port":6433},
      {"name":"n3","port":6434}
    ],"replication":"multi-master"}'
  ⠋ Enabling Spock multi-master replication...
✓ n1 ←→ n2 ←→ n3 (active-active)

# Write on n1, read on n3:
$ psql -p 6432 -d demo -c "INSERT INTO test VALUES (1, 'from n1');"
$ psql -p 6434 -d demo -c "SELECT * FROM test;"
  1 | from n1  ← replicated

# Write on n3, read on n1:
$ psql -p 6434 -d demo -c "INSERT INTO test VALUES (2, 'from n3');"
$ psql -p 6432 -d demo -c "SELECT * FROM test;"
  1 | from n1
  2 | from n3  ← replicated back
```

*What's happening: Control Plane enabled Spock active-active replication across
all three nodes. Every node accepts writes. Conflict resolution happens
automatically at the column level.*

### Caveats

The API calls shown above are based on the current Control Plane quickstart
documentation. The exact API shape — especially the PATCH for adding nodes and
the `"replication":"multi-master"` parameter — must be validated against the
actual Control Plane v0.6 API. The guide.sh script will be built against the
real API; these examples illustrate the intended user experience.

### guide.sh Patterns

Follows conventions established in try-pgedge-helm:

- `set -euo pipefail`, trap handlers for cleanup
- Colored output: `header()`, `info()`, `warn()`, `explain()`, `prompt_run()`
- Spinner animations for long-running operations (DB creation, replica sync)
- `read -rp "Press Enter to continue..."` for pacing
- Idempotent: detects existing CP containers and skips setup if present
- Completion message with links to docs and the "Explore & Install" path

---

## Deliverable 2: Package Catalog Page

**Location:** `package-catalog/`
**Format:** Single HTML file + `catalog.json`, vanilla JS, no build step.
**Serves at:** `localhost:8080` via `serve.sh` (or any static file server).
**Future home:** pgedge.com (migrated when ready).

### Three Zones

**Zone 1: Interactive Selector (top)**

Four dropdowns that dynamically regenerate the install commands:

| Dropdown | Options |
|---|---|
| Platform | Enterprise Linux (RHEL/Rocky/Alma), Debian, Ubuntu |
| OS Version | 9, 10 (EL) / 11, 12, 13 (Debian) / 22.04, 24.04 (Ubuntu) |
| Architecture | x86_64, arm64 |
| PG Version | 17, 16, 18 |

Defaults to EL 9 / x86_64 / PG 17 (most common).

**Zone 2: Generated Install Commands (middle)**

Adapts based on selector values. The page absorbs the OS-variant prerequisite
matrix so the user never sees branching. Example for EL 9 / x86_64 / PG 17:

```bash
# 1. Configure prerequisites
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf config-manager --set-enabled crb

# 2. Add pgEdge repository
sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm

# 3. Install pgEdge Enterprise Postgres 17 (full)
sudo dnf install -y pgedge-enterprise-all_17

# 4. Initialize and start
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable --now postgresql-17
```

Includes a [Copy All] button.

**Zone 3: Browsable Package Catalog (bottom)**

Categorized, expandable tree rendered from `catalog.json`. Each entry shows
package name, description, and PG version compatibility. Clicking a package
reveals the individual install command.

Categories:

| Category | Packages |
|---|---|
| **Core** | PostgreSQL, Spock 5.0, lolor, Snowflake |
| **AI & Machine Learning** | pgVector, MCP Server, RAG Server, Vectorizer, Anonymizer, Docloader |
| **Management Tools** | pgAdmin 4, pgBouncer, pgBackRest, ACE, Radar |
| **Extensions** | PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB, pg_hint_plan, PLV8, set_user, ... |
| **High Availability** | Patroni, etcd |

The catalog also notes the two meta-packages:

| Meta-Package | RPM | DEB | Contents |
|---|---|---|---|
| **Full** (recommended) | `pgedge-enterprise-all_17` | `pgedge-enterprise-all-17` | Everything: PG + Spock + all extensions + pgAdmin + pgBouncer + pgBackRest |
| **Minimal** | `pgedge-enterprise-postgres_17` | `pgedge-enterprise-postgres-17` | Core: PG + Spock + lolor + Snowflake + pgAudit + PostGIS + pgVector + PL languages |

### catalog.json Structure

```json
{
  "meta_packages": [
    {
      "id": "full",
      "label": "Enterprise All (Recommended)",
      "description": "Complete pgEdge Enterprise stack",
      "rpm_pattern": "pgedge-enterprise-all_{ver}",
      "deb_pattern": "pgedge-enterprise-all-{ver}",
      "pg_versions": ["16", "17", "18"]
    },
    {
      "id": "minimal",
      "label": "Enterprise Postgres (Minimal)",
      "description": "Core database with replication extensions",
      "rpm_pattern": "pgedge-enterprise-postgres_{ver}",
      "deb_pattern": "pgedge-enterprise-postgres-{ver}",
      "pg_versions": ["16", "17", "18"]
    }
  ],
  "categories": [
    {
      "name": "Core",
      "packages": [
        {
          "name": "PostgreSQL",
          "description": "pgEdge-patched PostgreSQL database engine",
          "pg_versions": ["15", "16", "17", "18"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "Spock 5.0",
          "description": "Multi-master active-active logical replication",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        }
      ]
    }
  ],
  "platforms": {
    "el9": {
      "label": "Enterprise Linux 9 (RHEL / Rocky / Alma)",
      "pkg_manager": "dnf",
      "prerequisites": [
        "sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm",
        "sudo dnf config-manager --set-enabled crb"
      ],
      "repo_install": "sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm",
      "install_pattern": "sudo dnf install -y {package}",
      "init_pattern": "sudo /usr/pgsql-{ver}/bin/postgresql-{ver}-setup initdb",
      "start_pattern": "sudo systemctl enable --now postgresql-{ver}"
    },
    "debian12": {
      "label": "Debian 12 (Bookworm)",
      "pkg_manager": "apt",
      "prerequisites": [],
      "repo_install": "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update",
      "install_pattern": "sudo apt-get install -y {package}",
      "init_pattern": "sudo pg_ctlcluster {ver} main start",
      "start_pattern": "sudo systemctl enable --now postgresql"
    }
  }
}
```

### Design Principles

- **Single HTML file, vanilla JS.** No React, no build step, no node_modules.
  This makes it trivially portable to any CMS or static host when it migrates
  to pgedge.com.
- **`catalog.json` is the source of truth.** The HTML reads from it. When
  packages change, update the JSON — the page adapts automatically.
- **Absorbs complexity.** The per-OS prerequisite matrix, the RPM/DEB naming
  differences, the PG version suffixes — all handled by the page. The user
  just picks from dropdowns and copies commands.

---

## Deliverable 3: Bare Metal Walkthrough

**Location:** `bare-metal/`
**Prerequisites:** 1-3 Linux VMs (EL 9/10, Debian 11/12/13, Ubuntu 22.04/24.04),
SSH access, sudo.
**Delivery:** Interactive `guide.sh`, Runme-compatible `WALKTHROUGH.md`.

### Journey (4 Steps)

**Step 1: Explore What's Available**

Opens the package catalog page if running locally, or prints a categorized
summary to the terminal:

```
pgEdge Enterprise Postgres includes 30+ packages across 5 categories:

  Core:        PostgreSQL 17, Spock 5.0, lolor, Snowflake
  AI/ML:       pgVector, MCP Server, RAG Server, Vectorizer
  Management:  pgAdmin, pgBouncer, pgBackRest, ACE, Radar
  Extensions:  PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB...
  HA:          Patroni, etcd

[Press Enter to continue]
```

**Step 2: Install Enterprise Postgres**

The script detects the OS from `/etc/os-release` and runs the correct commands
automatically. The user never sees the branching matrix.

```bash
Detected: AlmaLinux 9 (x86_64)

$ sudo dnf install -y https://dl.fedoraproject.org/.../epel-release-latest-9.noarch.rpm
$ sudo dnf config-manager --set-enabled crb
$ sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm
$ sudo dnf install -y pgedge-enterprise-all_17
✓ pgEdge Enterprise Postgres 17 installed

$ sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
$ sudo systemctl enable --now postgresql-17
✓ PostgreSQL 17 running on port 5432

$ psql -c "SELECT version();"
  PostgreSQL 17.2 (pgEdge Enterprise)
```

*What's happening: You now have a production-grade PostgreSQL with Spock,
pgBackRest, pgBouncer, pgAdmin, and all extensions pre-installed. Everything
came from the pgEdge package repo via your native package manager.*

**Step 3: Verify Extensions**

```bash
$ psql -c "SELECT name, default_version, comment
           FROM pg_available_extensions
           WHERE name IN ('spock','vector','postgis','pgaudit')
           ORDER BY name;"

  name    | version | comment
 ---------+---------+----------------------------------
  pgaudit | 17.0    | Audit logging
  postgis | 3.5.4   | PostGIS geometry and geography
  spock   | 5.0.5   | Multi-master logical replication
  vector  | 0.8.1   | Vector similarity search
```

*What's happening: These extensions are installed as shared libraries but not
yet enabled in your database. Enable them with `CREATE EXTENSION` when needed.*

**Step 4: Set Up Replication (Optional — requires 2+ VMs)**

The script asks if the user has multiple VMs. If not, the experience is complete
at step 3. If yes, the script walks through manual Spock configuration:

```bash
Node 1 (this machine): 192.168.1.10
Node 2: _____________ [user enters IP]

# Configure both nodes for logical replication:
$ sudo -u postgres psql -c "
  ALTER SYSTEM SET wal_level = 'logical';
  ALTER SYSTEM SET max_worker_processes = 16;
  ALTER SYSTEM SET max_replication_slots = 16;
  ALTER SYSTEM SET shared_preload_libraries = 'spock';"
$ sudo systemctl restart postgresql-17

# Enable Spock on both nodes:
$ psql -d demo -c "CREATE EXTENSION spock;"

# Create nodes:
$ psql -d demo -c "SELECT spock.node_create(
    node_name := 'n1',
    dsn := 'host=192.168.1.10 dbname=demo');"

# Create bidirectional subscriptions:
$ psql -h 192.168.1.10 -d demo -c "SELECT spock.sub_create(
    subscription_name := 'n1_to_n2',
    provider_dsn := 'host=192.168.1.11 dbname=demo');"
$ psql -h 192.168.1.11 -d demo -c "SELECT spock.sub_create(
    subscription_name := 'n2_to_n1',
    provider_dsn := 'host=192.168.1.10 dbname=demo');"

# Verify:
$ psql -h 192.168.1.10 -d demo -c "INSERT INTO test VALUES (1, 'from n1');"
$ psql -h 192.168.1.11 -d demo -c "SELECT * FROM test;"
  1 | from n1  ← replicated
```

*What's happening: You've manually configured Spock active-active replication.
Each node accepts writes and replicates to the other.*

### Completion Message

```
You've installed pgEdge Enterprise Postgres and configured multi-master
replication from scratch.

Started with bare metal? Add Control Plane to orchestrate what you already
have — backups, failover, and scaling, all managed through a single API.

  → Try Control Plane: ./control-plane/guide.sh
  → Browse all packages: http://localhost:8080
  → Full documentation: https://docs.pgedge.com/enterprise/
```

### Caveats

The Spock SQL commands (`spock.node_create`, `spock.sub_create`) must be
validated against the Spock 5.0 API. Function signatures, required parameters,
and `pg_hba.conf` configuration for cross-node authentication need to be
verified during implementation.

---

## Deliverable 4: Prototype Updates (ant-dev-experience)

### Changes to EnterprisePostgresSection.tsx

**Current state:** 4-step linear journey using deprecated `pgedge` CLI commands
(`pgedge setup`, `pgedge add-node`, `pgedge spock enable`, `pgedge cluster-status`).
None of these commands exist in the current product.

**New state:** Mode toggle with two paths, following the same pattern as
`ContainersSection.tsx` (which has a single-region / multi-region toggle).

### Toggle Framing (Outcome-Based)

```
[ Get Running Fast ]  |  [ Explore & Install ]
```

**"Get Running Fast" description:**
*pgEdge Control Plane deploys and manages your Postgres — from a single primary
through HA to full multi-master. One API, zero manual configuration.*

**"Explore & Install" description:**
*Browse the full pgEdge Enterprise package catalog. Install components on your
own Linux servers exactly how you want them.*

"Control Plane" appears naturally in the description, not the toggle label. By
the time the user reads it, they already know what it does.

### Terminal Animation Content

**"Get Running Fast" path (4 steps):**

| Step | Icon | Terminal Content |
|---|---|---|
| Deploy | Database | `docker run pgedge/control-plane` + `curl /v1/cluster/init` |
| Primary | Server | `curl POST /v1/databases` → PostgreSQL running + `psql SELECT version()` |
| Replicate | Copy | `curl PATCH` (add replica) → cluster status showing primary + replica |
| Distribute | GitBranch | `curl PATCH` (multi-master) → write on n1, read on n3, write on n3, read on n1 |

**"Explore & Install" path (4 steps):**

| Step | Icon | Terminal Content |
|---|---|---|
| Explore | Search | Categorized package listing (Core, AI/ML, Tools, Extensions, HA) |
| Install | Download | `dnf install pgedge-enterprise-all_17` + `systemctl enable` + `psql SELECT version()` |
| Verify | CheckCircle | `SELECT * FROM pg_available_extensions` showing Spock, pgVector, PostGIS, pgAudit |
| Replicate | GitBranch | Spock `node_create` + `sub_create` + write/read verification across nodes |

### Explainer Cards

Each step has a "What's happening" card on the right side (existing pattern).
Content follows the descriptions in Deliverables 1 and 3.

### Completion Box

```
Ready to try it yourself?

[Try in Browser →]  [Run Locally →]  [Browse Packages →]
```

- **Try in Browser** → GitHub Codespace for try-pgedge-enterprise
- **Run Locally** → curl-pipe install link
- **Browse Packages** → Package catalog page (in-repo URL for now, pgedge.com later)

For the "Explore & Install" path, an additional CTA:

*Started with bare metal? Add Control Plane to orchestrate what you already
have.* → switches to the "Get Running Fast" toggle.

### Code Changes Required

| File | Change |
|---|---|
| `EnterprisePostgresSection.tsx` | Rewrite with mode toggle (follow ContainersSection.tsx pattern) |
| Step data objects (`STEP_LINES`, `STEP_EXPLAINERS`, `STEP_META`) | Two sets of data, one per path |
| Completion box | Add "Browse Packages" CTA, add CP bridge message for bare-metal path |

---

## Stretch Goal: Vagrant VM Provisioning

**Location:** `vagrant/`
**Priority:** Secondary. Droppable if it becomes complicated.

A Vagrantfile that provisions 1-3 AlmaLinux 9 VMs locally with:
- pgEdge repo pre-configured
- `pgedge-enterprise-all_17` pre-installed
- PostgreSQL initialized and running

This gives evaluators without existing VMs a way to try the bare-metal path.
The bare-metal `guide.sh` can detect if it's running inside a Vagrant VM and
skip the install steps.

---

## Phase 2: SystemD Support (Future)

Control Plane is adding SystemD support, which will allow it to manage
bare-metal package installs instead of only container images. When this ships,
the two paths converge: Control Plane can orchestrate instances installed from
the package repo.

Phase 1 does not design for this. The bridge between the two paths is messaging
("Started with bare metal? Add Control Plane to orchestrate what you already
have."), not technology. Phase 2 changes will be designed when SystemD support
is ready.

---

## Delivery Format Summary

| Deliverable | Primary Entry | Fallback Entry |
|---|---|---|
| Control Plane Quickstart | User brings Docker host + `guide.sh` | Codespace (Docker-in-Docker) |
| Package Catalog Page | `localhost:8080` via `serve.sh` | Eventually pgedge.com |
| Bare Metal Walkthrough | User brings Linux VM(s) + `guide.sh` | Vagrant (stretch) |
| Prototype Updates | ant-dev-experience repo | N/A |

## Meta-Packages

All quickstarts use the **full** meta-package:

| Variant | RPM | DEB | Use Case |
|---|---|---|---|
| **Full (recommended)** | `pgedge-enterprise-all_17` | `pgedge-enterprise-all-17` | Quickstarts, evaluations, most deployments |
| **Minimal** | `pgedge-enterprise-postgres_17` | `pgedge-enterprise-postgres-17` | Production deploys wanting fine-grained control |

The full meta-package includes everything in minimal plus pgAdmin 4, pgBouncer,
and pgBackRest. For a quickstart, the "one command, everything installed" moment
is more valuable than saving disk space.

## Open Questions

1. **Control Plane API shape.** The exact endpoints and JSON payloads for
   creating databases, adding nodes, and enabling multi-master need to be
   validated against the real CP v0.6 API. The design illustrates intended UX;
   implementation will match the actual API.

2. **Spock 5.0 SQL API.** The `spock.node_create` and `spock.sub_create`
   function signatures, plus required `pg_hba.conf` and `postgresql.conf`
   settings, need verification against Spock 5.0 docs.

3. **Codespace support for Control Plane.** The CP quickstart requires Docker
   with host networking. Docker-in-Docker in Codespaces may or may not support
   host networking mode. Needs testing.

4. **Package catalog completeness.** The `catalog.json` needs to be populated
   from the actual repo contents. Some packages (especially newer AI toolkit
   components) may not be in the dnf/apt repo yet — they may only be available
   as standalone downloads or Docker images.
