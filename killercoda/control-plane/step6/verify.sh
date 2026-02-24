#!/bin/bash
# Verify backup config is set on the database
curl -sf http://localhost:3000/v1/databases/demo 2>/dev/null | \
  jq -e '.spec.backup_config.repositories | length > 0' > /dev/null 2>&1
