#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Serving package catalog at http://localhost:${PORT}"
echo "Press Ctrl+C to stop."
python3 -m http.server "$PORT" --directory "$DIR"
