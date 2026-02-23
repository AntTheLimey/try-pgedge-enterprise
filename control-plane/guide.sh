#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/helpers.sh
source "$SCRIPT_DIR/../lib/helpers.sh"
setup_trap

CP_PORT="${CP_PORT:-3000}"
CP_URL="http://localhost:${CP_PORT}"

# ── Welcome ──────────────────────────────────────────────────────────────────

header "pgEdge Enterprise -- Get Running Fast"

explain "This guide walks you through the full Control Plane journey:"
explain ""
explain "  1. Start Control Plane"
explain "  2. Deploy a single primary"
explain "  3. Add read replicas & HA"
explain "  4. Go multi-master"
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

prompt_continue

# ── Step 2: Deploy a Single Primary ──────────────────────────────────────────

header "Step 2: Deploy a Single Primary"

explain "Control Plane will pull a pgEdge Enterprise container image, configure"
explain "PostgreSQL, and start it. You'll have a production-ready primary with"
explain "pgBackRest backups already configured."

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s -X POST ${CP_URL}/v1/databases \
    -H 'Content-Type: application/json' \
    -d '{\"name\":\"demo\",\"nodes\":[{\"name\":\"n1\",\"port\":6432}]}' | jq ."

start_spinner "Waiting for database to be ready..."
sleep 5  # Placeholder for real health polling -- replace with actual DB readiness check
stop_spinner

info "PostgreSQL 17 running on port 6432"

prompt_run "psql -h localhost -p 6432 -U admin -d demo -c \"SELECT version();\""

prompt_continue

# ── Step 3: Add Read Replicas & HA ───────────────────────────────────────────

header "Step 3: Add Read Replicas & HA"

explain "Control Plane will add a streaming replica with automatic failover via"
explain "Patroni. If n1 goes down, n2 promotes automatically."

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s -X PATCH ${CP_URL}/v1/databases/demo \
    -H 'Content-Type: application/json' \
    -d '{\"nodes\":[
      {\"name\":\"n1\",\"port\":6432},
      {\"name\":\"n2\",\"port\":6433,\"role\":\"replica\"}
    ]}' | jq ."

start_spinner "Waiting for replica to sync..."
sleep 5  # Placeholder for real sync polling -- replace with actual replication lag check
stop_spinner

info "n2 streaming from n1"

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s ${CP_URL}/v1/databases/demo | jq '.nodes'"

prompt_continue

# ── Step 4: Go Multi-Master ──────────────────────────────────────────────────

header "Step 4: Go Multi-Master"

explain "Control Plane will enable Spock active-active replication across all"
explain "three nodes. Every node accepts writes. Conflict resolution happens"
explain "automatically at the column level."

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s -X PATCH ${CP_URL}/v1/databases/demo \
    -H 'Content-Type: application/json' \
    -d '{\"nodes\":[
      {\"name\":\"n1\",\"port\":6432},
      {\"name\":\"n2\",\"port\":6433},
      {\"name\":\"n3\",\"port\":6434}
    ],\"replication\":\"multi-master\"}' | jq ."

start_spinner "Enabling Spock multi-master replication..."
sleep 5  # Placeholder for real replication health polling -- replace with actual check
stop_spinner

info "n1 <-> n2 <-> n3 (active-active)"

explain ""
explain "Let's prove it works. Write on n1, read on n3:"

prompt_run "psql -h localhost -p 6432 -d demo -c \"CREATE TABLE IF NOT EXISTS test (id int, msg text);\""
prompt_run "psql -h localhost -p 6432 -d demo -c \"INSERT INTO test VALUES (1, 'from n1');\""
prompt_run "psql -h localhost -p 6434 -d demo -c \"SELECT * FROM test;\""

explain "Now write on n3, read on n1:"

prompt_run "psql -h localhost -p 6434 -d demo -c \"INSERT INTO test VALUES (2, 'from n3');\""
prompt_run "psql -h localhost -p 6432 -d demo -c \"SELECT * FROM test;\""

# ── Completion ───────────────────────────────────────────────────────────────

header "Done!"

info "You've gone from a single primary to full multi-master replication,"
info "all orchestrated by Control Plane."
echo ""
explain "What's next:"
explain ""
explain "  Browse packages:       http://localhost:8080  (run: ../package-catalog/serve.sh)"
explain "  Try bare metal:        ../bare-metal/guide.sh"
explain "  Full documentation:    https://docs.pgedge.com/enterprise/"
echo ""
explain "${DIM}To clean up: bash $SCRIPT_DIR/scripts/setup.sh cleanup${RESET}"
echo ""
