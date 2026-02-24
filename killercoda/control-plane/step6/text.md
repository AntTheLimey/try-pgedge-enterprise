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
