#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script — downloads and runs the control-plane guide without cloning.
# Usage: curl -sSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main/control-plane/run.sh | bash

BASE_URL="https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main"
DEST="/tmp/pgedge-enterprise"

if ! command -v curl &>/dev/null; then
  echo "Error: curl is required but not found." >&2
  exit 1
fi

echo "Downloading pgEdge Control Plane guide..."

mkdir -p "$DEST/control-plane/scripts" "$DEST/lib"

files=(
  "lib/helpers.sh"
  "control-plane/guide.sh"
  "control-plane/scripts/setup.sh"
)

for f in "${files[@]}"; do
  if ! curl -sSfL "$BASE_URL/$f" -o "$DEST/$f"; then
    echo "Error: failed to download $f" >&2
    exit 1
  fi
done

chmod +x "$DEST/lib/helpers.sh" \
         "$DEST/control-plane/guide.sh" \
         "$DEST/control-plane/scripts/setup.sh"

exec bash "$DEST/control-plane/guide.sh"
