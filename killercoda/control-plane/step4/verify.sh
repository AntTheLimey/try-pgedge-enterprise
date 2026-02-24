#!/bin/bash
# Verify both nodes are available
curl -sf http://localhost:3000/v1/databases/demo 2>/dev/null | \
  jq -e '.state == "available" and ([.instances[] | select(.node_name == "n1" or .node_name == "n2")] | length == 2)' > /dev/null 2>&1
