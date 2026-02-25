#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/helpers.sh
source "$SCRIPT_DIR/../lib/helpers.sh"
setup_trap

PG_VERSION="${PG_VERSION:-17}"

# ── Welcome ──────────────────────────────────────────────────────────────────

header "pgEdge Enterprise -- Explore & Install"

explain "This guide walks you through the bare-metal experience:"
explain ""
explain "  1. Explore what's available"
explain "  2. Install Enterprise Postgres"
explain "  3. Verify extensions"
explain "  4. Set up replication (optional)"
explain ""
explain "You'll go from a fresh Linux VM to a fully loaded Enterprise Postgres"
explain "with 30+ packages, and optionally configure multi-master replication."
explain ""
explain "${DIM}Prerequisites: Linux VM (EL 9/10, Debian 11-13, Ubuntu 22.04/24.04), sudo${RESET}"

prompt_continue

# ── Step 1: Explore What's Available ─────────────────────────────────────────

header "Step 1: Explore What's Available"

explain "pgEdge Enterprise Postgres includes 30+ packages across 5 categories:"
echo ""
explain "  ${BOLD}Core${RESET}          PostgreSQL ${PG_VERSION}, Spock 5.0, lolor, Snowflake"
explain "  ${BOLD}AI/ML${RESET}         pgVector, MCP Server, RAG Server, Vectorizer, Anonymizer, Docloader"
explain "  ${BOLD}Management${RESET}    pgAdmin 4, pgBouncer, pgBackRest, ACE, Radar"
explain "  ${BOLD}Extensions${RESET}    PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB, pg_hint_plan, PLV8, set_user"
explain "  ${BOLD}HA${RESET}            Patroni, etcd"
echo ""
explain "Two meta-packages make installation easy:"
echo ""
explain "  ${BOLD}Minimal (recommended)${RESET}  pgedge-enterprise-postgres_${PG_VERSION}   -- Core + key extensions"
explain "  ${BOLD}Full${RESET}                   pgedge-enterprise-all_${PG_VERSION}         -- Everything included"
echo ""
explain "${DIM}Browse the full catalog: https://docs.pgedge.com/enterprise/packages${RESET}"

prompt_continue

# ── Step 2: Install Enterprise Postgres ──────────────────────────────────────

header "Step 2: Install Enterprise Postgres"

# -- Check for existing PostgreSQL installation --
EXISTING_PG=false

if command -v psql &>/dev/null; then
  EXISTING_PG=true
fi

if command -v systemctl &>/dev/null; then
  if systemctl is-active --quiet postgresql 2>/dev/null \
      || systemctl is-active --quiet "postgresql-*" 2>/dev/null; then
    EXISTING_PG=true
  fi
fi

if [[ -d /var/lib/postgresql ]] || [[ -d /var/lib/pgsql ]]; then
  EXISTING_PG=true
fi

if [[ "$EXISTING_PG" == "true" ]]; then
  echo ""
  warn "Existing PostgreSQL installation detected."
  echo ""
  explain "This guide installs system packages and needs a machine without PostgreSQL."
  explain "Use a fresh Linux VM -- UTM (macOS), Multipass, or a cloud instance all work."
  echo ""
  explain "Alternatively, try the ${BOLD}Control Plane${RESET} path -- it runs in Docker containers"
  explain "and won't conflict with your existing PostgreSQL:"
  echo ""
  explain "  ${DIM}curl -sSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main/control-plane/run.sh | bash${RESET}"
  echo ""
  exit 0
fi

detect_os
info "Detected: ${OS_ID} ${OS_VERSION} (${OS_ARCH})"
echo ""

# -- Choose minimal or full installation --
explain "Two installation options:"
echo ""
explain "  ${BOLD}1) Minimal (recommended)${RESET}  PostgreSQL + Spock + pgVector + PostGIS + pgAudit"
explain "  ${BOLD}2) Full${RESET}                   Everything above + pgAdmin, pgBouncer, pgBackRest,"
explain "                            Patroni, TimescaleDB, and 15+ more packages"
echo ""
read -rp "  Choose [1/2] (default: 1): " INSTALL_CHOICE </dev/tty
echo ""

if [[ "${INSTALL_CHOICE:-1}" == "2" ]]; then
  INSTALL_MODE="full"
else
  INSTALL_MODE="minimal"
fi

case "$OS_FAMILY" in
  el)
    explain "Installing prerequisites (EPEL + CRB)..."
    prompt_run "sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_MAJOR}.noarch.rpm"
    prompt_run "sudo dnf config-manager --set-enabled crb"

    explain "Adding the pgEdge repository..."
    prompt_run "sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm"

    if [[ "$INSTALL_MODE" == "full" ]]; then
      explain "Installing pgEdge Enterprise Postgres ${PG_VERSION} (full)..."
      prompt_run "sudo dnf install -y pgedge-enterprise-all_${PG_VERSION}"
    else
      explain "Installing pgEdge Enterprise Postgres ${PG_VERSION} (minimal)..."
      prompt_run "sudo dnf install -y pgedge-enterprise-postgres_${PG_VERSION}"
    fi

    explain "Initializing the database cluster and starting PostgreSQL..."
    prompt_run "sudo /usr/pgsql-${PG_VERSION}/bin/postgresql-${PG_VERSION}-setup initdb"
    prompt_run "sudo systemctl enable --now postgresql-${PG_VERSION}"
    ;;

  debian|ubuntu)
    explain "Installing prerequisites..."
    prompt_run "sudo apt-get update && sudo apt-get install -y curl gnupg2 apt-transport-https"

    explain "Adding the pgEdge repository..."
    prompt_run "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update"

    if [[ "$INSTALL_MODE" == "full" ]]; then
      explain "Installing pgEdge Enterprise Postgres ${PG_VERSION} (full)..."
      prompt_run "sudo apt-get install -y pgedge-enterprise-all-${PG_VERSION}"
    else
      explain "Installing pgEdge Enterprise Postgres ${PG_VERSION} (minimal)..."
      prompt_run "sudo apt-get install -y pgedge-enterprise-postgres-${PG_VERSION}"
    fi

    explain "Starting the database cluster and enabling PostgreSQL..."
    prompt_run "sudo pg_ctlcluster ${PG_VERSION} main start"
    prompt_run "sudo systemctl enable --now postgresql"
    ;;

  *)
    warn "Unsupported OS: ${OS_ID} ${OS_VERSION}"
    warn "This guide supports Enterprise Linux (RHEL/Rocky/Alma), Debian, and Ubuntu."
    warn "See https://www.pgedge.com/enterprise/ for manual installation instructions."
    exit 1
    ;;
esac

info "pgEdge Enterprise Postgres ${PG_VERSION} installed and running."

prompt_continue

# ── Step 3: Verify Extensions ────────────────────────────────────────────────

header "Step 3: Verify Extensions"

explain "Let's confirm the key extensions are available. These are installed as"
explain "shared libraries but not yet enabled -- use CREATE EXTENSION when needed."

prompt_run "sudo -u postgres psql -c \"SELECT name, default_version, comment FROM pg_available_extensions WHERE name IN ('spock','vector','postgis','pgaudit') ORDER BY name;\""

prompt_continue

# ── Step 4: Set Up Replication (Optional) ────────────────────────────────────

header "Step 4: Set Up Replication (Optional)"

explain "Spock enables multi-master active-active replication. Each node accepts"
explain "writes and replicates to the others with column-level conflict resolution."
echo ""
explain "This step requires ${BOLD}2 or more VMs${RESET} with pgEdge Enterprise installed."
echo ""

read -rp "  Do you have 2+ VMs ready? (y/N) " HAS_VMS </dev/tty
echo ""

if [[ "${HAS_VMS,,}" == "y"* ]]; then
  explain "Launching the replication setup helper..."
  echo ""
  bash "$SCRIPT_DIR/scripts/setup-replication.sh"
else
  info "No problem! You can set up replication later by running:"
  echo ""
  explain "  ${DIM}bash $SCRIPT_DIR/scripts/setup-replication.sh${RESET}"
  echo ""
fi

# ── Completion ───────────────────────────────────────────────────────────────

header "Done!"

info "You've installed pgEdge Enterprise Postgres and explored the full"
info "package ecosystem on bare metal."
echo ""
explain "What's next:"
explain ""
explain "  Browse packages:       https://docs.pgedge.com/enterprise/packages"
explain "  Try Control Plane:     ../control-plane/guide.sh"
explain "  Full documentation:    https://docs.pgedge.com/enterprise/"
echo ""
explain "${BOLD}Started with bare metal?${RESET} Add Control Plane to orchestrate what you"
explain "already have -- backups, failover, and scaling, all managed through a"
explain "single API."
echo ""
explain "  ${DIM}bash ../control-plane/guide.sh${RESET}"
echo ""
