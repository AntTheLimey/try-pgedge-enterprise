# try-pgedge-enterprise

The fastest way to experience pgEdge Enterprise Postgres — from package
discovery through single-node installs to multi-master replication.

## Two Paths

### Get Running Fast — Control Plane

pgEdge Control Plane deploys and manages your Postgres. One API takes you from
a single primary through HA to full multi-master.

**Prerequisites:** Docker (with host networking), curl

```bash
# Interactive walkthrough
./guides/guide.sh

# Or follow the step-by-step markdown
# Open guides/WALKTHROUGH.md in VS Code with Runme
```

### Explore & Install — Bare Metal

Browse the full pgEdge Enterprise package catalog. Install on your own Linux
servers using your native package manager.

**Prerequisites:** Linux VM (EL 9/10, Debian 11-13, Ubuntu 22.04/24.04), sudo

```bash
# Interactive walkthrough
./bare-metal/guide.sh

# Or follow the step-by-step markdown
# Open bare-metal/WALKTHROUGH.md in VS Code with Runme
```

## Package Catalog

Browse all 30+ packages interactively. Pick your platform, copy the install
commands.

```bash
# Serve locally
./package-catalog/serve.sh
# Open http://localhost:8080
```

## What's Included

| Category | Packages |
|---|---|
| **Core** | PostgreSQL 17, Spock 5.0, lolor, Snowflake |
| **AI & ML** | pgVector, MCP Server, RAG Server, Vectorizer, Anonymizer, Docloader |
| **Management** | pgAdmin 4, pgBouncer, pgBackRest, ACE, Radar |
| **Extensions** | PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB, pg_hint_plan, PLV8, set_user |
| **HA** | Patroni, etcd |

## Links

- [pgEdge Documentation](https://docs.pgedge.com/enterprise/)
- [pgEdge GitHub](https://github.com/pgEdge)
- [pgedge.com](https://pgedge.com)
