#!/bin/bash
# Waits for a database to reach "available" state.
# Usage: wait-for-db.sh <database_id> [timeout_seconds]
#
# Killercoda copies this to /usr/local/bin with +x via index.json assets.

DB_ID="${1:?Usage: wait-for-db.sh <database_id> [timeout_seconds]}"
TIMEOUT="${2:-180}"

spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0
elapsed=0

while [ "$elapsed" -lt "$TIMEOUT" ]; do
  state=$(curl -sf "http://localhost:3000/v1/databases/${DB_ID}" 2>/dev/null | jq -r '.state // empty')

  if [ "$state" = "available" ]; then
    printf "\r  ✓ Database '%s' is available.         \n" "$DB_ID"
    exit 0
  fi

  printf "\r  %s Waiting for database '%s' (state: %s)..." "${spinner[$i]}" "$DB_ID" "${state:-pending}"
  i=$(( (i + 1) % ${#spinner[@]} ))
  sleep 3
  elapsed=$((elapsed + 3))
done

echo ""
echo "  ✗ Timed out after ${TIMEOUT}s waiting for database '${DB_ID}'"
exit 1
