# blueprint

Composable Claude skills that enforce structural discipline across the full engineering
lifecycle — from ideation through implementation to ongoing maintenance.

## Skill Map

```
                        ┌─────────────────────────────────────────────┐
   BUILD WORKFLOW       │                                             │
                        │  ideate → architect → design → scaffold     │
                        │  "what      "what are    "how do    "stamp   │
                        │  approach?"  the pieces?" they wire?" it out" │
                        └─────────────────────────────────────────────┘

                        ┌─────────────────────────────────────────────┐
   REVIEW WORKFLOW      │                                             │
                        │  code-review ──┐                            │
                        │  (file-level)  ├→ refactoring-plan → refactor│
                        │  review-arch ──┘   (prioritise)    (execute)│
                        │  (system-level)                             │
                        └─────────────────────────────────────────────┘
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
| **refactoring-plan** | "what should I fix first" | Prioritised, dependency-ordered roadmap | refactor |

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
└── code-review/          ← existing skill, unchanged
    └── SKILL.md
```

### Claude.ai
Reference the skill principles conversationally or upload relevant SKILL.md files
as context when working on specific tasks.

## Common Workflows

### New Project
1. **ideate** — explore approaches, stress-test thinking
2. **architect** — decompose domain into modules and abstractions
3. **design** — wire components together, define interfaces
4. **scaffold** — generate project boilerplate

### Extend Existing System
1. **architect** — where does the new capability fit?
2. **design** — how does it integrate with existing structure?
3. **scaffold** — stamp out the new module following conventions

### Structural Health Check
1. **review-architecture** — diagnose system-level issues (scored)
2. **code-review** — diagnose file-level issues (scored)
3. **refactoring-plan** — synthesise into prioritised roadmap
4. **refactor** — execute the plan, phase by phase
5. **review-architecture** — re-score to measure improvement

### "This Works But It's A Mess"
1. **refactoring-plan** — quickly triage what to fix first
2. **refactor** — execute incrementally
3. *(optional)* **architect** — if the plan reveals the decomposition itself is wrong
