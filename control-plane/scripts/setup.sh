#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../lib/helpers.sh
source "$SCRIPT_DIR/../../lib/helpers.sh"
setup_trap

# ── Configurable variables ───────────────────────────────────────────────────

CP_IMAGE="${CP_IMAGE:-ghcr.io/pgedge/control-plane}"
CP_CONTAINER="host-1"
CP_PORT="${CP_PORT:-3000}"
CP_DATA="${CP_DATA:-$HOME/pgedge/control-plane}"

# ── Functions ────────────────────────────────────────────────────────────────

check_existing() {
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
    info "Control Plane is already running (container: ${CP_CONTAINER})"
    info "API: http://localhost:${CP_PORT}"
    return 0
  fi
  return 1
}

ensure_docker() {
  require_cmd docker "Install Docker: https://docs.docker.com/get-docker/"

  if ! docker info &>/dev/null; then
    error "Docker daemon is not running. Please start Docker and try again."
    exit 1
  fi
}

ensure_swarm() {
  if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
    info "Initializing Docker Swarm..."
    # Use the default-route IPv4 address to avoid multi-address errors
    local advertise_addr
    advertise_addr=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
    if [[ -n "$advertise_addr" ]]; then
      docker swarm init --advertise-addr "$advertise_addr" 2>/dev/null || true
    else
      docker swarm init 2>/dev/null || true
    fi
  fi
}

start_control_plane() {
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
}

wait_for_healthy() {
  start_spinner "Waiting for Control Plane API..."
  local retries=30
  while [[ "$retries" -gt 0 ]]; do
    if curl -sf "http://localhost:${CP_PORT}/v1/version" >/dev/null 2>&1; then
      stop_spinner
      info "Control Plane running on http://localhost:${CP_PORT}"
      return 0
    fi
    sleep 2
    retries=$((retries - 1))
  done
  stop_spinner
  error "Control Plane did not become healthy within 60 seconds."
  exit 1
}

cleanup() {
  # Delete any databases first (async, best-effort)
  curl -sf -X DELETE "http://localhost:${CP_PORT}/v1/databases/example" >/dev/null 2>&1 || true
  sleep 3

  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
    info "Stopping and removing Control Plane container..."
    docker stop "$CP_CONTAINER" >/dev/null 2>&1 || true
    docker rm "$CP_CONTAINER" >/dev/null 2>&1 || true
    info "Container removed."
  fi

  # Remove database containers managed by CP
  local db_containers
  db_containers=$(docker ps -a --filter "label=pgedge.database.id" --format '{{.Names}}' 2>/dev/null || true)
  if [[ -n "$db_containers" ]]; then
    info "Removing database containers..."
    echo "$db_containers" | xargs -r docker rm -f >/dev/null 2>&1 || true
  fi

  if [[ -d "$CP_DATA" ]]; then
    info "Removing data directory: $CP_DATA"
    rm -rf "$CP_DATA"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

case "${1:-setup}" in
  setup)
    if check_existing; then
      exit 0
    fi
    ensure_docker
    ensure_swarm
    start_control_plane
    wait_for_healthy
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Usage: $0 {setup|cleanup}"
    exit 1
    ;;
esac
