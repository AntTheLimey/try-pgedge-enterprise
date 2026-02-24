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
