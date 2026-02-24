# Prove Replication

Let's verify that active-active replication is working by writing data
on one node and reading it on the other.

## Get the ports

First, grab the port for each node:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
echo "n1: port $N1_PORT  |  n2: port $N2_PORT"
```

## Create a table on n1

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "
CREATE TABLE cities (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  country TEXT NOT NULL
);"
```

## Insert data on n1

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "
INSERT INTO cities (id, name, country) VALUES
  (1, 'New York', 'USA'),
  (2, 'London', 'UK'),
  (3, 'Tokyo', 'Japan');"
```

## Read on n2

These rows were written on n1 but are already replicated to n2:

```bash
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N2_PORT" -U admin demo -c "SELECT * FROM cities;"
```

You should see all 3 cities.

## Write on n2

This is the active-active part — n2 can accept writes too:

```bash
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N2_PORT" -U admin demo -c "
INSERT INTO cities (id, name, country) VALUES
  (4, 'Sydney', 'Australia'),
  (5, 'Berlin', 'Germany');"
```

## Read back on n1

All 5 rows should be here — 3 written locally and 2 replicated
from n2:

```bash
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -c "SELECT * FROM cities ORDER BY id;"
```

**Bidirectional active-active replication confirmed.**

**Next:** Let's protect this data with backup and restore.
