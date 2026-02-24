#!/bin/bash
set -euo pipefail

# --- Killercoda background installer ---
# Pulls the Control Plane image and installs tools.
# The foreground script waits for /tmp/.background-done before proceeding.

echo "Initializing Docker Swarm..."
docker swarm init 2>/dev/null || true

echo "Pulling pgEdge Control Plane image..."
docker pull ghcr.io/pgedge/control-plane

echo "Installing tools..."
apt-get update -qq
apt-get install -y -qq jq postgresql-client > /dev/null 2>&1

echo "Creating backup directory..."
mkdir -p /var/lib/pgedge/backups

touch /tmp/.background-done
echo "Background setup complete!"
