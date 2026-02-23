# Enterprise Quickstart Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build try-pgedge-enterprise — a quickstart repo with Control Plane and bare-metal walkthrough paths, an interactive package catalog web page, and ant-dev-experience prototype updates.

**Architecture:** Two complementary quickstart paths (Control Plane containers + bare-metal packages) in one repo, bridged by messaging not technology. A vanilla JS package catalog page serves as the discovery hub. Shell scripts follow try-pgedge-helm interactive walkthrough patterns. The ant-dev-experience prototype gets a mode toggle rewrite mirroring ContainersSection.tsx.

**Tech Stack:** Bash (guide scripts), vanilla HTML/CSS/JS (catalog page), React/TypeScript (prototype updates), JSON (catalog data)

**Quality tools:** shellcheck (bash linting), jq (JSON validation), Makefile (quality gates)

**Reference repos:**
- Design doc: `docs/plans/2026-02-23-enterprise-quickstart-design.md` (this repo)
- Shell patterns: `/Users/apegg/PROJECTS/try-pgedge-helm/guide.sh`
- Claude + agent patterns: `/Users/apegg/PROJECTS/ai-dba-workbench/` (coordinator model, Makefile quality gates, agent knowledge bases)
- Claude + agent patterns: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/` (sub-agent delegation, settings)
- React patterns: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/ContainersSection.tsx`
- Current prototype: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/EnterprisePostgresSection.tsx`

---

## Task 1: Repository Scaffolding, Claude Config, and Quality Tooling

This task creates the full project foundation: directory structure, Claude
Code configuration (CLAUDE.md, agents, settings), quality gates (Makefile,
shellcheck, jq validation), and editor config.

**Files:**
- Create: `CLAUDE.md`
- Create: `.claude/settings.local.json`
- Create: `.claude/agents/shell-expert.md`
- Create: `.claude/agents/web-expert.md`
- Create: `.claude/agents/code-reviewer.md`
- Create: `Makefile`
- Create: `.editorconfig`
- Create: `.gitignore`
- Create: `README.md` (placeholder — full content in Task 8)
- Create: `package-catalog/serve.sh`
- Create: placeholder scripts and markdown files for all deliverables

### Step 1: Create directory structure

```bash
mkdir -p control-plane/scripts package-catalog bare-metal/scripts lib \
         .claude/agents .claude/shell-expert .claude/web-expert .claude/code-reviewer
```

### Step 2: Create .gitignore

```gitignore
# OS
.DS_Store
Thumbs.db

# Editors
*.swp
*.swo
*~
.vscode/
.idea/

# Vagrant (stretch goal)
vagrant/.vagrant/

# Runtime
*.log
*.pid

# Node (only if htmlhint/eslint added later)
node_modules/
```

### Step 3: Create .editorconfig

```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.sh]
indent_style = space
indent_size = 2

[*.json]
indent_style = space
indent_size = 2

[*.html]
indent_style = space
indent_size = 2

[*.md]
indent_style = space
indent_size = 2
trim_trailing_whitespace = false
```

### Step 4: Create CLAUDE.md

This follows the coordinator model from ai-dba-workbench, adapted for this
project's shell + HTML + JSON tech stack.

```markdown
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

This is **try-pgedge-enterprise** — a quickstart repository with two
complementary paths for experiencing pgEdge Enterprise Postgres:

- **"Get Running Fast"** — Control Plane orchestrates containers.
- **"Explore & Install"** — Browse packages, install on bare-metal VMs.

A vanilla JS package catalog page serves as the discovery hub. Shell
scripts follow try-pgedge-helm interactive walkthrough patterns.

### Repository Structure

```
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
```

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

1. `make lint` — shellcheck on all `.sh` files, jq on all `.json` files.
2. `make validate` — JSON schema checks on catalog.json.

Individual targets:

```bash
make lint          # Lint shell scripts and validate JSON
make validate      # Validate catalog.json structure
make test-all      # Run all quality checks
make serve         # Serve the package catalog locally
make clean         # Remove generated files
```

## Important Context

### pgEdge Products

- **Enterprise Postgres**: PostgreSQL distribution with Spock, pgVector,
  PostGIS, pgAdmin, pgBackRest, and 30+ packages.
- **Control Plane**: Lightweight orchestrator for Postgres instances.
  REST API. Currently container-only; SystemD support coming in Phase 2.
- **Spock**: Multi-master active-active logical replication. Column-level
  conflict resolution. Core differentiator.

### Open Questions (from design doc)

1. **Control Plane API shape** — Endpoints marked with `# NOTE` in
   scripts need validation against CP v0.6 API.
2. **Spock 5.0 SQL API** — `spock.node_create` and `spock.sub_create`
   signatures need verification against Spock 5.0 docs.
3. **Codespace support** — Docker host networking in Codespaces untested.
4. **Package catalog completeness** — `catalog.json` needs validation
   against actual repo contents.

### Competitive Note

**Neon is a direct competitor. Never reference, recommend, or use Neon.**

### Design Document

The full design document is at:
`docs/plans/2026-02-23-enterprise-quickstart-design.md`

The implementation plan is at:
`docs/plans/2026-02-23-enterprise-quickstart-plan.md`
```

### Step 5: Create .claude/settings.local.json

```json
{
  "permissions": {
    "allow": [
      "Bash(make:*)",
      "Bash(shellcheck:*)",
      "Bash(jq:*)",
      "Bash(python3 -m http.server:*)",
      "Bash(python3 -c:*)",
      "Bash(chmod:*)",
      "Bash(ls:*)",
      "Bash(wc:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git branch:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(gh pr:*)",
      "Bash(gh issue:*)",
      "Bash(bash -c:*)",
      "Bash(mkdir:*)"
    ]
  }
}
```

### Step 6: Create .claude/agents/shell-expert.md

```markdown
---
name: shell-expert
description: Use this agent for writing and modifying Bash scripts — guide.sh, setup.sh, helpers.sh, and any shell scripting work. Can both advise and write code directly.

tools: Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch, AskUserQuestion
model: opus
color: green
---

You are a senior Bash scripting expert. You write interactive CLI
walkthrough scripts following the patterns established in the
try-pgedge-helm project.

## Your Role

You are a full-capability shell development agent. You can:

- **Implement**: Write and edit Bash scripts directly
- **Review**: Check scripts for correctness and best practices
- **Debug**: Diagnose and fix shell script issues

## Project Context

This is **try-pgedge-enterprise** — a quickstart repo with interactive
shell walkthroughs for pgEdge Enterprise Postgres. Read `CLAUDE.md`
for full project context.

## Shell Conventions

All scripts follow these conventions:

- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Source shared helpers: `source "$SCRIPT_DIR/../lib/helpers.sh"`
- Call `setup_trap` early for spinner cleanup on exit
- Two-space indentation
- Use helper functions: `header()`, `explain()`, `info()`, `warn()`,
  `show_cmd()`, `prompt_run()`, `prompt_continue()`, `start_spinner()`,
  `stop_spinner()`, `require_cmd()`, `detect_os()`
- Interactive prompts use `read -rp "..." </dev/tty`
- Filter TTY warnings: `2> >(grep -v "Unable to use a TTY" >&2)`

## Reference

The shared helper library is at `lib/helpers.sh`. Read it before writing
any script that uses these functions.

The try-pgedge-helm guide.sh at
`/Users/apegg/PROJECTS/try-pgedge-helm/guide.sh` is the gold-standard
reference for interactive walkthrough patterns.

## Quality

- All scripts must pass `shellcheck` with no errors
- Run `make lint` to verify
- Test scripts by running them when possible
```

### Step 7: Create .claude/agents/web-expert.md

```markdown
---
name: web-expert
description: Use this agent for the package catalog web page — HTML, CSS, vanilla JavaScript. Can both advise and write code directly. Use for any work on package-catalog/index.html.

tools: Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch, AskUserQuestion
model: opus
color: blue
---

You are a senior frontend developer specializing in vanilla HTML, CSS,
and JavaScript. You build clean, accessible, dependency-free web pages.

## Your Role

You are a full-capability web development agent. You can:

- **Implement**: Write and edit HTML, CSS, and JavaScript directly
- **Review**: Check pages for accessibility, responsiveness, correctness
- **Debug**: Diagnose and fix rendering or logic issues

## Project Context

This is **try-pgedge-enterprise** — a quickstart repo for pgEdge
Enterprise Postgres. Read `CLAUDE.md` for full project context.

The package catalog page is a single-file vanilla HTML/CSS/JS app at
`package-catalog/index.html` that reads from `package-catalog/catalog.json`.

## Design Principles

- **Single HTML file, vanilla JS.** No React, no build step, no
  node_modules. Trivially portable to any CMS or static host.
- **`catalog.json` is the source of truth.** The HTML reads from it.
  When packages change, update the JSON — the page adapts.
- **Absorbs complexity.** OS prerequisite matrix, RPM/DEB naming
  differences, PG version suffixes — all handled by the page.

## Three Zones

1. **Interactive Selector** (top) — 4 dropdowns: Platform, Architecture,
   PG Version, Meta-Package. Dynamically regenerates install commands.
2. **Generated Install Commands** (middle) — Adapts to selector values.
   Includes [Copy All] button.
3. **Browsable Package Catalog** (bottom) — Categorized, expandable tree
   rendered from `catalog.json`.

## Style

- Clean, professional look. pgEdge brand: navy (#0D2137), teal (#2DD4BF).
- Dark code blocks on light background.
- Responsive — works on mobile and desktop.
- No external CSS frameworks. All styles inline in the HTML file.
- Two-space indentation.

## Quality

- Semantic HTML5 elements
- Accessible: proper labels, keyboard navigation, ARIA where needed
- No external dependencies — everything in one file + catalog.json
- Test by serving locally: `bash package-catalog/serve.sh`
```

### Step 8: Create .claude/agents/code-reviewer.md

```markdown
---
name: code-reviewer
description: Use this agent for code quality review of shell scripts, HTML/JS, and JSON data files. Advisory only — does not modify code.

tools: Read, Grep, Glob, Bash, WebFetch, WebSearch, AskUserQuestion
model: opus
color: teal
---

You are an expert code reviewer for the try-pgedge-enterprise project.
Your mission is to ensure quality, correctness, and consistency.

## CRITICAL: Advisory Role Only

**You do NOT write, edit, or modify code directly.** You provide
analysis and recommendations for the primary agent to implement.

## Project Context

Read `CLAUDE.md` for full project context. This project contains:

- Bash scripts (guide.sh, setup.sh, helpers.sh)
- A vanilla HTML/CSS/JS page (index.html)
- JSON data files (catalog.json)
- Markdown documentation (WALKTHROUGH.md, README.md)

## Review Checklist

### Shell Scripts
- [ ] Starts with `#!/usr/bin/env bash` and `set -euo pipefail`
- [ ] Sources `lib/helpers.sh` correctly
- [ ] Calls `setup_trap` for spinner cleanup
- [ ] Uses two-space indentation
- [ ] All variables quoted (no word splitting)
- [ ] No unused variables
- [ ] Passes shellcheck with no errors
- [ ] Interactive prompts use `</dev/tty`
- [ ] Idempotent where possible (safe to re-run)
- [ ] `# NOTE` comments mark API endpoints needing validation

### HTML/CSS/JS
- [ ] Semantic HTML5 elements
- [ ] Accessible: labels, keyboard nav, ARIA
- [ ] No external dependencies
- [ ] XSS prevention (proper escaping of user-visible data)
- [ ] Responsive layout
- [ ] Copy button works
- [ ] Clean, consistent two-space indentation

### JSON
- [ ] Valid JSON (passes `jq empty`)
- [ ] Consistent structure across entries
- [ ] All required fields present
- [ ] No trailing commas

### Documentation
- [ ] Clear, concise language
- [ ] Active voice
- [ ] Code blocks have language tags
- [ ] Commands are correct and runnable
- [ ] Links are valid

## Report Format

**Code Review Report**

*Files Reviewed*: [list]
*Summary*: Issues: X | Suggestions: X

**[ISSUE-NNN] Title**
- **Location**: `file:line`
- **Severity**: Bug / Major / Minor / Style
- **Description**: What and why
- **Recommendation**: How to fix

**Positive Observations**: [What's done well]
```

### Step 9: Create agent knowledge base READMEs

Create `/.claude/shell-expert/README.md`:

```markdown
# Shell Expert Knowledge Base

## Interactive Walkthrough Pattern

The guide scripts follow a 5-phase pattern per step:

1. `header()` — Section title
2. `explain()` — Description of what will happen
3. `prompt_continue()` — Let user read
4. `prompt_run()` — Execute commands with pauses
5. `info()` — Success message

## Helper Functions (lib/helpers.sh)

| Function | Purpose |
|----------|---------|
| `header "text"` | Blue section header with decorations |
| `info "text"` | Green success/status message |
| `warn "text"` | Yellow warning message |
| `error "text"` | Red error message |
| `explain "text"` | Indented explanatory text |
| `show_cmd "cmd"` | Display command in yellow with $ prefix |
| `prompt_continue` | "Press Enter to continue..." |
| `prompt_run "cmd"` | Show command, wait for Enter, execute |
| `start_spinner "msg"` | Start background spinner animation |
| `stop_spinner` | Stop spinner, clear line |
| `require_cmd "cmd" "hint"` | Assert command exists or exit |
| `detect_os` | Set OS_FAMILY, OS_MAJOR, PKG_MGR from /etc/os-release |
| `setup_trap` | Register EXIT trap for spinner cleanup |

## Reference

- Gold standard: `/Users/apegg/PROJECTS/try-pgedge-helm/guide.sh`
- Shared library: `lib/helpers.sh`
```

Create `/.claude/web-expert/README.md`:

```markdown
# Web Expert Knowledge Base

## Package Catalog Page Architecture

Single-file vanilla HTML/CSS/JS app at `package-catalog/index.html`.

### Data Flow

1. Page loads → fetches `catalog.json` via `fetch()`
2. Populates dropdown selectors from platform/version data
3. Generates install commands dynamically on dropdown change
4. Renders categorized package tree with expand/collapse

### Three Zones

1. **Selector** — 4 dropdowns cascading to generate commands
2. **Commands** — Dynamically generated install steps + copy button
3. **Catalog** — Expandable category tree showing all packages

### catalog.json Schema

- `meta_packages[]` — Full and Minimal meta-packages
- `categories[]` — Package groups with individual package entries
- `platforms{}` — Platform configs with prerequisites and command patterns
- `pg_versions[]` — Available PG versions
- `default_*` — Default selections

### Style

- Brand colors: navy (#0D2137), teal (#2DD4BF)
- Dark code blocks (`#0f172a`) on light background (`#f8fafc`)
- Responsive grid for selectors
- No external dependencies
```

Create `/.claude/code-reviewer/README.md`:

```markdown
# Code Reviewer Knowledge Base

## Project Quality Standards

### Shell Scripts
- Follow try-pgedge-helm patterns exactly
- All scripts must pass shellcheck
- Interactive scripts source lib/helpers.sh
- Two-space indentation throughout

### HTML/CSS/JS
- Vanilla only — no frameworks, no build step
- Semantic HTML5 with accessibility
- All styles and scripts inline in single HTML file
- catalog.json is the single source of truth

### Common Anti-Patterns to Flag

```bash
# BAD: Unquoted variable
echo $VAR
# GOOD:
echo "$VAR"

# BAD: Missing error handling
cd some_dir
# GOOD:
cd some_dir || exit 1

# BAD: Using [ instead of [[
if [ "$x" = "y" ]; then
# GOOD:
if [[ "$x" = "y" ]]; then
```

```javascript
// BAD: innerHTML without escaping
el.innerHTML = userInput;
// GOOD:
el.textContent = userInput;

// BAD: No error handling on fetch
const data = await fetch("catalog.json");
// GOOD:
const resp = await fetch("catalog.json");
if (!resp.ok) throw new Error(`Failed: ${resp.status}`);
const data = await resp.json();
```
```

### Step 10: Create Makefile

```makefile
.PHONY: all lint validate test-all serve clean help

SHELL_FILES := $(shell find . -name '*.sh' -not -path './.git/*')
JSON_FILES  := $(shell find . -name '*.json' -not -path './.git/*' -not -path './.claude/*')

all: test-all

## Lint all shell scripts with shellcheck and validate JSON
lint:
	@echo "Linting shell scripts..."
	@shellcheck $(SHELL_FILES)
	@echo "✓ Shell scripts OK"
	@echo ""
	@echo "Validating JSON..."
	@for f in $(JSON_FILES); do \
		jq empty "$$f" || exit 1; \
	done
	@echo "✓ JSON OK"

## Validate catalog.json structure (categories, platforms, meta_packages)
validate:
	@echo "Validating catalog.json structure..."
	@python3 -c "\
import json, sys; \
d = json.load(open('package-catalog/catalog.json')); \
errors = []; \
if 'categories' not in d: errors.append('missing categories'); \
if 'platforms' not in d: errors.append('missing platforms'); \
if 'meta_packages' not in d: errors.append('missing meta_packages'); \
if 'pg_versions' not in d: errors.append('missing pg_versions'); \
for cat in d.get('categories', []): \
    for pkg in cat.get('packages', []): \
        if not pkg.get('name'): errors.append(f'package missing name in {cat[\"name\"]}'); \
        if not pkg.get('pg_versions'): errors.append(f'{pkg.get(\"name\",\"?\")} missing pg_versions'); \
for key, plat in d.get('platforms', {}).items(): \
    if not plat.get('install_pattern'): errors.append(f'{key} missing install_pattern'); \
if errors: \
    print('Validation errors:'); \
    [print(f'  - {e}') for e in errors]; \
    sys.exit(1); \
cats = len(d['categories']); \
pkgs = sum(len(c['packages']) for c in d['categories']); \
plats = len(d['platforms']); \
print(f'✓ catalog.json valid: {cats} categories, {pkgs} packages, {plats} platforms')"

## Run all quality checks
test-all: lint validate
	@echo ""
	@echo "═══════════════════════════════════"
	@echo "  ✓ All checks passed"
	@echo "═══════════════════════════════════"

## Serve the package catalog locally
serve:
	@bash package-catalog/serve.sh

## Remove generated files
clean:
	@echo "Nothing to clean (no build step)"

## Show this help
help:
	@echo "Available targets:"
	@echo "  make lint       - Lint shell scripts (shellcheck) and validate JSON (jq)"
	@echo "  make validate   - Validate catalog.json structure"
	@echo "  make test-all   - Run all quality checks"
	@echo "  make serve      - Serve package catalog on localhost:8080"
	@echo "  make clean      - Remove generated files"
	@echo "  make help       - Show this help"
```

### Step 11: Create serve.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Serving package catalog at http://localhost:${PORT}"
echo "Press Ctrl+C to stop."
python3 -m http.server "$PORT" --directory "$DIR"
```

### Step 12: Create placeholder files

Create minimal placeholders for all deliverable files. Each guide.sh
and setup script gets:

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Not yet implemented — see docs/plans/ for the implementation plan."
```

Each WALKTHROUGH.md gets:

```markdown
# TODO

This file will be implemented. See `docs/plans/` for the plan.
```

README.md gets:

```markdown
# try-pgedge-enterprise

> Implementation in progress. See `docs/plans/` for the design
> document and implementation plan.
```

### Step 13: Make all scripts executable

```bash
chmod +x control-plane/guide.sh control-plane/scripts/setup.sh \
         bare-metal/guide.sh bare-metal/scripts/setup-replication.sh \
         package-catalog/serve.sh
```

### Step 14: Verify structure

Run: `find . -not -path './.git/*' -not -name '.DS_Store' | sort`

Expected output should show the full directory tree from CLAUDE.md plus
the .claude/ agent config directory.

### Step 15: Verify quality tooling works

Run: `make lint`
Expected: shellcheck passes on all placeholder scripts, jq validates
any existing JSON files.

Note: `make validate` will fail until catalog.json exists (Task 3).
That's expected.

### Step 16: Commit

```bash
git add .gitignore .editorconfig CLAUDE.md .claude/ Makefile README.md \
       lib/ control-plane/ package-catalog/ bare-metal/
git commit -m "scaffold: repo structure, Claude config, quality tooling

Directory structure, placeholder scripts, CLAUDE.md with project
standing instructions, sub-agent configs (shell-expert, web-expert,
code-reviewer), Makefile with lint/validate/test-all targets,
.editorconfig, and .claude/settings.local.json."
```

---

## Task 2: Shared Shell Library

**Files:**
- Create: `lib/helpers.sh`
- Test: `shellcheck lib/helpers.sh`

This extracts the common helper functions from try-pgedge-helm's `guide.sh` into a shared library that both `control-plane/guide.sh` and `bare-metal/guide.sh` will source.

**Step 1: Write lib/helpers.sh**

```bash
#!/usr/bin/env bash
# Shared helper functions for interactive guide scripts.
# Source this file: SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" && source "$SCRIPT_DIR/../lib/helpers.sh"

# ── Colors ──────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

# ── Output helpers ──────────────────────────────────────────────────────────

header() {
  echo ""
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${BLUE}  $1${RESET}"
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
  echo ""
}

info() {
  echo -e "  ${GREEN}$1${RESET}"
}

warn() {
  echo -e "  ${YELLOW}$1${RESET}"
}

error() {
  echo -e "  ${RED}$1${RESET}"
}

explain() {
  echo -e "  $1"
}

show_cmd() {
  echo ""
  echo -e "  ${YELLOW}\$ $1${RESET}"
}

# ── Interactive helpers ─────────────────────────────────────────────────────

prompt_continue() {
  echo ""
  read -rp "  Press Enter to continue..." </dev/tty
  echo ""
}

prompt_run() {
  local cmd="$1"
  show_cmd "$cmd"
  echo ""
  read -rp "  Press Enter to run..." </dev/tty
  echo -e "  ${CYAN}Running...${RESET}"
  echo ""
  eval "$cmd" 2> >(grep -v "Unable to use a TTY" >&2)
  echo ""
}

# ── Spinner ─────────────────────────────────────────────────────────────────

SPINNER_PID=""

start_spinner() {
  local msg="$1"
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  (
    while true; do
      for (( i=0; i<${#chars}; i++ )); do
        printf "\r  \033[0;36m%s\033[0m %s" "${chars:$i:1}" "$msg"
        sleep 0.1
      done
    done
  ) &
  SPINNER_PID=$!
}

stop_spinner() {
  if [ -n "${SPINNER_PID:-}" ]; then
    kill "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null || true
    printf "\r\033[K"
    SPINNER_PID=""
  fi
}

# ── Prerequisite checks ────────────────────────────────────────────────────

require_cmd() {
  local cmd="$1"
  local install_hint="${2:-}"
  if ! command -v "$cmd" &>/dev/null; then
    error "Required command not found: $cmd"
    if [ -n "$install_hint" ]; then
      explain "$install_hint"
    fi
    exit 1
  fi
}

# ── OS detection (for bare-metal) ───────────────────────────────────────────

detect_os() {
  if [ ! -f /etc/os-release ]; then
    error "Cannot detect OS: /etc/os-release not found"
    exit 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release

  OS_ID="${ID:-unknown}"
  OS_VERSION="${VERSION_ID:-unknown}"
  OS_ARCH="$(uname -m)"

  case "$OS_ID" in
    rhel|rocky|almalinux|centos|ol)
      OS_FAMILY="el"
      OS_MAJOR="${OS_VERSION%%.*}"
      PKG_MGR="dnf"
      ;;
    debian)
      OS_FAMILY="debian"
      OS_MAJOR="${OS_VERSION%%.*}"
      PKG_MGR="apt-get"
      ;;
    ubuntu)
      OS_FAMILY="ubuntu"
      OS_MAJOR="${OS_VERSION}"
      PKG_MGR="apt-get"
      ;;
    *)
      error "Unsupported OS: $OS_ID $OS_VERSION"
      exit 1
      ;;
  esac

  info "Detected: ${NAME:-$OS_ID} ${OS_VERSION} (${OS_ARCH})"
}

# ── Cleanup trap helper ────────────────────────────────────────────────────

setup_trap() {
  trap 'stop_spinner' EXIT
}
```

**Step 2: Run shellcheck**

Run: `shellcheck lib/helpers.sh`
Expected: No errors (warnings about sourced variables are OK with the disable directive).

**Step 3: Verify sourcing works**

Run: `bash -c 'source lib/helpers.sh && header "Test" && info "OK"'`
Expected: Colored output with "Test" header and green "OK".

**Step 4: Run quality gate**

Run: `make lint`
Expected: All checks pass.

**Step 5: Commit**

```bash
git add lib/helpers.sh
git commit -m "feat: add shared shell helper library

Common functions for interactive guide scripts: colors, output
helpers, spinner, OS detection, prerequisite checks."
```

---

## Task 3: Package Catalog Data

**Files:**
- Create: `package-catalog/catalog.json`
- Test: `python3 -c "import json; json.load(open('package-catalog/catalog.json'))"`

**Step 1: Create catalog.json**

This is the single source of truth for all package and platform data. The HTML page and bare-metal guide both consume it.

```json
{
  "meta_packages": [
    {
      "id": "full",
      "label": "Enterprise All (Recommended)",
      "description": "Complete pgEdge Enterprise stack: PostgreSQL + Spock + all extensions + pgAdmin + pgBouncer + pgBackRest",
      "rpm_pattern": "pgedge-enterprise-all_{ver}",
      "deb_pattern": "pgedge-enterprise-all-{ver}",
      "pg_versions": ["16", "17", "18"]
    },
    {
      "id": "minimal",
      "label": "Enterprise Postgres (Minimal)",
      "description": "Core database with replication: PostgreSQL + Spock + lolor + Snowflake + pgAudit + PostGIS + pgVector + PL languages",
      "rpm_pattern": "pgedge-enterprise-postgres_{ver}",
      "deb_pattern": "pgedge-enterprise-postgres-{ver}",
      "pg_versions": ["16", "17", "18"]
    }
  ],
  "categories": [
    {
      "name": "Core",
      "packages": [
        {
          "name": "PostgreSQL",
          "description": "pgEdge-patched PostgreSQL database engine",
          "pg_versions": ["15", "16", "17", "18"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "Spock 5.0",
          "description": "Multi-master active-active logical replication",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "lolor",
          "description": "Large object logical replication support",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "Snowflake",
          "description": "Distributed sequence ID generation",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        }
      ]
    },
    {
      "name": "AI & Machine Learning",
      "packages": [
        {
          "name": "pgVector",
          "description": "Vector similarity search for AI embeddings",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "MCP Server",
          "description": "Model Context Protocol server for LLM-database integration",
          "pg_versions": ["17"],
          "included_in": ["full"]
        },
        {
          "name": "RAG Server",
          "description": "Retrieval-augmented generation server",
          "pg_versions": ["17"],
          "included_in": ["full"]
        },
        {
          "name": "Vectorizer",
          "description": "Automated vector embedding generation",
          "pg_versions": ["17"],
          "included_in": ["full"]
        },
        {
          "name": "Anonymizer",
          "description": "Data anonymization and masking for AI pipelines",
          "pg_versions": ["16", "17"],
          "included_in": ["full"]
        },
        {
          "name": "Docloader",
          "description": "Document ingestion and chunking for RAG workflows",
          "pg_versions": ["17"],
          "included_in": ["full"]
        }
      ]
    },
    {
      "name": "Management Tools",
      "packages": [
        {
          "name": "pgAdmin 4",
          "description": "Web-based PostgreSQL administration interface",
          "pg_versions": ["all"],
          "included_in": ["full"]
        },
        {
          "name": "pgBouncer",
          "description": "Lightweight connection pooler for PostgreSQL",
          "pg_versions": ["all"],
          "included_in": ["full"]
        },
        {
          "name": "pgBackRest",
          "description": "Reliable backup and restore with PITR support",
          "pg_versions": ["all"],
          "included_in": ["full"]
        },
        {
          "name": "ACE",
          "description": "Assessment, comparison, and evaluation tool for schema/data validation",
          "pg_versions": ["all"],
          "included_in": ["full"]
        },
        {
          "name": "Radar",
          "description": "Replication monitoring and health dashboard",
          "pg_versions": ["all"],
          "included_in": ["full"]
        }
      ]
    },
    {
      "name": "Extensions",
      "packages": [
        {
          "name": "PostGIS",
          "description": "Geospatial data types, functions, and indexing",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "pgAudit",
          "description": "Detailed session and object audit logging",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full", "minimal"]
        },
        {
          "name": "pg_cron",
          "description": "Job scheduler for running periodic SQL tasks",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full"]
        },
        {
          "name": "Orafce",
          "description": "Oracle compatibility functions and packages",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full"]
        },
        {
          "name": "TimescaleDB",
          "description": "Time-series data optimizations and hypertables",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full"]
        },
        {
          "name": "pg_hint_plan",
          "description": "Query plan hinting for manual optimization",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full"]
        },
        {
          "name": "PLV8",
          "description": "JavaScript procedural language (V8 engine)",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full"]
        },
        {
          "name": "set_user",
          "description": "Privilege escalation auditing and control",
          "pg_versions": ["15", "16", "17"],
          "included_in": ["full"]
        }
      ]
    },
    {
      "name": "High Availability",
      "packages": [
        {
          "name": "Patroni",
          "description": "Automatic failover and HA management for PostgreSQL",
          "pg_versions": ["all"],
          "included_in": ["full"]
        },
        {
          "name": "etcd",
          "description": "Distributed key-value store for Patroni consensus",
          "pg_versions": ["all"],
          "included_in": ["full"]
        }
      ]
    }
  ],
  "platforms": {
    "el9": {
      "label": "Enterprise Linux 9 (RHEL / Rocky / Alma)",
      "family": "el",
      "version": "9",
      "pkg_manager": "dnf",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [
        "sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm",
        "sudo dnf config-manager --set-enabled crb"
      ],
      "repo_install": "sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm",
      "install_pattern": "sudo dnf install -y {package}",
      "init_pattern": "sudo /usr/pgsql-{ver}/bin/postgresql-{ver}-setup initdb",
      "start_pattern": "sudo systemctl enable --now postgresql-{ver}"
    },
    "el10": {
      "label": "Enterprise Linux 10 (RHEL / Rocky / Alma)",
      "family": "el",
      "version": "10",
      "pkg_manager": "dnf",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [
        "sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm",
        "sudo dnf config-manager --set-enabled crb"
      ],
      "repo_install": "sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm",
      "install_pattern": "sudo dnf install -y {package}",
      "init_pattern": "sudo /usr/pgsql-{ver}/bin/postgresql-{ver}-setup initdb",
      "start_pattern": "sudo systemctl enable --now postgresql-{ver}"
    },
    "debian11": {
      "label": "Debian 11 (Bullseye)",
      "family": "debian",
      "version": "11",
      "pkg_manager": "apt",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [],
      "repo_install": "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update",
      "install_pattern": "sudo apt-get install -y {package}",
      "init_pattern": "sudo pg_ctlcluster {ver} main start",
      "start_pattern": "sudo systemctl enable --now postgresql"
    },
    "debian12": {
      "label": "Debian 12 (Bookworm)",
      "family": "debian",
      "version": "12",
      "pkg_manager": "apt",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [],
      "repo_install": "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update",
      "install_pattern": "sudo apt-get install -y {package}",
      "init_pattern": "sudo pg_ctlcluster {ver} main start",
      "start_pattern": "sudo systemctl enable --now postgresql"
    },
    "debian13": {
      "label": "Debian 13 (Trixie)",
      "family": "debian",
      "version": "13",
      "pkg_manager": "apt",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [],
      "repo_install": "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update",
      "install_pattern": "sudo apt-get install -y {package}",
      "init_pattern": "sudo pg_ctlcluster {ver} main start",
      "start_pattern": "sudo systemctl enable --now postgresql"
    },
    "ubuntu2204": {
      "label": "Ubuntu 22.04 (Jammy)",
      "family": "ubuntu",
      "version": "22.04",
      "pkg_manager": "apt",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [],
      "repo_install": "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update",
      "install_pattern": "sudo apt-get install -y {package}",
      "init_pattern": "sudo pg_ctlcluster {ver} main start",
      "start_pattern": "sudo systemctl enable --now postgresql"
    },
    "ubuntu2404": {
      "label": "Ubuntu 24.04 (Noble)",
      "family": "ubuntu",
      "version": "24.04",
      "pkg_manager": "apt",
      "architectures": ["x86_64", "aarch64"],
      "prerequisites": [],
      "repo_install": "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update",
      "install_pattern": "sudo apt-get install -y {package}",
      "init_pattern": "sudo pg_ctlcluster {ver} main start",
      "start_pattern": "sudo systemctl enable --now postgresql"
    }
  },
  "pg_versions": ["16", "17", "18"],
  "default_platform": "el9",
  "default_arch": "x86_64",
  "default_pg_version": "17"
}
```

**Step 2: Validate JSON**

Run: `python3 -c "import json; d=json.load(open('package-catalog/catalog.json')); print(f'{len(d[\"categories\"])} categories, {sum(len(c[\"packages\"]) for c in d[\"categories\"])} packages, {len(d[\"platforms\"])} platforms')"`

Expected: `5 categories, 24 packages, 7 platforms`

**Step 3: Run quality gate**

Run: `make test-all`
Expected: All checks pass — shellcheck on scripts, jq on JSON, catalog
structure validation.

**Step 4: Commit**

```bash
git add package-catalog/catalog.json
git commit -m "feat: add package catalog data

Source of truth for all package metadata, platform configs, and
install command patterns. Consumed by the catalog web page and
bare-metal guide."
```

---

## Task 4: Package Catalog Web Page

**Files:**
- Create: `package-catalog/index.html`
- Reference: `package-catalog/catalog.json` (from Task 3)
- Test: open in browser via `bash package-catalog/serve.sh`

This is a single-file vanilla HTML/CSS/JS app with three zones:
1. Interactive Selector (4 dropdowns)
2. Generated Install Commands (adapts to selection)
3. Browsable Package Catalog (expandable categories)

**Step 1: Create index.html — HTML structure**

Write `package-catalog/index.html` with the complete HTML skeleton. Key sections:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>pgEdge Enterprise Postgres — Package Catalog</title>
  <style>
    /* See Step 2 for styles */
  </style>
</head>
<body>
  <header>
    <h1>pgEdge Enterprise Postgres</h1>
    <p class="subtitle">Browse the full package ecosystem. Pick your platform, copy the commands, start building.</p>
  </header>

  <main>
    <!-- Zone 1: Interactive Selector -->
    <section id="selector" class="zone">
      <h2>Configure Your Install</h2>
      <div class="selector-grid">
        <div class="selector-group">
          <label for="platform">Platform</label>
          <select id="platform"></select>
        </div>
        <div class="selector-group">
          <label for="arch">Architecture</label>
          <select id="arch"></select>
        </div>
        <div class="selector-group">
          <label for="pg-version">PostgreSQL</label>
          <select id="pg-version"></select>
        </div>
        <div class="selector-group">
          <label for="meta-package">Package</label>
          <select id="meta-package"></select>
        </div>
      </div>
    </section>

    <!-- Zone 2: Generated Commands -->
    <section id="commands" class="zone">
      <div class="commands-header">
        <h2>Install Commands</h2>
        <button id="copy-all" class="copy-btn" title="Copy all commands">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
          Copy All
        </button>
      </div>
      <pre id="install-commands"><code></code></pre>
    </section>

    <!-- Zone 3: Package Catalog -->
    <section id="catalog" class="zone">
      <h2>Package Catalog</h2>
      <p class="zone-desc">Click a category to expand. Click a package for its individual install command.</p>
      <div id="catalog-tree"></div>
    </section>
  </main>

  <footer>
    <p>
      <a href="https://docs.pgedge.com/enterprise/">Documentation</a> &middot;
      <a href="https://github.com/pgEdge">GitHub</a> &middot;
      <a href="https://pgedge.com">pgedge.com</a>
    </p>
  </footer>

  <script>
    /* See Step 3-5 for JavaScript */
  </script>
</body>
</html>
```

**Step 2: Add CSS styles**

Inside the `<style>` tag. Design principles:
- Clean, professional look. Dark code blocks on light background.
- Responsive grid for selectors (2x2 on mobile, 4-col on desktop).
- Monospace code blocks with syntax highlighting for bash comments.
- Expandable category cards for the catalog.
- Match pgEdge brand colors: dark navy (#0D2137), teal accents (#2DD4BF).

```css
:root {
  --bg: #f8fafc;
  --surface: #ffffff;
  --text: #1e293b;
  --text-muted: #64748b;
  --border: #e2e8f0;
  --navy: #0D2137;
  --teal: #2DD4BF;
  --teal-dark: #14b8a6;
  --code-bg: #0f172a;
  --code-text: #e2e8f0;
  --green: #22c55e;
  --radius: 12px;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.6;
}

header {
  background: var(--navy);
  color: white;
  padding: 3rem 2rem 2.5rem;
  text-align: center;
}
header h1 { font-size: 2rem; margin-bottom: 0.5rem; }
header .subtitle { color: #94a3b8; font-size: 1.1rem; max-width: 600px; margin: 0 auto; }

main { max-width: 900px; margin: 0 auto; padding: 2rem 1rem; }

.zone { margin-bottom: 2.5rem; }
.zone h2 { font-size: 1.3rem; margin-bottom: 0.75rem; }
.zone-desc { color: var(--text-muted); font-size: 0.9rem; margin-bottom: 1rem; }

/* Zone 1: Selector */
.selector-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1rem;
}
.selector-group label {
  display: block;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}
.selector-group select {
  width: 100%;
  padding: 0.6rem 0.75rem;
  border: 1px solid var(--border);
  border-radius: 8px;
  font-size: 0.95rem;
  background: var(--surface);
  cursor: pointer;
}
.selector-group select:focus {
  outline: none;
  border-color: var(--teal);
  box-shadow: 0 0 0 3px rgba(45, 212, 191, 0.15);
}

/* Zone 2: Commands */
.commands-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}
.copy-btn {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.4rem 0.8rem;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--surface);
  font-size: 0.85rem;
  cursor: pointer;
  color: var(--text-muted);
  transition: all 0.15s;
}
.copy-btn:hover { border-color: var(--teal); color: var(--teal-dark); }
.copy-btn.copied { border-color: var(--green); color: var(--green); }

#install-commands {
  background: var(--code-bg);
  color: var(--code-text);
  padding: 1.5rem;
  border-radius: var(--radius);
  overflow-x: auto;
  font-size: 0.9rem;
  line-height: 1.7;
}
#install-commands .comment { color: #64748b; }

/* Zone 3: Catalog */
.category {
  border: 1px solid var(--border);
  border-radius: var(--radius);
  margin-bottom: 0.75rem;
  overflow: hidden;
  background: var(--surface);
}
.category-header {
  padding: 0.75rem 1rem;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 600;
  user-select: none;
}
.category-header:hover { background: #f1f5f9; }
.category-header .count { color: var(--text-muted); font-weight: 400; font-size: 0.85rem; }
.category-header .arrow { transition: transform 0.2s; }
.category.open .category-header .arrow { transform: rotate(90deg); }

.category-body { display: none; border-top: 1px solid var(--border); }
.category.open .category-body { display: block; }

.pkg-row {
  padding: 0.6rem 1rem;
  border-bottom: 1px solid var(--border);
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}
.pkg-row:last-child { border-bottom: none; }
.pkg-row:hover { background: #f8fafc; }
.pkg-name { font-weight: 500; font-size: 0.95rem; }
.pkg-desc { color: var(--text-muted); font-size: 0.85rem; }
.pkg-meta { font-size: 0.8rem; color: var(--text-muted); white-space: nowrap; }
.pkg-badges { display: flex; gap: 0.3rem; flex-wrap: wrap; }
.badge {
  display: inline-block;
  padding: 0.1rem 0.4rem;
  border-radius: 4px;
  font-size: 0.75rem;
  background: #f1f5f9;
  color: var(--text-muted);
}
.badge.included { background: #ecfdf5; color: #059669; }

.pkg-install-cmd {
  display: none;
  padding: 0.5rem 1rem 0.75rem;
  background: var(--code-bg);
  font-family: monospace;
  font-size: 0.85rem;
  color: var(--code-text);
}
.pkg-row.expanded + .pkg-install-cmd { display: block; }

footer {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
  font-size: 0.9rem;
}
footer a { color: var(--teal-dark); text-decoration: none; }
footer a:hover { text-decoration: underline; }
```

**Step 3: Add JavaScript — Data loading and selector logic**

```javascript
let catalog = null;

async function init() {
  const resp = await fetch("catalog.json");
  catalog = await resp.json();
  populateSelectors();
  updateCommands();
  renderCatalog();
}

function populateSelectors() {
  const platformEl = document.getElementById("platform");
  const archEl = document.getElementById("arch");
  const pgEl = document.getElementById("pg-version");
  const metaEl = document.getElementById("meta-package");

  // Platforms
  for (const [key, plat] of Object.entries(catalog.platforms)) {
    const opt = document.createElement("option");
    opt.value = key;
    opt.textContent = plat.label;
    if (key === catalog.default_platform) opt.selected = true;
    platformEl.appendChild(opt);
  }

  // PG versions
  for (const ver of catalog.pg_versions) {
    const opt = document.createElement("option");
    opt.value = ver;
    opt.textContent = `PostgreSQL ${ver}`;
    if (ver === catalog.default_pg_version) opt.selected = true;
    pgEl.appendChild(opt);
  }

  // Meta-packages
  for (const mp of catalog.meta_packages) {
    const opt = document.createElement("option");
    opt.value = mp.id;
    opt.textContent = mp.label;
    metaEl.appendChild(opt);
  }

  updateArchOptions();

  platformEl.addEventListener("change", () => { updateArchOptions(); updateCommands(); });
  archEl.addEventListener("change", updateCommands);
  pgEl.addEventListener("change", updateCommands);
  metaEl.addEventListener("change", updateCommands);
}

function updateArchOptions() {
  const archEl = document.getElementById("arch");
  const platform = catalog.platforms[document.getElementById("platform").value];
  const currentArch = archEl.value;
  archEl.innerHTML = "";
  for (const arch of platform.architectures) {
    const opt = document.createElement("option");
    opt.value = arch;
    opt.textContent = arch === "x86_64" ? "x86_64 (Intel/AMD)" : "aarch64 (ARM)";
    if (arch === currentArch || arch === catalog.default_arch) opt.selected = true;
    archEl.appendChild(opt);
  }
}
```

**Step 4: Add JavaScript — Command generation**

```javascript
function updateCommands() {
  const platformKey = document.getElementById("platform").value;
  const pgVer = document.getElementById("pg-version").value;
  const metaId = document.getElementById("meta-package").value;
  const platform = catalog.platforms[platformKey];
  const meta = catalog.meta_packages.find(m => m.id === metaId);

  const pkgName = platform.pkg_manager === "dnf"
    ? meta.rpm_pattern.replace("{ver}", pgVer)
    : meta.deb_pattern.replace("{ver}", pgVer);

  const lines = [];

  // Prerequisites
  if (platform.prerequisites.length > 0) {
    lines.push({ text: "# 1. Configure prerequisites", comment: true });
    platform.prerequisites.forEach(cmd => lines.push({ text: cmd }));
    lines.push({ text: "" });
    lines.push({ text: "# 2. Add pgEdge repository", comment: true });
  } else {
    lines.push({ text: "# 1. Add pgEdge repository", comment: true });
  }
  lines.push({ text: platform.repo_install });
  lines.push({ text: "" });

  const stepNum = platform.prerequisites.length > 0 ? 3 : 2;
  lines.push({ text: `# ${stepNum}. Install ${meta.label}`, comment: true });
  lines.push({ text: platform.install_pattern.replace("{package}", pkgName) });
  lines.push({ text: "" });

  lines.push({ text: `# ${stepNum + 1}. Initialize and start`, comment: true });
  lines.push({ text: platform.init_pattern.replace(/{ver}/g, pgVer) });
  lines.push({ text: platform.start_pattern.replace(/{ver}/g, pgVer) });

  const codeEl = document.querySelector("#install-commands code");
  codeEl.innerHTML = lines.map(l => {
    if (l.comment) return `<span class="comment">${escapeHtml(l.text)}</span>`;
    return escapeHtml(l.text);
  }).join("\n");
}

function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// Copy button
document.getElementById("copy-all").addEventListener("click", function() {
  const code = document.querySelector("#install-commands code").textContent;
  navigator.clipboard.writeText(code).then(() => {
    this.classList.add("copied");
    this.querySelector("svg + *") && (this.lastChild.textContent = "Copied!");
    setTimeout(() => {
      this.classList.remove("copied");
      this.lastChild.textContent = "Copy All";
    }, 2000);
  });
});
```

**Step 5: Add JavaScript — Catalog tree rendering**

```javascript
function renderCatalog() {
  const tree = document.getElementById("catalog-tree");
  const pgVer = document.getElementById("pg-version").value;
  const platformKey = document.getElementById("platform").value;
  const platform = catalog.platforms[platformKey];

  tree.innerHTML = "";

  for (const cat of catalog.categories) {
    const div = document.createElement("div");
    div.className = "category";

    const header = document.createElement("div");
    header.className = "category-header";
    header.innerHTML = `
      <span>${cat.name} <span class="count">(${cat.packages.length})</span></span>
      <span class="arrow">&#9654;</span>
    `;
    header.addEventListener("click", () => div.classList.toggle("open"));

    const body = document.createElement("div");
    body.className = "category-body";

    for (const pkg of cat.packages) {
      const row = document.createElement("div");
      row.className = "pkg-row";

      const badges = pkg.included_in.map(id => {
        const mp = catalog.meta_packages.find(m => m.id === id);
        return `<span class="badge included">${mp ? mp.label.split("(")[0].trim() : id}</span>`;
      }).join("");

      const pgBadges = pkg.pg_versions.map(v =>
        `<span class="badge">PG ${v}</span>`
      ).join("");

      row.innerHTML = `
        <div>
          <div class="pkg-name">${pkg.name}</div>
          <div class="pkg-desc">${pkg.description}</div>
          <div class="pkg-badges" style="margin-top:0.3rem">${pgBadges}</div>
        </div>
        <div class="pkg-meta">${badges}</div>
      `;

      // Expand to show install command on click
      const cmdDiv = document.createElement("div");
      cmdDiv.className = "pkg-install-cmd";
      // Individual package install commands would need package-specific names
      // For now show the meta-package that includes it
      cmdDiv.textContent = `# ${pkg.name} is included in: ${pkg.included_in.map(id =>
        catalog.meta_packages.find(m => m.id === id)?.label
      ).join(", ")}`;

      row.addEventListener("click", () => {
        row.classList.toggle("expanded");
      });

      body.appendChild(row);
      body.appendChild(cmdDiv);
    }

    div.appendChild(header);
    div.appendChild(body);
    tree.appendChild(div);
  }

  // Re-render catalog when PG version changes (for version badges)
  document.getElementById("pg-version").addEventListener("change", renderCatalog);
}

document.addEventListener("DOMContentLoaded", init);
```

**Step 6: Test the page locally**

Run: `bash package-catalog/serve.sh`
Then open `http://localhost:8080` in a browser.

Verify:
- [ ] All 4 dropdowns render with correct options
- [ ] Default selection is EL 9 / x86_64 / PG 17 / Enterprise All
- [ ] Changing platform updates prerequisites in commands
- [ ] Changing to Debian/Ubuntu removes EPEL/CRB prerequisites
- [ ] Copy All button works
- [ ] All 5 categories render in catalog
- [ ] Categories expand/collapse on click
- [ ] Package badges show PG versions and meta-package inclusion
- [ ] Page is responsive on narrow viewport

**Step 7: Run quality gate**

Run: `make test-all`
Expected: All checks pass.

**Step 8: Commit**

```bash
git add package-catalog/index.html package-catalog/serve.sh
git commit -m "feat: add interactive package catalog web page

Single-file vanilla HTML/CSS/JS app with:
- Platform/arch/PG version selector dropdowns
- Dynamic install command generation
- Browsable categorized package catalog
- Copy-to-clipboard support

Reads from catalog.json. No build step, no dependencies."
```

---

## Task 5: Control Plane Quickstart

**Files:**
- Create: `control-plane/guide.sh`
- Create: `control-plane/scripts/setup.sh`
- Create: `control-plane/WALKTHROUGH.md`
- Reference: `lib/helpers.sh` (from Task 2)
- Test: `shellcheck control-plane/guide.sh control-plane/scripts/setup.sh`

**Caveat from design doc:** The exact Control Plane API shape (especially PATCH for adding nodes, `"replication":"multi-master"`) must be validated against the real CP v0.6 API. The scripts use the endpoints from the design doc as the starting point. Comments mark lines that need API validation.

**Step 1: Write control-plane/scripts/setup.sh**

This bootstraps Control Plane — pulls the image, initializes Docker Swarm if needed, starts the container, and runs health checks.

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/helpers.sh"
setup_trap

CP_IMAGE="${CP_IMAGE:-pgedge/control-plane:latest}"
CP_CONTAINER="pgedge-cp"
CP_PORT="${CP_PORT:-3000}"
CP_DATA="${CP_DATA:-$HOME/pgedge/control-plane}"

check_existing() {
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
    info "Control Plane is already running (container: ${CP_CONTAINER})"
    info "API: http://localhost:${CP_PORT}"
    return 0
  fi
  return 1
}

ensure_docker() {
  require_cmd docker "Install Docker: https://docs.docker.com/get-docker/"

  if ! docker info &>/dev/null; then
    error "Docker daemon is not running. Please start Docker and try again."
    exit 1
  fi
}

ensure_swarm() {
  if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
    info "Initializing Docker Swarm..."
    docker swarm init 2>/dev/null || true
  fi
}

start_control_plane() {
  mkdir -p "$CP_DATA"

  start_spinner "Pulling Control Plane image..."
  docker pull "$CP_IMAGE" >/dev/null 2>&1
  stop_spinner
  info "Image pulled: $CP_IMAGE"

  start_spinner "Starting Control Plane..."
  docker run -d --name "$CP_CONTAINER" \
    --network host \
    -v "$CP_DATA":/data \
    "$CP_IMAGE" >/dev/null 2>&1
  stop_spinner
  info "Container started: $CP_CONTAINER"
}

wait_for_healthy() {
  start_spinner "Waiting for Control Plane API..."
  local retries=30
  while [ "$retries" -gt 0 ]; do
    if curl -sf "http://localhost:${CP_PORT}/v1/cluster/init" >/dev/null 2>&1; then
      stop_spinner
      info "Control Plane running on http://localhost:${CP_PORT}"
      return 0
    fi
    sleep 2
    retries=$((retries - 1))
  done
  stop_spinner
  error "Control Plane did not become healthy within 60 seconds."
  exit 1
}

cleanup() {
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CP_CONTAINER}$"; then
    info "Stopping and removing Control Plane container..."
    docker rm -f "$CP_CONTAINER" >/dev/null 2>&1
    info "Container removed."
  fi
}

# ── Main ────────────────────────────────────────────────────────────────────

case "${1:-setup}" in
  setup)
    if check_existing; then
      exit 0
    fi
    ensure_docker
    ensure_swarm
    start_control_plane
    wait_for_healthy
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Usage: $0 {setup|cleanup}"
    exit 1
    ;;
esac
```

**Step 2: Write control-plane/guide.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/helpers.sh"
setup_trap

CP_PORT="${CP_PORT:-3000}"
CP_URL="http://localhost:${CP_PORT}"

# ── Welcome ─────────────────────────────────────────────────────────────────

header "pgEdge Enterprise — Get Running Fast"

explain "This guide walks you through the full Control Plane journey:"
explain ""
explain "  1. Start Control Plane"
explain "  2. Deploy a single primary"
explain "  3. Add read replicas & HA"
explain "  4. Go multi-master"
explain ""
explain "You'll go from zero to active-active replication in minutes."
explain ""
explain "${DIM}Prerequisites: Docker (with host networking)${RESET}"

prompt_continue

# ── Step 1: Start Control Plane ─────────────────────────────────────────────

header "Step 1: Start Control Plane"

explain "Control Plane is a lightweight orchestrator that manages your Postgres"
explain "instances. It runs as a single container and exposes a REST API."

prompt_continue

explain "Setting up Control Plane..."
echo ""
bash "$SCRIPT_DIR/scripts/setup.sh" setup

prompt_continue

# ── Step 2: Deploy a Single Primary ─────────────────────────────────────────

header "Step 2: Deploy a Single Primary"

explain "Control Plane will pull a pgEdge Enterprise container image, configure"
explain "PostgreSQL, and start it. You'll have a production-ready primary with"
explain "pgBackRest backups already configured."

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s -X POST ${CP_URL}/v1/databases \\
    -H 'Content-Type: application/json' \\
    -d '{\"name\":\"demo\",\"nodes\":[{\"name\":\"n1\",\"port\":6432}]}' | jq ."

start_spinner "Waiting for database to be ready..."
sleep 5  # Replace with actual health polling
stop_spinner

info "PostgreSQL 17 running on port 6432"

prompt_run "psql -h localhost -p 6432 -U admin -d demo -c \"SELECT version();\""

prompt_continue

# ── Step 3: Add Read Replicas & HA ──────────────────────────────────────────

header "Step 3: Add Read Replicas & HA"

explain "Control Plane will add a streaming replica with automatic failover via"
explain "Patroni. If n1 goes down, n2 promotes automatically."

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s -X PATCH ${CP_URL}/v1/databases/demo \\
    -H 'Content-Type: application/json' \\
    -d '{\"nodes\":[
      {\"name\":\"n1\",\"port\":6432},
      {\"name\":\"n2\",\"port\":6433,\"role\":\"replica\"}
    ]}' | jq ."

start_spinner "Waiting for replica to sync..."
sleep 5  # Replace with actual sync polling
stop_spinner

info "n2 streaming from n1"

prompt_run "curl -s ${CP_URL}/v1/databases/demo | jq '.nodes'"

prompt_continue

# ── Step 4: Go Multi-Master ─────────────────────────────────────────────────

header "Step 4: Go Multi-Master"

explain "Control Plane will enable Spock active-active replication across all"
explain "three nodes. Every node accepts writes. Conflict resolution happens"
explain "automatically at the column level."

# NOTE: API endpoint needs validation against CP v0.6 API
prompt_run "curl -s -X PATCH ${CP_URL}/v1/databases/demo \\
    -H 'Content-Type: application/json' \\
    -d '{\"nodes\":[
      {\"name\":\"n1\",\"port\":6432},
      {\"name\":\"n2\",\"port\":6433},
      {\"name\":\"n3\",\"port\":6434}
    ],\"replication\":\"multi-master\"}' | jq ."

start_spinner "Enabling Spock multi-master replication..."
sleep 5  # Replace with actual replication health polling
stop_spinner

info "n1 <-> n2 <-> n3 (active-active)"

explain ""
explain "Let's prove it works. Write on n1, read on n3:"

prompt_run "psql -h localhost -p 6432 -d demo -c \"CREATE TABLE IF NOT EXISTS test (id int, msg text);\""
prompt_run "psql -h localhost -p 6432 -d demo -c \"INSERT INTO test VALUES (1, 'from n1');\""
prompt_run "psql -h localhost -p 6434 -d demo -c \"SELECT * FROM test;\""

explain "Now write on n3, read on n1:"

prompt_run "psql -h localhost -p 6434 -d demo -c \"INSERT INTO test VALUES (2, 'from n3');\""
prompt_run "psql -h localhost -p 6432 -d demo -c \"SELECT * FROM test;\""

# ── Completion ──────────────────────────────────────────────────────────────

header "Done!"

info "You've gone from a single primary to full multi-master replication,"
info "all orchestrated by Control Plane."
echo ""
explain "What's next:"
explain ""
explain "  Browse packages:       http://localhost:8080  (run: ../package-catalog/serve.sh)"
explain "  Try bare metal:        ../bare-metal/guide.sh"
explain "  Full documentation:    https://docs.pgedge.com/enterprise/"
echo ""
explain "${DIM}To clean up: bash $SCRIPT_DIR/scripts/setup.sh cleanup${RESET}"
echo ""
```

**Step 3: Write control-plane/WALKTHROUGH.md**

```markdown
# pgEdge Control Plane — Get Running Fast

In this walkthrough you'll progressively build from a single PostgreSQL primary
through HA to full multi-master replication, all orchestrated by pgEdge Control Plane.

Click the **Run** button on any code block to execute it directly in the terminal.

## Prerequisites

- Docker (with host networking enabled)
- curl and jq

## Step 1: Start Control Plane

Initialize Docker Swarm (if not already active):

\`\`\`bash
docker swarm init 2>/dev/null || echo "Swarm already active"
\`\`\`

Start the Control Plane container:

\`\`\`bash
docker run -d --name pgedge-cp \
    --network host \
    -v ~/pgedge/control-plane:/data \
    pgedge/control-plane:latest
\`\`\`

Wait for it to become healthy:

\`\`\`bash
until curl -sf http://localhost:3000/v1/cluster/init >/dev/null 2>&1; do sleep 2; done
echo "Control Plane is ready"
\`\`\`

## Step 2: Deploy a Single Primary

Create a database with one node:

\`\`\`bash
curl -s -X POST http://localhost:3000/v1/databases \
    -H 'Content-Type: application/json' \
    -d '{"name":"demo","nodes":[{"name":"n1","port":6432}]}' | jq .
\`\`\`

Verify PostgreSQL is running:

\`\`\`bash
psql -h localhost -p 6432 -U admin -d demo -c "SELECT version();"
\`\`\`

## Step 3: Add Read Replicas & HA

Add a streaming replica with automatic failover:

\`\`\`bash
curl -s -X PATCH http://localhost:3000/v1/databases/demo \
    -H 'Content-Type: application/json' \
    -d '{"nodes":[
      {"name":"n1","port":6432},
      {"name":"n2","port":6433,"role":"replica"}
    ]}' | jq .
\`\`\`

Check cluster status:

\`\`\`bash
curl -s http://localhost:3000/v1/databases/demo | jq '.nodes'
\`\`\`

## Step 4: Go Multi-Master

Enable Spock active-active replication across three nodes:

\`\`\`bash
curl -s -X PATCH http://localhost:3000/v1/databases/demo \
    -H 'Content-Type: application/json' \
    -d '{"nodes":[
      {"name":"n1","port":6432},
      {"name":"n2","port":6433},
      {"name":"n3","port":6434}
    ],"replication":"multi-master"}' | jq .
\`\`\`

Prove replication works — write on n1, read on n3:

\`\`\`bash
psql -h localhost -p 6432 -d demo -c "CREATE TABLE IF NOT EXISTS test (id int, msg text);"
psql -h localhost -p 6432 -d demo -c "INSERT INTO test VALUES (1, 'from n1');"
psql -h localhost -p 6434 -d demo -c "SELECT * FROM test;"
\`\`\`

Write on n3, read on n1:

\`\`\`bash
psql -h localhost -p 6434 -d demo -c "INSERT INTO test VALUES (2, 'from n3');"
psql -h localhost -p 6432 -d demo -c "SELECT * FROM test;"
\`\`\`

## Cleanup

\`\`\`bash
docker rm -f pgedge-cp
\`\`\`

## What's Next

- **Browse all packages:** Run `../package-catalog/serve.sh` and open http://localhost:8080
- **Try bare metal:** Run `../bare-metal/guide.sh`
- **Documentation:** https://docs.pgedge.com/enterprise/
```

**Step 4: Make scripts executable**

```bash
chmod +x control-plane/guide.sh control-plane/scripts/setup.sh
```

**Step 5: Run quality gate**

Run: `make test-all`
Expected: All checks pass.

**Step 6: Commit**

```bash
git add control-plane/
git commit -m "feat: add Control Plane quickstart

Interactive guide.sh with 4-step journey (single primary -> HA ->
multi-master), Runme-compatible WALKTHROUGH.md, and setup.sh for
bootstrapping. API endpoints marked for CP v0.6 validation."
```

---

## Task 6: Bare Metal Walkthrough

**Files:**
- Create: `bare-metal/guide.sh`
- Create: `bare-metal/scripts/setup-replication.sh`
- Create: `bare-metal/WALKTHROUGH.md`
- Reference: `lib/helpers.sh` (from Task 2)
- Reference: `package-catalog/catalog.json` (from Task 3)
- Test: `shellcheck bare-metal/guide.sh bare-metal/scripts/setup-replication.sh`

**Caveat from design doc:** The Spock SQL commands (`spock.node_create`, `spock.sub_create`) must be validated against the Spock 5.0 API.

**Step 1: Write bare-metal/guide.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/helpers.sh"
setup_trap

PG_VERSION="${PG_VERSION:-17}"

# ── Welcome ─────────────────────────────────────────────────────────────────

header "pgEdge Enterprise — Explore & Install"

explain "This guide walks you through installing pgEdge Enterprise Postgres"
explain "on your Linux server:"
explain ""
explain "  1. Explore what's available"
explain "  2. Install Enterprise Postgres"
explain "  3. Verify extensions"
explain "  4. Set up replication (optional — requires 2+ VMs)"
explain ""
explain "${DIM}Prerequisites: Linux VM (EL 9/10, Debian 11-13, Ubuntu 22.04/24.04), sudo${RESET}"

prompt_continue

# ── Step 1: Explore What's Available ────────────────────────────────────────

header "Step 1: Explore What's Available"

explain "pgEdge Enterprise Postgres includes 30+ packages across 5 categories:"
echo ""
explain "  ${BOLD}Core:${RESET}        PostgreSQL ${PG_VERSION}, Spock 5.0, lolor, Snowflake"
explain "  ${BOLD}AI/ML:${RESET}       pgVector, MCP Server, RAG Server, Vectorizer"
explain "  ${BOLD}Management:${RESET}  pgAdmin, pgBouncer, pgBackRest, ACE, Radar"
explain "  ${BOLD}Extensions:${RESET}  PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB..."
explain "  ${BOLD}HA:${RESET}          Patroni, etcd"
echo ""
explain "${DIM}Browse the full catalog: http://localhost:8080 (run: ../package-catalog/serve.sh)${RESET}"

prompt_continue

# ── Step 2: Install Enterprise Postgres ─────────────────────────────────────

header "Step 2: Install Enterprise Postgres"

detect_os

explain ""
explain "We'll install the full Enterprise meta-package, which includes"
explain "PostgreSQL ${PG_VERSION} plus all extensions, pgAdmin, pgBouncer, and pgBackRest."

prompt_continue

case "$OS_FAMILY" in
  el)
    # Prerequisites
    if [ "$OS_MAJOR" = "9" ]; then
      prompt_run "sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm"
      prompt_run "sudo dnf config-manager --set-enabled crb"
    elif [ "$OS_MAJOR" = "10" ]; then
      prompt_run "sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm"
      prompt_run "sudo dnf config-manager --set-enabled crb"
    fi

    # Repo + install
    prompt_run "sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm"
    prompt_run "sudo dnf install -y pgedge-enterprise-all_${PG_VERSION}"

    # Init + start
    prompt_run "sudo /usr/pgsql-${PG_VERSION}/bin/postgresql-${PG_VERSION}-setup initdb"
    prompt_run "sudo systemctl enable --now postgresql-${PG_VERSION}"
    ;;

  debian|ubuntu)
    # Repo + install
    prompt_run "sudo curl -sSL https://apt.pgedge.com/repodeb/pgedge-release_latest_all.deb -o /tmp/pgedge-release.deb && sudo dpkg -i /tmp/pgedge-release.deb && sudo apt-get update"
    prompt_run "sudo apt-get install -y pgedge-enterprise-all-${PG_VERSION}"

    # Init + start
    prompt_run "sudo pg_ctlcluster ${PG_VERSION} main start"
    prompt_run "sudo systemctl enable --now postgresql"
    ;;
esac

info "pgEdge Enterprise Postgres ${PG_VERSION} installed and running"

prompt_continue

# ── Step 3: Verify Extensions ──────────────────────────────────────────────

header "Step 3: Verify Extensions"

explain "These extensions are installed as shared libraries but not yet enabled"
explain "in your database. Enable them with CREATE EXTENSION when needed."

prompt_run "sudo -u postgres psql -c \"SELECT name, default_version, comment
           FROM pg_available_extensions
           WHERE name IN ('spock','vector','postgis','pgaudit')
           ORDER BY name;\""

prompt_continue

# ── Step 4: Replication (Optional) ──────────────────────────────────────────

header "Step 4: Set Up Replication (Optional)"

explain "Multi-master replication requires 2 or more VMs, each with pgEdge"
explain "Enterprise Postgres installed (repeat Steps 1-3 on each VM)."
echo ""
read -rp "  Do you have 2+ VMs ready? [y/N] " HAS_VMS </dev/tty

if [[ "${HAS_VMS,,}" == "y"* ]]; then
  bash "$SCRIPT_DIR/scripts/setup-replication.sh"
else
  explain ""
  explain "No problem! You can set up replication later."
  explain "Run: bash $SCRIPT_DIR/scripts/setup-replication.sh"
fi

# ── Completion ──────────────────────────────────────────────────────────────

header "Done!"

info "You've installed pgEdge Enterprise Postgres and all extensions."
echo ""
explain "What's next:"
explain ""
explain "  Browse packages:       http://localhost:8080  (run: ../package-catalog/serve.sh)"
explain "  Try Control Plane:     ../control-plane/guide.sh"
explain "  Full documentation:    https://docs.pgedge.com/enterprise/"
echo ""
explain "${BOLD}Started with bare metal?${RESET} Add Control Plane to orchestrate what"
explain "you already have — backups, failover, and scaling, all managed"
explain "through a single API."
echo ""
```

**Step 2: Write bare-metal/scripts/setup-replication.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/helpers.sh"
setup_trap

PG_VERSION="${PG_VERSION:-17}"

header "Multi-Master Replication Setup"

explain "This will configure Spock active-active replication between two nodes."
explain "Both nodes must have pgEdge Enterprise Postgres ${PG_VERSION} installed."

echo ""
read -rp "  This node's IP address: " NODE1_IP </dev/tty
read -rp "  Other node's IP address: " NODE2_IP </dev/tty
echo ""

DB_NAME="${DB_NAME:-demo}"

# ── Configure for logical replication ───────────────────────────────────────

header "Configuring PostgreSQL for Logical Replication"

explain "Setting wal_level=logical and loading Spock on this node..."

prompt_run "sudo -u postgres psql -c \"
  ALTER SYSTEM SET wal_level = 'logical';
  ALTER SYSTEM SET max_worker_processes = 16;
  ALTER SYSTEM SET max_replication_slots = 16;
  ALTER SYSTEM SET shared_preload_libraries = 'spock';\""

prompt_run "sudo systemctl restart postgresql-${PG_VERSION}"

explain ""
warn "Now run the same ALTER SYSTEM commands on ${NODE2_IP} and restart PostgreSQL there."
warn "Press Enter when the other node is configured."
prompt_continue

# ── Create database and enable Spock ────────────────────────────────────────

header "Enabling Spock"

prompt_run "sudo -u postgres createdb ${DB_NAME} 2>/dev/null || echo 'Database already exists'"
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"CREATE EXTENSION IF NOT EXISTS spock;\""

explain ""
warn "Now create the '${DB_NAME}' database and enable Spock on ${NODE2_IP}."
warn "Press Enter when ready."
prompt_continue

# ── Create nodes ────────────────────────────────────────────────────────────

header "Creating Spock Nodes"

# NOTE: spock.node_create signature needs validation against Spock 5.0 docs
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.node_create(
    node_name := 'n1',
    dsn := 'host=${NODE1_IP} dbname=${DB_NAME}');\""

explain ""
warn "Now run on ${NODE2_IP}:"
echo ""
show_cmd "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.node_create(
    node_name := 'n2',
    dsn := 'host=${NODE2_IP} dbname=${DB_NAME}');\""
echo ""
warn "Press Enter when done."
prompt_continue

# ── Create subscriptions ───────────────────────────────────────────────────

header "Creating Bidirectional Subscriptions"

# NOTE: spock.sub_create signature needs validation against Spock 5.0 docs
explain "Creating subscription from n1 to n2..."
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.sub_create(
    subscription_name := 'n1_to_n2',
    provider_dsn := 'host=${NODE2_IP} dbname=${DB_NAME}');\""

explain ""
warn "Now run on ${NODE2_IP}:"
echo ""
show_cmd "sudo -u postgres psql -d ${DB_NAME} -c \"SELECT spock.sub_create(
    subscription_name := 'n2_to_n1',
    provider_dsn := 'host=${NODE1_IP} dbname=${DB_NAME}');\""
echo ""
warn "Press Enter when done."
prompt_continue

# ── Verify replication ──────────────────────────────────────────────────────

header "Verifying Replication"

explain "Let's create a test table and prove data replicates both ways."

prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"CREATE TABLE IF NOT EXISTS test (id int, msg text);\""

explain "Write on this node (n1):"
prompt_run "sudo -u postgres psql -d ${DB_NAME} -c \"INSERT INTO test VALUES (1, 'from n1');\""

explain "Read from the other node (n2):"
prompt_run "psql -h ${NODE2_IP} -U postgres -d ${DB_NAME} -c \"SELECT * FROM test;\""

info ""
info "If you see 'from n1' on the other node, replication is working!"
explain ""
explain "Try writing on n2 and reading back here to confirm bidirectional replication."
echo ""
```

**Step 3: Write bare-metal/WALKTHROUGH.md**

```markdown
# pgEdge Enterprise — Explore & Install

In this walkthrough you'll install pgEdge Enterprise Postgres on a Linux server,
verify the included extensions, and optionally configure multi-master replication.

Click the **Run** button on any code block to execute it directly in the terminal.

## Prerequisites

- Linux VM: Enterprise Linux 9/10, Debian 11-13, or Ubuntu 22.04/24.04
- sudo access
- For replication: 2+ VMs with network connectivity

## Step 1: Explore What's Available

pgEdge Enterprise Postgres includes 30+ packages across 5 categories:

| Category | Packages |
|---|---|
| **Core** | PostgreSQL 17, Spock 5.0, lolor, Snowflake |
| **AI/ML** | pgVector, MCP Server, RAG Server, Vectorizer, Anonymizer, Docloader |
| **Management** | pgAdmin, pgBouncer, pgBackRest, ACE, Radar |
| **Extensions** | PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB, pg_hint_plan, PLV8, set_user |
| **HA** | Patroni, etcd |

Browse the full interactive catalog: http://localhost:8080

## Step 2: Install (Enterprise Linux 9)

> Adapt commands for your OS. The interactive `guide.sh` auto-detects your platform.

Configure prerequisites:

\`\`\`bash
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf config-manager --set-enabled crb
\`\`\`

Add the pgEdge repository:

\`\`\`bash
sudo dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm
\`\`\`

Install the full Enterprise meta-package:

\`\`\`bash
sudo dnf install -y pgedge-enterprise-all_17
\`\`\`

Initialize and start PostgreSQL:

\`\`\`bash
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable --now postgresql-17
\`\`\`

Verify:

\`\`\`bash
sudo -u postgres psql -c "SELECT version();"
\`\`\`

## Step 3: Verify Extensions

\`\`\`bash
sudo -u postgres psql -c "SELECT name, default_version, comment
    FROM pg_available_extensions
    WHERE name IN ('spock','vector','postgis','pgaudit')
    ORDER BY name;"
\`\`\`

## Step 4: Set Up Replication (Optional)

> Requires 2+ VMs. Repeat Steps 1-3 on each VM first.

Configure both nodes for logical replication:

\`\`\`bash
sudo -u postgres psql -c "
    ALTER SYSTEM SET wal_level = 'logical';
    ALTER SYSTEM SET max_worker_processes = 16;
    ALTER SYSTEM SET max_replication_slots = 16;
    ALTER SYSTEM SET shared_preload_libraries = 'spock';"
sudo systemctl restart postgresql-17
\`\`\`

Create the database and enable Spock (on both nodes):

\`\`\`bash
sudo -u postgres createdb demo
sudo -u postgres psql -d demo -c "CREATE EXTENSION spock;"
\`\`\`

Create nodes (run each on the respective machine):

\`\`\`bash
# On node 1 (192.168.1.10):
sudo -u postgres psql -d demo -c "SELECT spock.node_create(
    node_name := 'n1',
    dsn := 'host=192.168.1.10 dbname=demo');"

# On node 2 (192.168.1.11):
sudo -u postgres psql -d demo -c "SELECT spock.node_create(
    node_name := 'n2',
    dsn := 'host=192.168.1.11 dbname=demo');"
\`\`\`

Create bidirectional subscriptions:

\`\`\`bash
# On node 1:
sudo -u postgres psql -d demo -c "SELECT spock.sub_create(
    subscription_name := 'n1_to_n2',
    provider_dsn := 'host=192.168.1.11 dbname=demo');"

# On node 2:
sudo -u postgres psql -d demo -c "SELECT spock.sub_create(
    subscription_name := 'n2_to_n1',
    provider_dsn := 'host=192.168.1.10 dbname=demo');"
\`\`\`

Verify replication:

\`\`\`bash
# Write on node 1:
sudo -u postgres psql -d demo -c "INSERT INTO test VALUES (1, 'from n1');"

# Read on node 2:
psql -h 192.168.1.11 -U postgres -d demo -c "SELECT * FROM test;"
\`\`\`

## What's Next

- **Browse all packages:** Run `../package-catalog/serve.sh` and open http://localhost:8080
- **Try Control Plane:** Run `../control-plane/guide.sh`
- **Documentation:** https://docs.pgedge.com/enterprise/

**Started with bare metal?** Add Control Plane to orchestrate what you already
have — backups, failover, and scaling, all managed through a single API.
```

**Step 4: Make scripts executable**

```bash
chmod +x bare-metal/guide.sh bare-metal/scripts/setup-replication.sh
```

**Step 5: Run quality gate**

Run: `make test-all`
Expected: All checks pass.

**Step 6: Commit**

```bash
git add bare-metal/
git commit -m "feat: add bare-metal walkthrough

Interactive guide.sh with 4-step journey (explore -> install ->
verify -> replicate), Runme-compatible WALKTHROUGH.md, and
setup-replication.sh for manual Spock configuration.
Spock SQL commands marked for v5.0 validation."
```

---

## Task 7: Prototype Updates (ant-dev-experience)

**Files:**
- Modify: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/EnterprisePostgresSection.tsx`
- Reference: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/ContainersSection.tsx` (pattern to follow)

This rewrites EnterprisePostgresSection.tsx with:
- A mode toggle: "Get Running Fast" | "Explore & Install"
- Two sets of step data (STEP_LINES, EXPLAINERS, STEP_META, NEXT_LABELS)
- Updated completion box with "Browse Packages" CTA and CP bridge message
- Terminal animation uses existing StepTerminal pattern

**Step 1: Read current files for context**

Read both `EnterprisePostgresSection.tsx` and `ContainersSection.tsx` fully to understand imports, component structure, and shared patterns.

**Step 2: Rewrite EnterprisePostgresSection.tsx**

Replace the entire file contents. Key changes:

1. **Add mode state and toggle UI** (following ContainersSection.tsx pattern):

```tsx
type Mode = "control-plane" | "bare-metal";
const [mode, setMode] = useState<Mode>("control-plane");

// Reset step when mode changes
useEffect(() => setActiveStep(0), [mode]);
```

Toggle UI:
```tsx
<div className="flex gap-1 p-1 bg-card rounded-lg w-fit mb-10">
  <button onClick={() => setMode("control-plane")}
    className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${mode === "control-plane" ? "bg-blue text-foreground" : "text-muted-foreground hover:text-foreground"}`}>
    Get Running Fast
  </button>
  <button onClick={() => setMode("bare-metal")}
    className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${mode === "bare-metal" ? "bg-blue text-foreground" : "text-muted-foreground hover:text-foreground"}`}>
    Explore &amp; Install
  </button>
</div>
```

2. **Two sets of step data:**

"Get Running Fast" (Control Plane) steps:

```tsx
const CP_STEP_META = [
  { icon: Database, label: "Deploy" },
  { icon: Server, label: "Primary" },
  { icon: CopyIcon, label: "Replicate" },
  { icon: GitBranch, label: "Distribute" },
];

const CP_STEP_LINES: Record<number, { text: string; typed?: boolean; green?: boolean }[]> = {
  0: [
    { text: '$ docker run -d --name pgedge-cp --network host pgedge/control-plane:latest', typed: true },
    { text: 'Unable to find image locally... Pulling...' },
    { text: '✓ Control Plane running on localhost:3000', green: true },
    { text: '' },
    { text: '$ curl http://localhost:3000/v1/cluster/init', typed: true },
    { text: '{"status":"ready","version":"0.6.0"}' },
  ],
  1: [
    { text: '$ curl -X POST http://localhost:3000/v1/databases \\', typed: true },
    { text: '    -d \'{"name":"demo","nodes":[{"name":"n1","port":6432}]}\'', typed: true },
    { text: '  ⠋ Creating database...' },
    { text: '✓ PostgreSQL 17 running on port 6432', green: true },
    { text: '' },
    { text: '$ psql -p 6432 -d demo -c "SELECT version();"', typed: true },
    { text: '  PostgreSQL 17.2 (pgEdge Enterprise)' },
  ],
  2: [
    { text: '$ curl -X PATCH http://localhost:3000/v1/databases/demo \\', typed: true },
    { text: '    -d \'{"nodes":[{"name":"n1"},{"name":"n2","role":"replica"}]}\'', typed: true },
    { text: '  ⠋ Adding replica...' },
    { text: '✓ n2 streaming from n1 (lag: 0ms)', green: true },
    { text: '' },
    { text: '$ curl http://localhost:3000/v1/databases/demo | jq \'.nodes\'', typed: true },
    { text: '  n1: primary  | port 6432 | healthy' },
    { text: '  n2: replica  | port 6433 | healthy | lag: 0ms' },
  ],
  3: [
    { text: '$ curl -X PATCH http://localhost:3000/v1/databases/demo \\', typed: true },
    { text: '    -d \'{"replication":"multi-master"}\'', typed: true },
    { text: '  ⠋ Enabling Spock multi-master...' },
    { text: '✓ n1 ←→ n2 ←→ n3 (active-active)', green: true },
    { text: '' },
    { text: '$ psql -p 6432 -d demo -c "INSERT INTO test VALUES (1, \'from n1\');"', typed: true },
    { text: '$ psql -p 6434 -d demo -c "SELECT * FROM test;"', typed: true },
    { text: '  1 | from n1  ← replicated', green: true },
  ],
};

const CP_EXPLAINERS = [
  {
    text: "Control Plane is a lightweight orchestrator that manages your Postgres instances. It runs as a single container and exposes a REST API for all operations.",
    link: "Control Plane docs →",
  },
  {
    text: "Control Plane pulled a pgEdge Enterprise container image, configured PostgreSQL, and started it. You have a production-ready single primary with pgBackRest backups already configured.",
    link: "Database configuration →",
  },
  {
    text: "Control Plane added a streaming replica with automatic failover via Patroni. If n1 goes down, n2 promotes automatically. pgBackRest handles backup coordination across both nodes.",
    link: "High availability docs →",
  },
  {
    text: "Control Plane enabled Spock active-active replication across all three nodes. Every node accepts writes. Conflict resolution happens automatically at the column level.",
    link: "Multi-master replication →",
  },
];

const CP_NEXT_LABELS = [
  "Next: Deploy a single primary →",
  "Next: Add read replicas & HA →",
  "Next: Go multi-master →",
  null,
];
```

"Explore & Install" (Bare Metal) steps:

```tsx
const BM_STEP_META = [
  { icon: Search, label: "Explore" },
  { icon: Download, label: "Install" },
  { icon: CheckCircle, label: "Verify" },
  { icon: GitBranch, label: "Replicate" },
];

const BM_STEP_LINES: Record<number, { text: string; typed?: boolean; green?: boolean }[]> = {
  0: [
    { text: 'pgEdge Enterprise Postgres includes 30+ packages:' },
    { text: '' },
    { text: '  Core:        PostgreSQL 17, Spock 5.0, lolor, Snowflake' },
    { text: '  AI/ML:       pgVector, MCP Server, RAG Server, Vectorizer' },
    { text: '  Management:  pgAdmin, pgBouncer, pgBackRest, ACE, Radar' },
    { text: '  Extensions:  PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB...' },
    { text: '  HA:          Patroni, etcd' },
  ],
  1: [
    { text: '$ sudo dnf install -y pgedge-enterprise-all_17', typed: true },
    { text: 'Installing: pgedge-enterprise-all_17 and 24 dependencies...' },
    { text: '✓ pgEdge Enterprise Postgres 17 installed', green: true },
    { text: '' },
    { text: '$ sudo systemctl enable --now postgresql-17', typed: true },
    { text: '✓ PostgreSQL 17 running on port 5432', green: true },
    { text: '' },
    { text: '$ psql -c "SELECT version();"', typed: true },
    { text: '  PostgreSQL 17.2 (pgEdge Enterprise)' },
  ],
  2: [
    { text: '$ psql -c "SELECT name, default_version FROM pg_available_extensions', typed: true },
    { text: '           WHERE name IN (\'spock\',\'vector\',\'postgis\',\'pgaudit\');"', typed: true },
    { text: '  name    | version' },
    { text: ' ---------+---------' },
    { text: '  pgaudit | 17.0', green: true },
    { text: '  postgis | 3.5.4', green: true },
    { text: '  spock   | 5.0.5', green: true },
    { text: '  vector  | 0.8.1', green: true },
  ],
  3: [
    { text: '$ psql -d demo -c "SELECT spock.node_create(', typed: true },
    { text: '    node_name := \'n1\', dsn := \'host=10.0.0.1 dbname=demo\');"', typed: true },
    { text: '✓ Node n1 created', green: true },
    { text: '' },
    { text: '$ psql -d demo -c "SELECT spock.sub_create(', typed: true },
    { text: '    subscription_name := \'n1_to_n2\',', typed: true },
    { text: '    provider_dsn := \'host=10.0.0.2 dbname=demo\');"', typed: true },
    { text: '✓ Subscription active — n1 ←→ n2', green: true },
    { text: '' },
    { text: '$ psql -p 5432 -d demo -c "INSERT INTO test VALUES (1, \'from n1\');"', typed: true },
    { text: '$ psql -h 10.0.0.2 -d demo -c "SELECT * FROM test;"', typed: true },
    { text: '  1 | from n1  ← replicated', green: true },
  ],
};

const BM_EXPLAINERS = [
  {
    text: "pgEdge Enterprise Postgres is a fully-supported PostgreSQL distribution with 30+ integrated packages for replication, AI/ML, monitoring, and high availability — all installable from a single package repository.",
    link: "Browse package catalog →",
  },
  {
    text: "One command installs everything: PostgreSQL, Spock replication, pgVector, PostGIS, pgAdmin, pgBouncer, pgBackRest, and all extensions. Everything came from the pgEdge package repo via your native package manager.",
    link: "Installation guide →",
  },
  {
    text: "These extensions are installed as shared libraries but not yet enabled in your database. Enable them with CREATE EXTENSION when needed. All versions are tested and certified to work together.",
    link: "Extension compatibility →",
  },
  {
    text: "You've manually configured Spock active-active replication. Each node accepts writes and replicates to the other. Conflict resolution happens automatically at the column level.",
    link: "Spock replication docs →",
  },
];

const BM_NEXT_LABELS = [
  "Next: Install Enterprise Postgres →",
  "Next: Verify extensions →",
  "Next: Set up replication →",
  null,
];
```

3. **Mode-aware data selection:**

```tsx
const STEP_LINES = mode === "control-plane" ? CP_STEP_LINES : BM_STEP_LINES;
const EXPLAINERS = mode === "control-plane" ? CP_EXPLAINERS : BM_EXPLAINERS;
const STEP_META = mode === "control-plane" ? CP_STEP_META : BM_STEP_META;
const NEXT_LABELS = mode === "control-plane" ? CP_NEXT_LABELS : BM_NEXT_LABELS;
```

4. **Mode-aware descriptions** below the toggle:

```tsx
{mode === "control-plane" ? (
  <p className="text-muted-foreground text-sm max-w-xl mb-10">
    pgEdge Control Plane deploys and manages your Postgres — from a single primary
    through HA to full multi-master. One API, zero manual configuration.
  </p>
) : (
  <p className="text-muted-foreground text-sm max-w-xl mb-10">
    Browse the full pgEdge Enterprise package catalog. Install components on your
    own Linux servers exactly how you want them.
  </p>
)}
```

5. **Updated completion box:**

```tsx
<div className="space-y-6">
  <div className="bg-success/10 border border-success/30 rounded-xl p-6 text-center">
    <p className="text-lg font-bold text-success">
      {mode === "control-plane"
        ? "You've gone from single primary to multi-master — all through one API. Ready to try it?"
        : "You've installed pgEdge Enterprise and configured multi-master replication. Ready to try it?"}
    </p>
    <div className="flex items-center justify-center gap-4 mt-4 flex-wrap">
      <button onClick={() => setShowSandboxChoice(true)}
        className="px-6 py-3 bg-blue text-foreground font-semibold rounded-lg hover:brightness-110 transition-all">
        Try in Browser →
      </button>
      <button onClick={() => toast.info("[Prototype] curl-pipe install for local use")}
        className="px-6 py-3 border border-teal text-teal font-semibold rounded-lg hover:bg-teal/10 transition-all">
        Run Locally →
      </button>
      <button onClick={() => toast.info("[Prototype] Opens package catalog at localhost:8080")}
        className="px-6 py-3 border border-teal text-teal font-semibold rounded-lg hover:bg-teal/10 transition-all">
        Browse Packages →
      </button>
    </div>
  </div>

  {/* Bridge message for bare-metal path */}
  {mode === "bare-metal" && (
    <div className="text-center">
      <p className="text-sm text-muted-foreground">
        Started with bare metal?{" "}
        <button onClick={() => setMode("control-plane")}
          className="text-teal hover:underline font-medium">
          Add Control Plane to orchestrate what you already have →
        </button>
      </p>
    </div>
  )}
</div>
```

**Step 3: Verify the prototype builds**

Run (from ant-dev-experience directory):
```bash
cd "/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience"
npm run build
```
Expected: Build succeeds with no TypeScript errors.

**Step 4: Verify the prototype renders**

Run: `npm run dev`
Open the Enterprise Postgres section in the browser. Verify:
- [ ] Mode toggle renders with both labels
- [ ] Switching modes resets to step 0 and updates description
- [ ] All 4 steps animate correctly for each mode
- [ ] Explainer cards update per step per mode
- [ ] Completion box shows "Browse Packages" CTA
- [ ] Bare-metal completion shows CP bridge message
- [ ] Clicking bridge message switches to control-plane mode

**Step 5: Commit**

```bash
git add src/components/EnterprisePostgresSection.tsx
git commit -m "feat: rewrite Enterprise section with two-path toggle

Mode toggle for 'Get Running Fast' (Control Plane) and 'Explore &
Install' (bare metal) paths. Each path has its own terminal
animation, explainer cards, and CTAs. Bridge message connects
bare-metal users to Control Plane."
```

---

## Task 8: README & Final Integration

**Files:**
- Modify: `README.md` (in try-pgedge-enterprise root)
- Test: visual review

**Step 1: Write README.md**

```markdown
# try-pgedge-enterprise

The fastest way to experience pgEdge Enterprise Postgres — from package
discovery through single-node installs to multi-master replication.

## Two Paths

### Get Running Fast — Control Plane

pgEdge Control Plane deploys and manages your Postgres. One API takes you from
a single primary through HA to full multi-master.

**Prerequisites:** Docker (with host networking), curl

```bash
# Interactive walkthrough
./control-plane/guide.sh

# Or follow the step-by-step markdown
# Open control-plane/WALKTHROUGH.md in VS Code with Runme
```

### Explore & Install — Bare Metal

Browse the full pgEdge Enterprise package catalog. Install on your own Linux
servers using your native package manager.

**Prerequisites:** Linux VM (EL 9/10, Debian 11-13, Ubuntu 22.04/24.04), sudo

```bash
# Interactive walkthrough
./bare-metal/guide.sh

# Or follow the step-by-step markdown
# Open bare-metal/WALKTHROUGH.md in VS Code with Runme
```

## Package Catalog

Browse all 30+ packages interactively. Pick your platform, copy the install
commands.

```bash
# Serve locally
./package-catalog/serve.sh
# Open http://localhost:8080
```

## What's Included

| Category | Packages |
|---|---|
| **Core** | PostgreSQL 17, Spock 5.0, lolor, Snowflake |
| **AI & ML** | pgVector, MCP Server, RAG Server, Vectorizer, Anonymizer, Docloader |
| **Management** | pgAdmin 4, pgBouncer, pgBackRest, ACE, Radar |
| **Extensions** | PostGIS, pgAudit, pg_cron, Orafce, TimescaleDB, pg_hint_plan, PLV8, set_user |
| **HA** | Patroni, etcd |

## Links

- [pgEdge Documentation](https://docs.pgedge.com/enterprise/)
- [pgEdge GitHub](https://github.com/pgEdge)
- [pgedge.com](https://pgedge.com)
```

**Step 2: Verify README renders**

Check the markdown renders correctly on GitHub or in a local preview.

**Step 3: Commit**

```bash
git add README.md
git commit -m "feat: add README with both quickstart paths

Landing page describing the Control Plane and bare-metal paths,
package catalog, and included packages."
```

---

## Open Questions (Carry Forward)

These items from the design doc need resolution during or after implementation:

1. **Control Plane API shape** — The exact endpoints and JSON payloads for `/v1/databases`, PATCH for adding nodes, and `"replication":"multi-master"` need validation against the CP v0.6 API. Marked with `# NOTE` comments in scripts.

2. **Spock 5.0 SQL API** — The `spock.node_create` and `spock.sub_create` function signatures, plus required `pg_hba.conf` and `postgresql.conf` settings, need verification against Spock 5.0 docs. Marked with `# NOTE` comments in scripts.

3. **Codespace support** — The CP quickstart needs Docker with host networking. Docker-in-Docker in Codespaces may not support host networking. Needs testing.

4. **Package catalog completeness** — `catalog.json` should be validated against actual repo contents. Some AI toolkit packages may not be in the dnf/apt repo yet.

---

## Dependency Graph

```
Task 1 (scaffolding + Claude config + Makefile + .editorconfig)
  ├── Task 2 (shell lib) ─────────┬── Task 5 (CP quickstart)
  ├── Task 3 (catalog.json) ──┬───┤
  │                            │   └── Task 6 (bare-metal)
  │                            │
  │                            └── Task 4 (catalog page)
  │
  └── Task 8 (README) ← after Tasks 4-6

Task 7 (prototype) — independent, can run in parallel with Tasks 4-6
```

Tasks 4, 5, 6, and 7 can be parallelized after their dependencies (Tasks 1-3) are complete.

All tasks run `make test-all` as their final quality gate before committing.
