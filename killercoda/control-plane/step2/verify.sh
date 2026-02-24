#!/bin/bash
# Verify Control Plane is responding
curl -sf http://localhost:3000/v1/cluster/init > /dev/null 2>&1
