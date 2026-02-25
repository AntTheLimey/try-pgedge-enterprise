#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update && sudo apt-get install -y postgresql-client jq
echo ""
echo "Setup complete!"
echo "  Option A: WALKTHROUGH.md should be open (click Run buttons)"
echo "  Option B: bash guides/guide.sh"
