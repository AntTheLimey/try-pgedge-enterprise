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
