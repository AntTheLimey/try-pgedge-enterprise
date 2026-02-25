#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/helpers.sh
source "$SCRIPT_DIR/../lib/helpers.sh"
setup_trap

CP_IMAGE="${CP_IMAGE:-ghcr.io/pgedge/control-plane}"
CP_CONTAINER="host-1"
CP_PORT="${CP_PORT:-3000}"
CP_URL="http://localhost:${CP_PORT}"
CP_DATA="${CP_DATA:-$HOME/pgedge/control-plane}"
DB_ID="example"

# ── Prerequisites ────────────────────────────────────────────────────────────

if ! command -v docker &>/dev/null; then
  header "pgEdge Enterprise -- Get Running Fast"
  warn "Docker is required but not installed."
  echo ""
  explain "Install Docker, then re-run the guide:"
  echo ""
  explain "  ${DIM}curl -fsSL https://get.docker.com | sudo sh${RESET}"
  explain "  ${DIM}sudo usermod -aG docker \$USER${RESET}"
  explain "  ${DIM}# Log out and back in, then:${RESET}"
  explain "  ${DIM}curl -sSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main/control-plane/run.sh | bash${RESET}"
  echo ""
  exit 0
fi

if ! docker info &>/dev/null; then
  header "pgEdge Enterprise -- Get Running Fast"
  error "Docker daemon is not running. Please start Docker and try again."
  exit 1
fi

# ── Port detection ───────────────────────────────────────────────────────────

port_in_use() {
  ss -tln 2>/dev/null | grep -q ":${1} " && return 0
  return 1
}

detect_ports() {
  local preferred=(5432 5433 5434)
  local all_free=true

  for p in "${preferred[@]}"; do
    if port_in_use "$p"; then
      all_free=false
      break
    fi
  done

  if [[ "$all_free" == "true" ]]; then
    N1_PORT=5432
    N2_PORT=5433
    N3_PORT=5434
    return
  fi

  # Find 3 consecutive free ports starting from 5432
  local start=5432
  while true; do
    local p1="$start"
    local p2=$((start + 1))
    local p3=$((start + 2))
    if ! port_in_use "$p1" && ! port_in_use "$p2" && ! port_in_use "$p3"; then
      N1_PORT="$p1"
      N2_PORT="$p2"
      N3_PORT="$p3"
      break
    fi
    start=$((start + 1))
  done

  warn "Standard Postgres ports (5432-5434) are in use."
  explain "Using available ports instead: ${BOLD}${N1_PORT}, ${N2_PORT}, ${N3_PORT}${RESET}"
  echo ""
}

# ── Welcome ──────────────────────────────────────────────────────────────────

header "pgEdge Enterprise -- Get Running Fast"

explain "This guide walks you through the Control Plane journey:"
explain ""
explain "  1. Start Control Plane"
explain "  2. Create a distributed database"
explain "  3. Verify multi-master replication"
explain ""
explain "You'll go from zero to active-active replication in minutes."

prompt_continue

# ── Step 1: Start Control Plane ──────────────────────────────────────────────

header "Step 1: Start Control Plane"

explain "Control Plane is a lightweight orchestrator that manages your Postgres"
explain "instances. It runs as a single container and exposes a REST API."

detect_ports

# Remove stale container from a previous run
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
  if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
    info "Removing stale container from a previous run..."
    docker rm -f "${CP_CONTAINER}" >/dev/null 2>&1 || true
  fi
fi

# Check if already running
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
  info "Control Plane is already running (container: ${CP_CONTAINER})"
else
  # Initialize Docker Swarm if needed
  if [[ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)" != "active" ]]; then
    info "Initializing Docker Swarm..."
    local_addr=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
    if [[ -n "$local_addr" ]]; then
      if ! docker swarm init --advertise-addr "$local_addr" >/dev/null 2>&1; then
        error "Failed to initialize Docker Swarm. Try manually: docker swarm init --advertise-addr $local_addr"
        exit 1
      fi
    else
      if ! docker swarm init >/dev/null 2>&1; then
        error "Failed to initialize Docker Swarm. Try manually: docker swarm init"
        exit 1
      fi
    fi
  fi

  # Pull and start Control Plane
  mkdir -p "$CP_DATA"

  start_spinner "Pulling Control Plane image..."
  docker pull "$CP_IMAGE" >/dev/null 2>&1
  stop_spinner
  info "Image pulled: $CP_IMAGE"

  start_spinner "Starting Control Plane..."
  docker run --detach \
    --env PGEDGE_HOST_ID="${CP_CONTAINER}" \
    --env PGEDGE_DATA_DIR="${CP_DATA}" \
    --volume "${CP_DATA}":"${CP_DATA}" \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --network host \
    --name "${CP_CONTAINER}" \
    "$CP_IMAGE" \
    run >/dev/null 2>&1
  stop_spinner
  info "Container started: $CP_CONTAINER"

  # Wait for API
  start_spinner "Waiting for Control Plane API..."
  retries=30
  while [[ "$retries" -gt 0 ]]; do
    if curl -sf "http://localhost:${CP_PORT}/v1/version" >/dev/null 2>&1; then
      break
    fi
    sleep 2
    retries=$((retries - 1))
  done
  stop_spinner

  if [[ "$retries" -eq 0 ]]; then
    error "Control Plane did not become healthy within 60 seconds."
    exit 1
  fi
  info "Control Plane running on ${CP_URL}"
fi

# Initialize cluster and get auth token
init_response=$(curl -sf "${CP_URL}/v1/cluster/init" 2>/dev/null || true)
if [[ -z "$init_response" ]]; then
  error "Failed to initialize cluster."
  exit 1
fi
CP_TOKEN=$(echo "$init_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [[ -z "$CP_TOKEN" ]]; then
  error "Failed to retrieve auth token from cluster init."
  exit 1
fi
info "Cluster initialized."

prompt_continue

# ── Step 2: Create a Distributed Database ────────────────────────────────────

header "Step 2: Create a Distributed Database"

explain "Control Plane uses a declarative model. You describe the database you"
explain "want -- name, users, and nodes -- and CP handles the rest. Spock"
explain "multi-master replication is configured automatically between all nodes."
echo ""
explain "This will create a 3-node database. It takes a minute or two while CP"
explain "pulls the Postgres image and starts each node."
echo ""
explain "${DIM}Tip: open a second terminal and run 'watch docker ps' to see containers spin up${RESET}"

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
                { \"name\": \"n1\", \"port\": ${N1_PORT}, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n2\", \"port\": ${N2_PORT}, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n3\", \"port\": ${N3_PORT}, \"host_ids\": [\"host-1\"] }
            ]
        }
    }'"

explain "The API returned a task confirming the database is being created."
explain "CP is now pulling the Postgres image and starting 3 nodes."
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

# Helper: find a node's container name by node name (e.g. "n1")
node_container() {
  docker ps --format '{{.Names}}' | grep "postgres-${DB_ID}-${1}-" | head -1
}

explain ""
explain "Let's connect to n1 using psql inside the container:"

prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n1-) psql -U admin ${DB_ID} -c \"SELECT version();\""

prompt_continue

# ── Step 3: Verify Multi-Master Replication ──────────────────────────────────

header "Step 3: Verify Multi-Master Replication"

explain "All three nodes have Spock bi-directional replication. Every node"
explain "accepts writes and changes propagate automatically."
explain ""
explain "Let's prove it. First, create a table on n1:"

prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n1-) psql -U admin ${DB_ID} -c \"CREATE TABLE example (id int primary key, data text);\""

explain "Insert a row on n2:"

prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n2-) psql -U admin ${DB_ID} -c \"INSERT INTO example (id, data) VALUES (1, 'Hello from n2!');\""

explain "Read it back from n1 -- it should be there via Spock replication:"

prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n1-) psql -U admin ${DB_ID} -c \"SELECT * FROM example;\""

explain "Now write on n3 and read from n1:"

prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n3-) psql -U admin ${DB_ID} -c \"INSERT INTO example (id, data) VALUES (2, 'Hello from n3!');\""

prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n1-) psql -U admin ${DB_ID} -c \"SELECT * FROM example;\""

# ── Step 4: Scale Out (Optional) ─────────────────────────────────────────────

header "Step 4: Scale Out (Optional)"

explain "Control Plane makes it easy to add nodes to a running database."
explain "One API call adds a 4th node, and CP automatically replicates all"
explain "existing data to it."
echo ""

read -rp "  Try it? (Y/n) " TRY_SCALE </dev/tty
echo ""

if [[ "${TRY_SCALE,,}" != "n"* ]]; then
  # Pick a free port for n4
  N4_PORT=$((N3_PORT + 1))
  while port_in_use "$N4_PORT"; do
    N4_PORT=$((N4_PORT + 1))
  done

  explain "Adding node n4 on port ${N4_PORT}. This sends the full database spec"
  explain "with the new node included -- CP handles the rest."

  prompt_run "curl -s -X POST ${CP_URL}/v1/databases/${DB_ID} \\
    -H 'Authorization: Bearer ${CP_TOKEN}' \\
    -H 'Content-Type: application/json' \\
    --data '{
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
                { \"name\": \"n1\", \"port\": ${N1_PORT}, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n2\", \"port\": ${N2_PORT}, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n3\", \"port\": ${N3_PORT}, \"host_ids\": [\"host-1\"] },
                { \"name\": \"n4\", \"port\": ${N4_PORT}, \"host_ids\": [\"host-1\"], \"source_node\": \"n1\" }
            ]
        }
    }'"

  explain "Waiting for n4 to come up..."
  echo ""

  start_spinner "Waiting for n4 to become available..."
  retries=60
  n4_ready=false
  while [[ "$retries" -gt 0 ]]; do
    if docker ps --format '{{.Names}}' | grep -q "postgres-${DB_ID}-n4-"; then
      n4_ready=true
      break
    fi
    sleep 3
    retries=$((retries - 1))
  done
  stop_spinner

  if [[ "$n4_ready" == "true" ]]; then
    info "Node n4 is running."
    echo ""
    explain "Let's check -- the data we inserted earlier should already be on n4:"

    prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n4-) psql -U admin ${DB_ID} -c \"SELECT * FROM example;\""
  else
    warn "n4 is still starting. Check 'docker ps' to monitor progress."
  fi
fi

# ── Step 5: Resilience (Optional) ────────────────────────────────────────────

header "Step 5: Resilience (Optional)"

explain "Active-active means every node accepts reads and writes. If a node"
explain "goes down, the others keep working. Let's prove it by killing n2."
echo ""

read -rp "  Try it? (Y/n) " TRY_RESILIENCE </dev/tty
echo ""

if [[ "${TRY_RESILIENCE,,}" != "n"* ]]; then
  explain "Stopping n2's container..."
  echo ""

  N2_CONTAINER=$(docker ps --format '{{.Names}}' | grep "postgres-${DB_ID}-n2-" | head -1)
  if [[ -n "$N2_CONTAINER" ]]; then
    docker stop "$N2_CONTAINER" >/dev/null 2>&1
    info "Node n2 stopped."
  else
    warn "Could not find n2 container."
  fi

  echo ""
  explain "n2 is down. Let's write on n1 and read from n3 -- they should still work:"

  prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n1-) psql -U admin ${DB_ID} -c \"INSERT INTO example (id, data) VALUES (3, 'Written while n2 is down!');\""

  prompt_run "docker exec \$(docker ps --format '{{.Names}}' | grep postgres-${DB_ID}-n3-) psql -U admin ${DB_ID} -c \"SELECT * FROM example;\""

  info "The cluster kept working with a node down."
  echo ""
  explain "In a production environment, Control Plane would automatically recover n2."
  explain "For this demo, you can restart it manually:"
  echo ""
  explain "  ${DIM}docker start ${N2_CONTAINER}${RESET}"
fi

# ── Completion ───────────────────────────────────────────────────────────────

header "Done!"

info "You've created a distributed Postgres database with multi-master"
info "replication, scaled it out, and proven it survives node failure --"
info "all through the Control Plane API."
echo ""
explain "What's next:"
explain ""
explain "  Browse packages:       https://docs.pgedge.com/enterprise/packages"
explain "  Full documentation:    https://docs.pgedge.com/enterprise/"
echo ""
explain "${BOLD}To clean up:${RESET}"
explain ""
explain "  ${DIM}# Stop and remove all demo containers${RESET}"
explain "  ${DIM}docker rm -f \$(docker ps -aq --filter label=pgedge.database.id) host-1${RESET}"
explain "  ${DIM}# Remove data directory${RESET}"
explain "  ${DIM}rm -rf ~/pgedge/control-plane${RESET}"
echo ""
