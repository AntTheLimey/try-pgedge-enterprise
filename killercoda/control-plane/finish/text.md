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
