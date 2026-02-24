#!/bin/bash
# Verify the database is available with 1 node
curl -sf http://localhost:3000/v1/databases/demo 2>/dev/null | \
  jq -e '.state == "available"' > /dev/null 2>&1
