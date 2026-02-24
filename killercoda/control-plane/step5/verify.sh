#!/bin/bash
# Verify data replicated to both nodes (5 rows each)
N1_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n1") | .connection_info.port')
N2_PORT=$(curl -s http://localhost:3000/v1/databases/demo | jq -r '.instances[] | select(.node_name=="n2") | .connection_info.port')
PGPASSWORD=secret psql -h localhost -p "$N1_PORT" -U admin demo -tAc "SELECT count(*) FROM cities;" 2>/dev/null | grep -q "5" && \
PGPASSWORD=secret psql -h localhost -p "$N2_PORT" -U admin demo -tAc "SELECT count(*) FROM cities;" 2>/dev/null | grep -q "5"
