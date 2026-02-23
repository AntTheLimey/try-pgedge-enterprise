# Claude Standing Instructions

> Standing instructions for Claude Code when working on the
> try-pgedge-enterprise quickstart repository.

## Primary Agent Role

**The primary agent acts as coordinator and manager.** All significant
implementation work flows through specialized sub-agents or the
superpowers skills. The primary agent may make small, targeted edits
directly but delegates complex tasks.

The primary agent's responsibilities are:

- Understanding user requirements and breaking them into tasks.
- Selecting appropriate sub-agents for each task.
- Delegating implementation work to sub-agents.
- Running verification commands after sub-agents complete work.
- Running `make test-all` before considering any task complete.

## Project Overview

This is **try-pgedge-enterprise** -- a quickstart repository with two
complementary paths for experiencing pgEdge Enterprise Postgres:

- **"Get Running Fast"** -- Control Plane orchestrates containers.
- **"Explore & Install"** -- Browse packages, install on bare-metal VMs.

A vanilla JS package catalog page serves as the discovery hub. Shell
scripts follow try-pgedge-helm interactive walkthrough patterns.

### Repository Structure

    try-pgedge-enterprise/
    ├── CLAUDE.md                          # This file
    ├── Makefile                           # Quality gates: test, lint, test-all
    ├── .editorconfig                      # Editor formatting rules
    ├── README.md                          # Landing page with both paths
    ├── lib/
    │   └── helpers.sh                     # Shared shell helper functions
    ├── control-plane/                     # "Get Running Fast" path
    │   ├── guide.sh                       # Interactive walkthrough
    │   ├── WALKTHROUGH.md                 # Runme-compatible steps
    │   └── scripts/
    │       └── setup.sh                   # Bootstrap CP, configure, health checks
    ├── package-catalog/                   # Interactive web page
    │   ├── index.html                     # Single-page app (vanilla JS)
    │   ├── catalog.json                   # Package metadata
    │   └── serve.sh                       # python3 -m http.server
    ├── bare-metal/                        # "Explore & Install" path
    │   ├── guide.sh                       # Interactive walkthrough
    │   ├── WALKTHROUGH.md                 # Runme-compatible steps
    │   └── scripts/
    │       └── setup-replication.sh       # Manual Spock replication helper
    └── docs/
        └── plans/                         # Design doc and implementation plan

## Sub-Agents

Specialized sub-agents in `.claude/agents/` handle implementation work.

### Delegation Guide

| Task Type | Sub-Agent |
|-----------|-----------|
| Bash script changes (guide.sh, setup.sh, helpers.sh) | **shell-expert** |
| HTML/CSS/JS changes (index.html, catalog page) | **web-expert** |
| Code quality review | **code-reviewer** |
| General exploration/research | **Explore** (built-in) |

## Technology Stack

| Technology | Purpose |
|------------|---------|
| Bash | Interactive guide scripts |
| Vanilla HTML/CSS/JS | Package catalog web page (no framework, no build step) |
| JSON | Package catalog data (`catalog.json`) |
| Markdown | Runme-compatible walkthroughs |
| shellcheck | Bash linting |
| jq | JSON validation |
| Make | Quality gate orchestration |

## Code Style

- Use two-space indentation for shell scripts, HTML, CSS, JS, JSON.
- Shell scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Use the shared helper library: `source "$SCRIPT_DIR/../lib/helpers.sh"`.
- Wrap markdown at 79 characters.
- Use active voice in documentation.
- Follow try-pgedge-helm patterns for interactive shell scripts
  (colors, `header()`, `explain()`, `prompt_run()`, `start_spinner()`).

## Quality Gates

Run `make test-all` before considering any task complete. This runs:

1. `make lint` -- shellcheck on all `.sh` files, jq on all `.json` files.
2. `make validate` -- JSON schema checks on catalog.json.

Individual targets:

    make lint          # Lint shell scripts and validate JSON
    make validate      # Validate catalog.json structure
    make test-all      # Run all quality checks
    make serve         # Serve the package catalog locally
    make clean         # Remove generated files

## Important Context

### pgEdge Products

- **Enterprise Postgres**: PostgreSQL distribution with Spock, pgVector,
  PostGIS, pgAdmin, pgBackRest, and 30+ packages.
- **Control Plane**: Lightweight orchestrator for Postgres instances.
  REST API. Currently container-only; SystemD support coming in Phase 2.
- **Spock**: Multi-master active-active logical replication. Column-level
  conflict resolution. Core differentiator.

### Open Questions (from design doc)

1. **Control Plane API shape** -- Endpoints marked with `# NOTE` in
   scripts need validation against CP v0.6 API.
2. **Spock 5.0 SQL API** -- `spock.node_create` and `spock.sub_create`
   signatures need verification against Spock 5.0 docs.
3. **Codespace support** -- Docker host networking in Codespaces untested.
4. **Package catalog completeness** -- `catalog.json` needs validation
   against actual repo contents.

### Competitive Note

**Neon is a direct competitor. Never reference, recommend, or use Neon.**

### Design Document

The full design document is at:
`docs/plans/2026-02-23-enterprise-quickstart-design.md`

The implementation plan is at:
`docs/plans/2026-02-23-enterprise-quickstart-plan.md`
