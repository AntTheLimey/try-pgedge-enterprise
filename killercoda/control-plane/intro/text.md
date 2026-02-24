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
