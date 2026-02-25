#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/helpers.sh
source "$SCRIPT_DIR/../lib/helpers.sh"
setup_trap

CP_PORT="${CP_PORT:-3000}"
CP_URL="http://localhost:${CP_PORT}"
DB_ID="example"

# ── Welcome ──────────────────────────────────────────────────────────────────

header "pgEdge Enterprise -- Get Running Fast"

explain "This guide walks you through the Control Plane journey:"
explain ""
explain "  1. Start Control Plane"
explain "  2. Create a distributed database"
explain "  3. Verify multi-master replication"
explain ""
explain "You'll go from zero to active-active replication in minutes."
explain ""
explain "${DIM}Prerequisites: Docker (with host networking)${RESET}"

prompt_continue

# ── Step 1: Start Control Plane ──────────────────────────────────────────────

header "Step 1: Start Control Plane"

explain "Control Plane is a lightweight orchestrator that manages your Postgres"
explain "instances. It runs as a single container and exposes a REST API."

prompt_continue

explain "Setting up Control Plane..."
echo ""
bash "$SCRIPT_DIR/scripts/setup.sh" setup

# Read the auth token
CP_DATA="${CP_DATA:-$HOME/pgedge/control-plane}"
if [[ -f "$CP_DATA/.token" ]]; then
  CP_TOKEN=$(cat "$CP_DATA/.token")
else
  error "Could not find Control Plane auth token."
  exit 1
fi

prompt_continue

# ── Step 2: Create a Distributed Database ────────────────────────────────────

header "Step 2: Create a Distributed Database"

explain "Control Plane uses a declarative model. You describe the database you"
explain "want -- name, users, and nodes -- and CP handles the rest. Spock"
explain "multi-master replication is configured automatically between all nodes."

prompt_run "curl -s -X POST ${CP_URL}/v1/databases \\
    -H 'Authorization: Bearer ${CP_TOKEN}' \\
    -H 'Content-Type: application/json' \\
    --data '{
        \"id\": \"${DB_ID}\",
        \"spec\": {
            \"database_name\": \"${DB_ID}\",
            \"database_users\": [
                {
                    \"username\": \"admin\",
                    \"password\": \"password\",
                    \"db_owner\": true,
                    \"attributes\": [\"SUPERUSER\", \"LOGIN\"]
                }
            ],
            \"nodes\": [
                { \"name\": \"n1\", \"port\": 6432, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n2\", \"port\": 6433, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n3\", \"port\": 6434, \"host_ids\": [\"host-1\"] }
            ]
        }
    }'"

explain "Database creation is asynchronous. Let's poll until it's ready..."
echo ""

start_spinner "Waiting for database to become available..."
retries=60
while [[ "$retries" -gt 0 ]]; do
  state=$(curl -sf -H "Authorization: Bearer ${CP_TOKEN}" "${CP_URL}/v1/databases/${DB_ID}" 2>/dev/null | grep -o '"state":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  if [[ "$state" == "available" ]]; then
    break
  fi
  sleep 3
  retries=$((retries - 1))
done
stop_spinner

if [[ "$state" == "available" ]]; then
  info "Database '${DB_ID}' is available with 3 nodes (n1, n2, n3)"
else
  warn "Database is still being created (state: ${state:-unknown}). You can check progress with:"
  show_cmd "curl -s -H 'Authorization: Bearer ${CP_TOKEN}' ${CP_URL}/v1/databases/${DB_ID} | jq .state"
  prompt_continue
fi

explain ""
explain "Let's check the database status:"

prompt_run "curl -s -H 'Authorization: Bearer ${CP_TOKEN}' ${CP_URL}/v1/databases/${DB_ID} | jq '{state: .state, nodes: [.spec.nodes[].name]}'"

explain ""
explain "Connect to one of the nodes:"

prompt_run "PGPASSWORD=password psql -h localhost -p 6432 -U admin ${DB_ID} -c \"SELECT version();\""

prompt_continue

# ── Step 3: Verify Multi-Master Replication ──────────────────────────────────

header "Step 3: Verify Multi-Master Replication"

explain "All three nodes have Spock bi-directional replication. Every node"
explain "accepts writes and changes propagate automatically."
explain ""
explain "Let's prove it. First, create a table on n1:"

prompt_run "PGPASSWORD=password psql -h localhost -p 6432 -U admin ${DB_ID} -c \"CREATE TABLE example (id int primary key, data text);\""

explain "Insert a row on n2:"

prompt_run "PGPASSWORD=password psql -h localhost -p 6433 -U admin ${DB_ID} -c \"INSERT INTO example (id, data) VALUES (1, 'Hello from n2!');\""

explain "Read it back from n1 -- it should be there via Spock replication:"

prompt_run "PGPASSWORD=password psql -h localhost -p 6432 -U admin ${DB_ID} -c \"SELECT * FROM example;\""

explain "Now write on n3 and read from n1:"

prompt_run "PGPASSWORD=password psql -h localhost -p 6434 -U admin ${DB_ID} -c \"INSERT INTO example (id, data) VALUES (2, 'Hello from n3!');\""

prompt_run "PGPASSWORD=password psql -h localhost -p 6432 -U admin ${DB_ID} -c \"SELECT * FROM example;\""

# ── Completion ───────────────────────────────────────────────────────────────

header "Done!"

info "You've created a 3-node distributed Postgres database with"
info "active-active multi-master replication, all via a single API call."
echo ""
explain "What's next:"
explain ""
explain "  Browse packages:       https://docs.pgedge.com/enterprise/packages"
explain "  Full documentation:    https://docs.pgedge.com/enterprise/"
echo ""
explain "${DIM}To clean up: bash $SCRIPT_DIR/scripts/setup.sh cleanup${RESET}"
echo ""
