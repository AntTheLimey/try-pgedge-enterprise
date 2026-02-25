#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script — downloads and runs the bare-metal guide without cloning.
# Usage: curl -sSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main/bare-metal/run.sh | bash

BASE_URL="https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main"
DEST="/tmp/pgedge-enterprise"

if ! command -v curl &>/dev/null; then
  echo "Error: curl is required but not found." >&2
  exit 1
fi

echo "Downloading pgEdge Enterprise guide..."

mkdir -p "$DEST/bare-metal/scripts" "$DEST/lib"

files=(
  "lib/helpers.sh"
  "bare-metal/guide.sh"
  "bare-metal/scripts/setup-replication.sh"
)

for f in "${files[@]}"; do
  if ! curl -sSfL "$BASE_URL/$f" -o "$DEST/$f"; then
    echo "Error: failed to download $f" >&2
    exit 1
  fi
done

chmod +x "$DEST/lib/helpers.sh" \
         "$DEST/bare-metal/guide.sh" \
         "$DEST/bare-metal/scripts/setup-replication.sh"

exec bash "$DEST/bare-metal/guide.sh"
