# blueprint

Composable Claude skills that enforce structural discipline across the full engineering
lifecycle — from ideation through implementation to ongoing maintenance.

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
| **architect** | "what should the components be" | Domain model, module decomposition, abstraction decisions | design |
| **design** | "build this", multi-file work | Dependency graph, data flow, interfaces, file structure | scaffold, refactor |
| **scaffold** | "new module", "add another X like Y" | Boilerplate files following conventions | — |
| **refactor** | "clean this up", "make it proper" | Restructured code with tests passing | — |
| **code-review** *(existing)* | "review this code" | Severity-ranked findings with BEFORE/AFTER | refactoring-plan |
| **review-architecture** | "review the architecture" | Scored diagnostic across 7 dimensions | refactoring-plan |
| **refactoring-plan** | "what should I fix first" | Prioritised, dependency-ordered roadmap | plan-tracker, refactor |
| **plan-tracker** | multi-step work starts, "create a plan", "verify the plan" | Tracked plan file (`PLAN-*.md`) with status, verification report | refactor, scaffold |

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
├── review-architecture/
│   └── SKILL.md
├── refactoring-plan/
│   └── SKILL.md
├── plan-tracker/
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
