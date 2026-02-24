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
