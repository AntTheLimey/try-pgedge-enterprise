#!/bin/bash
# Verify Docker Swarm is active and CP image is pulled
docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q active && \
docker image ls ghcr.io/pgedge/control-plane --format '{{.Repository}}' | grep -q control-plane && \
command -v jq > /dev/null 2>&1 && \
command -v psql > /dev/null 2>&1
