# Enterprise Postgres Prototype Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite EnterprisePostgresSection.tsx from a gated terminal walkthrough to a 3-step progressive layout (See it → Try it → Go deeper) mirroring the AI Toolkit section pattern.

**Architecture:** Replace the modal/animation-heavy component with a mostly-static 3-section layout. Step 1 uses a split-panel comparison table showing CP vs BM across 3 progression stages. Step 2 has 3 actionable cards. Step 3 has 4 resource links. Each step gets its own scroll animation ref.

**Tech Stack:** React, TypeScript, Tailwind CSS, lucide-react icons, sonner toast

**Reference files:**
- Current file: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/EnterprisePostgresSection.tsx`
- Pattern to follow: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/AIToolkitSection.tsx`
- Design doc: `/Users/apegg/PROJECTS/try-pgedge-enterprise/docs/plans/2026-02-23-prototype-redesign-design.md`

---

## Task 1: Rewrite EnterprisePostgresSection.tsx

**Files:**
- Modify: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/EnterprisePostgresSection.tsx`

### Step 1: Replace the entire file

Replace the contents of `EnterprisePostgresSection.tsx` with the following:

```tsx
import { useState } from "react";
import { Terminal, Github, BookOpen, GitBranch, Copy, Check, Search, ArrowDown, ExternalLink } from "lucide-react";
import { useScrollAnimation } from "@/hooks/useScrollAnimation";
import { toast } from "sonner";

/* ── Progression data ── */

const STAGES = [
  {
    label: "Primary",
    cp: {
      commands: [
        'curl -X POST /v1/databases \\',
        '  -d \'{"name":"demo","nodes":[{"name":"n1"}]}\'',
      ],
      result: "✓ PostgreSQL 17 running on port 6432",
    },
    bm: {
      commands: [
        'sudo dnf install -y pgedge-enterprise-all_17',
        'sudo systemctl enable --now postgresql-17',
      ],
      result: "✓ PostgreSQL 17 running on port 5432",
    },
  },
  {
    label: "Replicate",
    cp: {
      commands: [
        'curl -X PATCH /v1/databases/demo \\',
        '  -d \'{"nodes":[{"name":"n1"},{"name":"n2","role":"replica"}]}\'',
      ],
      result: "✓ n2 streaming from n1 (lag: 0ms)",
    },
    bm: {
      commands: [
        'SELECT spock.node_create(',
        '  node_name := \'n1\', dsn := \'host=10.0.0.1 dbname=demo\');',
        'SELECT spock.sub_create(',
        '  sub_name := \'n1_to_n2\', provider_dsn := \'host=10.0.0.2 ...\');',
      ],
      result: "✓ Subscription active — n1 ↔ n2",
    },
  },
  {
    label: "Distribute",
    cp: {
      commands: [
        'curl -X PATCH /v1/databases/demo \\',
        '  -d \'{"replication":"multi-master"}\'',
      ],
      result: "✓ n1 ↔ n2 ↔ n3 (active-active)",
    },
    bm: {
      commands: [
        'psql -h n1 -c "INSERT INTO test VALUES (1, \'from n1\');"',
        'psql -h n2 -c "SELECT * FROM test;"',
      ],
      result: "✓ 1 | from n1  ← replicated",
    },
  },
];

/* ── Main Section ── */
export default function EnterprisePostgresSection() {
  const { ref: s1Ref, isVisible: s1Vis } = useScrollAnimation();
  const { ref: s2Ref, isVisible: s2Vis } = useScrollAnimation();
  const { ref: s3Ref, isVisible: s3Vis } = useScrollAnimation();
  const [guideType, setGuideType] = useState<"cp" | "bm">("cp");
  const [copied, setCopied] = useState(false);

  const copyCmd = () => {
    const cmd = guideType === "cp"
      ? "git clone https://github.com/AntTheLimey/try-pgedge-enterprise.git && cd try-pgedge-enterprise && ./control-plane/guide.sh"
      : "git clone https://github.com/AntTheLimey/try-pgedge-enterprise.git && cd try-pgedge-enterprise && ./bare-metal/guide.sh";
    navigator.clipboard.writeText(cmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div id="distributed-content" className="bg-background">
      {/* Step 1: See it in action */}
      <div ref={s1Ref} className={`max-w-7xl mx-auto px-6 py-16 ${s1Vis ? "animate-fade-in-up" : "opacity-0"}`}>
        <div className="flex items-center gap-3 mb-2">
          <span className="text-xs font-bold text-teal uppercase tracking-wider">Step 1 of 3</span>
          <div className="flex gap-1">
            <span className="w-2 h-2 rounded-full bg-teal" />
            <span className="w-2 h-2 rounded-full bg-border" />
            <span className="w-2 h-2 rounded-full bg-border" />
          </div>
        </div>
        <h2 className="text-3xl font-bold text-foreground mb-2">Your Postgres journey</h2>
        <p className="text-muted-foreground mb-8">
          From a single primary to multi-master replication. Two paths, same destination.
        </p>

        {/* Column headers */}
        <div className="grid grid-cols-[120px_1fr_1fr] gap-4 mb-6">
          <div />
          <div>
            <h3 className="font-bold text-foreground">Control Plane</h3>
            <p className="text-xs text-muted-foreground">One API, zero manual configuration</p>
          </div>
          <div>
            <h3 className="font-bold text-foreground">Bare Metal</h3>
            <p className="text-xs text-muted-foreground">Your servers, your package manager, full control</p>
          </div>
        </div>

        {/* Progression rows */}
        {STAGES.map((stage, i) => (
          <div key={stage.label}>
            <div className="grid grid-cols-[120px_1fr_1fr] gap-4">
              {/* Stage label */}
              <div className="flex items-center">
                <span className="text-sm font-bold text-teal">{stage.label}</span>
              </div>
              {/* CP column */}
              <div className="bg-[#0D2137] rounded-lg p-4 font-mono text-xs">
                {stage.cp.commands.map((cmd, j) => (
                  <div key={j} className="text-primary-foreground/70">{cmd}</div>
                ))}
                <div className="text-success mt-1">{stage.cp.result}</div>
              </div>
              {/* BM column */}
              <div className="bg-[#0D2137] rounded-lg p-4 font-mono text-xs">
                {stage.bm.commands.map((cmd, j) => (
                  <div key={j} className="text-primary-foreground/70">{cmd}</div>
                ))}
                <div className="text-success mt-1">{stage.bm.result}</div>
              </div>
            </div>
            {/* Arrow connector */}
            {i < STAGES.length - 1 && (
              <div className="grid grid-cols-[120px_1fr_1fr] gap-4">
                <div />
                <div className="flex justify-center py-2">
                  <ArrowDown className="w-4 h-4 text-teal/40" />
                </div>
                <div className="flex justify-center py-2">
                  <ArrowDown className="w-4 h-4 text-teal/40" />
                </div>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Step 2: Try it yourself */}
      <div ref={s2Ref} className={`max-w-7xl mx-auto px-6 py-16 ${s2Vis ? "animate-fade-in-up" : "opacity-0"}`}>
        <div className="flex items-center gap-3 mb-2">
          <span className="text-xs font-bold text-teal uppercase tracking-wider">Step 2 of 3</span>
          <div className="flex gap-1">
            <span className="w-2 h-2 rounded-full bg-teal" />
            <span className="w-2 h-2 rounded-full bg-teal" />
            <span className="w-2 h-2 rounded-full bg-border" />
          </div>
        </div>
        <h2 className="text-3xl font-bold text-foreground mb-2">Try it yourself</h2>
        <p className="text-muted-foreground mb-8">Interactive walkthroughs that guide you through every step.</p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Card 1: Run the Guide (highlighted) */}
          <div className="bg-card border-2 border-teal rounded-xl p-6 text-center space-y-3 shadow-[0_0_20px_hsl(190_100%_42%/0.15)]">
            <Terminal className="w-12 h-12 text-teal mx-auto" />
            <h4 className="font-bold text-foreground">Run the Guide</h4>
            <p className="text-sm text-muted-foreground">Interactive terminal walkthrough — clone, run, follow along.</p>
            <p className="text-xs text-teal">~5 minutes</p>
            <div className="flex justify-center gap-1 bg-code-bg rounded-lg p-1">
              <button onClick={() => setGuideType("cp")} className={`px-3 py-1 rounded text-xs font-medium transition-colors ${guideType === "cp" ? "bg-teal/20 text-teal" : "text-muted-foreground hover:text-foreground"}`}>
                Control Plane
              </button>
              <button onClick={() => setGuideType("bm")} className={`px-3 py-1 rounded text-xs font-medium transition-colors ${guideType === "bm" ? "bg-teal/20 text-teal" : "text-muted-foreground hover:text-foreground"}`}>
                Bare Metal
              </button>
            </div>
            <button onClick={copyCmd} className="w-full py-2 rounded-lg bg-teal/10 text-teal font-semibold text-sm hover:bg-teal/20 transition-all flex items-center justify-center gap-2">
              {copied ? <><Check className="w-4 h-4 text-success" /> Copied!</> : <><Copy className="w-4 h-4" /> Copy command</>}
            </button>
            <div className="bg-code-bg rounded-lg p-3 text-left">
              <code className="text-[11px] text-primary-foreground/70 font-mono break-all">
                {guideType === "cp"
                  ? "git clone ...try-pgedge-enterprise && cd try-pgedge-enterprise && ./control-plane/guide.sh"
                  : "git clone ...try-pgedge-enterprise && cd try-pgedge-enterprise && ./bare-metal/guide.sh"}
              </code>
            </div>
            <p className="text-[10px] text-muted-foreground">
              {guideType === "cp" ? "Requires Docker" : "Requires Linux VM (EL 9/10, Debian, Ubuntu)"}
            </p>
          </div>

          {/* Card 2: Open in Codespaces */}
          <div className="bg-card border border-border rounded-xl p-6 text-center space-y-3">
            <Github className="w-12 h-12 text-muted-foreground mx-auto" />
            <h4 className="font-bold text-foreground">Open in Codespaces</h4>
            <p className="text-sm text-muted-foreground">VS Code with Runme — click to run each step. Nothing to install.</p>
            <p className="text-xs text-teal">Ready in ~45 seconds</p>
            <a href="https://codespaces.new/AntTheLimey/try-pgedge-enterprise?quickstart=1" target="_blank" rel="noopener noreferrer"
              className="block w-full py-2 rounded-lg bg-muted-foreground/10 text-foreground font-semibold text-sm hover:bg-muted-foreground/20 transition-all text-center">
              Launch Codespace →
            </a>
            <p className="text-[11px] text-muted-foreground">Free • GitHub account required</p>
          </div>

          {/* Card 3: Browse Package Catalog */}
          <div className="bg-card border border-border rounded-xl p-6 text-center space-y-3">
            <Search className="w-12 h-12 text-muted-foreground mx-auto" />
            <h4 className="font-bold text-foreground">Browse Package Catalog</h4>
            <p className="text-sm text-muted-foreground">Explore all 30+ packages. Pick your platform, copy install commands.</p>
            <p className="text-xs text-teal">No install required</p>
            <button onClick={() => toast.info("[Prototype] Would open package catalog")}
              className="block w-full py-2 rounded-lg bg-muted-foreground/10 text-foreground font-semibold text-sm hover:bg-muted-foreground/20 transition-all text-center">
              Open Catalog →
            </button>
            <p className="text-[11px] text-muted-foreground">Interactive web page • Works in any browser</p>
          </div>
        </div>
      </div>

      {/* Step 3: Go deeper */}
      <div ref={s3Ref} className={`max-w-7xl mx-auto px-6 py-16 ${s3Vis ? "animate-fade-in-up" : "opacity-0"}`}>
        <div className="flex items-center gap-3 mb-2">
          <span className="text-xs font-bold text-teal uppercase tracking-wider">Step 3 of 3</span>
          <div className="flex gap-1">
            <span className="w-2 h-2 rounded-full bg-teal" />
            <span className="w-2 h-2 rounded-full bg-teal" />
            <span className="w-2 h-2 rounded-full bg-teal" />
          </div>
        </div>
        <h2 className="text-3xl font-bold text-foreground mb-8">Go deeper</h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            { icon: BookOpen, title: "Documentation", desc: "Installation, configuration, and API reference", href: "https://docs.pgedge.com/enterprise/" },
            { icon: Github, title: "GitHub", desc: "Source code, issues, and contributions", href: "https://github.com/pgEdge" },
            { icon: Search, title: "Package Catalog", desc: "Full list of 30+ packages with version compatibility", href: "https://docs.pgedge.com/enterprise/" },
            { icon: GitBranch, title: "Spock Replication", desc: "Multi-master setup, conflict resolution, and tuning", href: "https://docs.pgedge.com/enterprise/" },
          ].map((r) => (
            <a key={r.title} href={r.href} target="_blank" rel="noopener"
              className="bg-card border border-border rounded-xl p-6 hover:shadow-lg hover:-translate-y-1 transition-all group">
              <r.icon className="w-8 h-8 text-teal mb-3 group-hover:scale-110 transition-transform" />
              <h4 className="font-bold text-foreground mb-1">{r.title}</h4>
              <p className="text-sm text-muted-foreground">{r.desc}</p>
            </a>
          ))}
        </div>
      </div>
    </div>
  );
}
```

### Step 2: Verify TypeScript compiles

Run (from ant-dev-experience directory):
```bash
cd "/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience"
npx tsc --noEmit
```
Expected: No errors. If there are unused import warnings, remove the unused imports.

### Step 3: Visual verification checklist

Run: `npm run dev`

Verify in browser:
- [ ] Step 1 shows "Your Postgres journey" with 3 progression rows
- [ ] Each row has stage label (Primary/Replicate/Distribute), CP column, BM column
- [ ] Code blocks have dark background with syntax highlighting
- [ ] Green result lines show outcomes
- [ ] Arrow connectors between rows
- [ ] Step 2 shows 3 cards: Run the Guide (teal highlighted), Codespaces, Package Catalog
- [ ] Run the Guide card has CP/BM toggle that switches the displayed command
- [ ] Copy button copies the correct command for selected guide type
- [ ] Codespaces card links to try-pgedge-enterprise repo
- [ ] Step 3 shows 4 resource link cards
- [ ] All 3 steps have "Step N of 3" indicators with dot progression
- [ ] Each step fades in on scroll
- [ ] No terminal animation, no mode toggle, no sandbox modal

### Step 4: Commit

```bash
cd "/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience"
git add src/components/EnterprisePostgresSection.tsx
git commit -m "feat: redesign Enterprise section as 3-step progressive layout

Replace gated terminal walkthrough with:
- Step 1: Static split-panel comparison (CP vs BM across 3 stages)
- Step 2: Try-it-yourself cards (Run Guide, Codespaces, Catalog)
- Step 3: Go deeper resource links

Mirrors the AI Toolkit section pattern. All content immediately
visible on scroll — no click-through required."
```

---

## Responsive design note

The 3-column grid (`grid-cols-[120px_1fr_1fr]`) in Step 1 may need a mobile
breakpoint. On small screens, consider stacking the columns. This can be
iterated after the initial implementation lands.

## What was removed

- `StepTerminal` component (typing animation)
- `SandboxPreview` import and usage
- Mode type and toggle (CP/BM)
- All CP_*/BM_* step data constants
- Progress bar with circular icons
- Completion gate and success message
- Bridge message
- Sandbox choice modal
- `useEffect` for step reset on mode change
