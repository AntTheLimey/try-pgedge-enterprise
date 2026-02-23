#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../lib/helpers.sh
source "$SCRIPT_DIR/../../lib/helpers.sh"
setup_trap

PG_VERSION="${PG_VERSION:-17}"

# ── Welcome ──────────────────────────────────────────────────────────────────

header "Spock Multi-Master Replication Setup"

explain "This helper walks you through configuring Spock active-active"
explain "replication between two nodes. You'll run commands on this machine"
explain "(node 1) and be told what to run on the second machine (node 2)."
echo ""

# ── Collect node IPs ─────────────────────────────────────────────────────────

read -rp "  Enter Node 1 IP (this machine): " NODE1_IP </dev/tty
read -rp "  Enter Node 2 IP:                " NODE2_IP </dev/tty
echo ""

DB_NAME="${DB_NAME:-demo}"

info "Node 1: ${NODE1_IP}"
info "Node 2: ${NODE2_IP}"
info "Database: ${DB_NAME}"

prompt_continue

# ── Configure for logical replication ────────────────────────────────────────

header "Configure for Logical Replication"

explain "PostgreSQL needs specific settings for Spock logical replication."
explain "We'll configure them on this node, then you'll do the same on node 2."

prompt_run "sudo -u postgres psql -c \"ALTER SYSTEM SET wal_level = 'logical';\""
prompt_run "sudo -u postgres psql -c \"ALTER SYSTEM SET max_worker_processes = 16;\""
prompt_run "sudo -u postgres psql -c \"ALTER SYSTEM SET max_replication_slots = 16;\""
prompt_run "sudo -u postgres psql -c \"ALTER SYSTEM SET shared_preload_libraries = 'spock';\""

explain "Restarting PostgreSQL to apply changes..."
prompt_run "sudo systemctl restart postgresql-${PG_VERSION}"

warn "Now run the same four ALTER SYSTEM commands on node 2 (${NODE2_IP})"
warn "and restart PostgreSQL there before continuing."

prompt_continue

# ── Enable Spock ─────────────────────────────────────────────────────────────

header "Enable Spock"

explain "Create the database and enable the Spock extension on this node."

prompt_run "sudo -u postgres createdb ${DB_NAME}"
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"CREATE EXTENSION spock;\""

warn "Now run the same commands on node 2 (${NODE2_IP}):"
show_cmd "sudo -u postgres createdb ${DB_NAME}"
show_cmd "sudo -u postgres psql -d ${DB_NAME} -c \"CREATE EXTENSION spock;\""

prompt_continue

# ── Create nodes ─────────────────────────────────────────────────────────────

header "Create Spock Nodes"

explain "Register this machine as node n1 in the Spock topology."

# NOTE: spock.node_create signature needs validation against Spock 5.0 docs
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.node_create(node_name := 'n1', dsn := 'host=${NODE1_IP} dbname=${DB_NAME}');\""

explain "Now create node n2 on the second machine (${NODE2_IP}):"
# NOTE: spock.node_create signature needs validation against Spock 5.0 docs
show_cmd "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.node_create(node_name := 'n2', dsn := 'host=${NODE2_IP} dbname=${DB_NAME}');\""

warn "Run the command above on node 2 before continuing."

prompt_continue

# ── Create subscriptions ─────────────────────────────────────────────────────

header "Create Bidirectional Subscriptions"

explain "Create a subscription on n1 that pulls changes from n2."

# NOTE: spock.sub_create signature needs validation against Spock 5.0 docs
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.sub_create(subscription_name := 'n1_to_n2', provider_dsn := 'host=${NODE2_IP} dbname=${DB_NAME}');\""

explain "Now create the reverse subscription on node 2 (${NODE2_IP}):"
# NOTE: spock.sub_create signature needs validation against Spock 5.0 docs
show_cmd "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.sub_create(subscription_name := 'n2_to_n1', provider_dsn := 'host=${NODE1_IP} dbname=${DB_NAME}');\""

warn "Run the command above on node 2 before continuing."

prompt_continue

# ── Verify replication ───────────────────────────────────────────────────────

header "Verify Replication"

explain "Let's prove replication works. We'll create a table and insert a row"
explain "on node 1, then check that it appears on node 2."

prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"CREATE TABLE test (id int PRIMARY KEY, msg text);\""
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"INSERT INTO test VALUES (1, 'from n1');\""

explain "Now check on node 2 -- the row should be replicated:"
show_cmd "sudo -u postgres psql -h ${NODE2_IP} -d ${DB_NAME} -c \"SELECT * FROM test;\""
echo ""

info "If you see the row on node 2, replication is working."
info "Try inserting on node 2 and reading back on node 1 to confirm"
info "bidirectional replication."
echo ""
