#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script — downloads and runs the Control Plane guide without cloning.
# Usage: curl -sSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main/guides/run.sh | bash

BASE_URL="https://raw.githubusercontent.com/AntTheLimey/try-pgedge-enterprise/main"
DEST="/tmp/pgedge-enterprise"

if ! command -v curl &>/dev/null; then
  echo "Error: curl is required but not found." >&2
  exit 1
fi

echo "Downloading pgEdge Control Plane guide..."

mkdir -p "$DEST/guides" "$DEST/lib"

files=(
  "lib/helpers.sh"
  "guides/guide.sh"
)

for f in "${files[@]}"; do
  if ! curl -sSfL "$BASE_URL/$f" -o "$DEST/$f"; then
    echo "Error: failed to download $f" >&2
    exit 1
  fi
done

chmod +x "$DEST/lib/helpers.sh" \
         "$DEST/guides/guide.sh"

exec bash "$DEST/guides/guide.sh"
