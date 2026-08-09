# blueprint

Composable Claude skills that enforce structural discipline across the full engineering
lifecycle — from ideation through implementation to ongoing maintenance.

**New here?** Open [`how-it-works.html`](how-it-works.html) — a plain-language explainer
of the checkpoint gate, the two chains, and all 14 skills. Or run `/how`.

## Skill Map

```
                        ┌──────────────────────────────────────────────────────┐
   BUILD WORKFLOW       │                                                      │
                        │  ideate → architect → design → scaffold              │
                        │  "what      "what are    "how do    "stamp            │
                        │  approach?"  the pieces?" they wire?" it out"         │
                        └──────────────────────────────────────────────────────┘

                        ┌──────────────────────────────────────────────────────┐
   REVIEW WORKFLOW      │                                                      │
                        │  code-review ──┐                                     │
                        │  (file-level)  ├→ refactoring-plan → refactor        │
                        │  review-arch ──┘   (prioritise)      (execute)       │
                        │  (system-level)                                      │
                        └──────────────────────────────────────────────────────┘

                        ┌──────────────────────────────────────────────────────┐
   PLAN TRACKING        │                                                      │
                        │  plan-tracker: creates PLAN-*.md at workflow start,   │
                        │  updates status during execution (PENDING → DONE),   │
                        │  verifies completion + diff + re-review at end       │
                        └──────────────────────────────────────────────────────┘
```

## Skills

| Skill | Trigger | Output | Feeds Into |
|---|---|---|---|
| **ideate** | "what are my options", "poke holes" | Decision summary with chosen approach | architect |
| **spec-interview** | hands over a markdown doc: "what's missing", "tighten this spec" | `<stem>.refined.md` + Handoff | architect |
| **architect** | "what should the components be" | Domain model, module decomposition, abstraction decisions | design |
| **design** | "build this", multi-file work | Dependency graph, data flow, interfaces, file structure | scaffold, refactor |
| **scaffold** | "new module", "add another X like Y" | Boilerplate files following conventions | — |
| **refactor** | "clean this up", "make it proper" | Restructured code with tests passing | — |
| **code-review** *(existing)* | "review this code" | Severity-ranked `CR-*` findings with BEFORE/AFTER | refactoring-plan |
| **review-architecture** | "review the architecture" | Scored diagnostic across 7 dimensions, `AR-*` findings | refactoring-plan |
| **review-depth** | "too complex", "hard to navigate", "deep modules" | Depth scorecard, `DM-*` findings | refactoring-plan |
| **compat-audit** | "do these skills conflict", "can I load these together" | Verdict matrix, `CA-*` findings, registry defects | refactoring-plan |
| **refactoring-plan** | "what should I fix first" | Prioritised, dependency-ordered roadmap | plan-tracker, refactor |
| **plan-tracker** | multi-step work starts, "create a plan", "verify the plan" | Tracked plan file (`PLAN-*.md`) with status, verification report | refactor, scaffold |
| **navigator** | "where is X", "what calls Y", "explore the codebase" | Answers about existing code — Q&A, no artifact | — |
| **orch** | "run this in parallel", "use the conductor" | Dispatch decision; parallel worktree build, test-gated | — |

## Installation

### Claude Code
Copy each skill directory into `~/.claude/skills/` or your project's `.claude/skills/`.
Place `shared-principles.md` as a sibling to the skill directories.

```
~/.claude/skills/
├── shared-principles.md
├── ideate/
│   └── SKILL.md
├── architect/
│   └── SKILL.md
├── design/
│   └── SKILL.md
├── scaffold/
│   └── SKILL.md
├── refactor/
│   └── SKILL.md
├── spec-interview/
│   └── SKILL.md
├── review-architecture/
│   └── SKILL.md
├── review-depth/
│   ├── SKILL.md
│   └── references/
├── compat-audit/
│   ├── SKILL.md
│   └── references/
├── refactoring-plan/
│   └── SKILL.md
├── plan-tracker/
│   └── SKILL.md
├── navigator/
│   └── SKILL.md
├── orch/
│   └── SKILL.md
└── code-review/          ← existing skill, unchanged
    └── SKILL.md
```

### Claude.ai
Reference the skill principles conversationally or upload relevant SKILL.md files
as context when working on specific tasks.

## Workflows

Six workflows covering every situation: build new, refactor, redesign, extend, explore, and rewrite. Each with concrete Claude Code commands, decision criteria, and transition rules.

**See [`WORKFLOWS.md`](WORKFLOWS.md) for the complete reference.**

Quick decision:

| Situation | Workflow | Start with |
|---|---|---|
| Building something new | W1 Build | `claude "ideate..."` |
| Code works, structure is messy | W2 Refactor | `claude "review the architecture..."` |
| Boundaries are fundamentally wrong | W3 Redesign | `claude "review the architecture..."` |
| Adding a new capability | W4 Extend | `claude "architect where [X] fits..."` |
| Vague problem, need to think | W5 Explore | `claude "ideate..."` |
| Beyond saving (rare) | W6 Rewrite | Review old → W1 on new |

## Example Prompts

### ideate

**Open exploration:**
```
I need to build a system that monitors credit spreads across 500 bonds and
generates carry signals daily. What are my options?
```

**Stress-test:**
```
Here's my plan: I'll compute carry as the rolling z-spread minus the
sector median, rank by decile, and rebalance weekly. Poke holes in this.
```

### architect
```
I've decided to build the carry signal system. Help me figure out what the
components should be — what are the right abstractions?
```

### design
```
Architecture is approved. Design the carry signal system — dependency graph,
interfaces, file structure.
```

### scaffold

**New project:**
```
Scaffold a new project called "carry-monitor" for the carry signal system.
```

**New module in existing project:**
```
Add a new momentum signal like the existing carry signal.
```

### refactor
```
This pipeline.py works but it's a single 400-line function. Clean it up.
```

### review-architecture
```
Review the architecture of this project. Is the structure sound?
```

### refactoring-plan
```
I just got the architecture review and code review results. What should I
fix first?
```

### code-review
```
Review this code.
```

## Tips

- **Skills chain naturally.** Output of one skill is input to the next.
  Say "proceed" or name the next step — no manual context passing needed.
- **Every skill stops for approval.** Design, refactoring plans, and scaffold
  all present their output for review before writing code.
- **Quantitative problems get extra scrutiny.** ideate and design add
  mathematical specification, degeneracy analysis, and overfitting checks.
- **Parallelisation is always considered.** Every skill flags embarrassingly
  parallel components and sequential bottlenecks.
