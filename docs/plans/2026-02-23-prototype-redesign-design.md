# Enterprise Postgres Prototype Section — Redesign

**Date:** 2026-02-23
**Status:** Approved
**Project:** ant-dev-experience prototype (EnterprisePostgresSection.tsx)

---

## Problem

The current Enterprise Postgres section in the ant-dev-experience prototype
forces users through a 4-step read-only terminal animation before exposing any
actionable "try it" options. This is sub-optimal compared to the other sections:

- **AI Toolkit** uses a 3-step progressive flow (See it → Run it → Go deeper)
  where installation cards are immediately visible on scroll.
- **Containers** separates the walkthrough from "Try it yourself" cards that are
  always visible at the bottom.
- **Enterprise Postgres** gates everything behind completing the animation.

Users want to try things, not watch a demo they can't interact with.

## Design

Rewrite EnterprisePostgresSection.tsx as a 3-step progressive layout mirroring
the AI Toolkit pattern. All steps are visible on scroll — no gating.

### Step 1: "Your Postgres journey"

A static split-panel comparison showing both paths (Control Plane and Bare Metal)
side by side across 3 progression stages. No animation, no toggle, no
click-through.

**Layout:** Column headers at top, then 3 rows connected by arrows.

```
              Control Plane              Bare Metal
              "One API, zero manual      "Your servers, your package
               configuration"             manager, full control"
              ─────────────────          ─────────────────────────

Primary       POST /v1/databases         dnf install pgedge-enterprise-all_17
              → PG 17 on port 6432       → PG 17 on port 5432
                      ↓                          ↓
Replicate     PATCH + add replicas       spock.node_create + sub_create
              → n2 streaming (lag: 0ms)  → Subscription active n1 ↔ n2
                      ↓                          ↓
Distribute    PATCH multi-master         INSERT on n1 / SELECT on n2
              → n1 ↔ n2 ↔ n3            → replicated
```

**Control Plane column** shows production-style API calls (not docker commands).
This communicates what CP does without implying a deployment model.

**Bare Metal column** shows native package manager + Spock SQL commands.

Each row has:
- A stage label on the left (Primary / Replicate / Distribute)
- A code block per column with the key command(s)
- A green result line showing the outcome
- An arrow connector to the next row

The visual takeaway: CP is 1 API call per stage, BM is hands-on SQL — same
destination, different paths. Scannable in 3 seconds.

### Step 2: "Try it yourself"

Three cards in a row. Card 1 gets the teal highlight treatment (recommended
path, matching Claude Code card in AI Toolkit).

**Card 1: "Run the Guide" (highlighted)**
- Icon: Terminal
- Copy-to-clipboard curl-pipe command to clone and run
- Sub-toggle or two buttons: "Control Plane guide" / "Bare Metal guide"
- Prerequisites: "Docker (CP) or Linux VM (BM)"
- Time: "~5 minutes"

**Card 2: "Open in Codespaces"**
- Icon: GitHub
- Direct link to codespaces.new/AntTheLimey/try-pgedge-enterprise
- "VS Code with Runme — click to run each step"
- "Free, GitHub account required"

**Card 3: "Browse Package Catalog"**
- Icon: Search/Package
- Link to hosted catalog page
- "Explore all 30+ packages, pick your platform, copy install commands"
- "No install required"

### Step 3: "Go deeper"

Four resource cards in a grid:

1. **Documentation** — docs.pgedge.com/enterprise/
2. **GitHub** — github.com/pgEdge
3. **Package Catalog Docs** — full package list with version compatibility
4. **Spock Replication** — multi-master setup, conflict resolution, tuning

### What gets removed

- Mode toggle (replaced by side-by-side comparison)
- Terminal typing animation (replaced by static code blocks)
- 4-step progress bar with circular icons (replaced by row labels)
- Completion gate (no more "finish walkthrough to unlock try-it")
- SandboxPreview component usage and sandbox choice modal
- Bridge message (both paths visible simultaneously)

### What stays

- The progression narrative (Primary → Replicate → Distribute)
- Both paths represented (CP and BM)
- "Try it yourself" actions (reorganized as immediately-visible cards)
- Step indicator dots (matching AI Toolkit's 1-of-3, 2-of-3, 3-of-3 pattern)

## Technical notes

- Component becomes mostly static — minimal useState (just the guide sub-toggle
  in Card 1)
- StepTerminal component is no longer needed and can be removed
- SandboxPreview import can be removed
- Significant line count reduction (~400 lines → ~250 lines estimated)
- No new dependencies required
