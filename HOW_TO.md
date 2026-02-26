# How To Use Blueprint Skills

Practical usage guide with examples for every skill and workflow.

## Triggering Skills

Skills activate automatically when you use their trigger phrases. You can also
invoke them directly as slash commands.

### Direct invocation
```
/ideate
/architect
/design
/scaffold
/refactor
/review-architecture
/refactoring-plan
/code-review
```

### Natural language triggers

| Instead of this | Say this |
|-----------------|----------|
| `/ideate` | "what are my options for...", "poke holes in this plan", "stress-test this" |
| `/architect` | "what should the components be", "how do I decompose this" |
| `/design` | "build this", "plan the implementation", "how should I structure this" |
| `/scaffold` | "create a new module", "add another X like Y", "bootstrap a project" |
| `/refactor` | "clean this up", "make it proper", "this works but it's messy" |
| `/review-architecture` | "review the architecture", "is this well-structured" |
| `/refactoring-plan` | "what should I fix first", "prioritise these findings" |
| `/code-review` | "review this code", "check this for bugs" |

## Examples by Skill

### ideate

**Mode A — Open exploration:**
```
I need to build a system that monitors credit spreads across 500 bonds and
generates carry signals daily. What are my options?
```

**Mode B — Stress-test an existing plan:**
```
Here's my plan: I'll compute carry as the rolling z-spread minus the
sector median, rank by decile, and rebalance weekly. Poke holes in this.
```

Output: Decision summary with chosen approach, trade-offs, load-bearing
assumptions, and what to build first.

---

### architect

```
I've decided to build the carry signal system. Help me figure out what the
components should be — what are the right abstractions?
```

```
I have these domain concepts: Bond, Spread, Universe, CarrySignal,
Portfolio, RiskModel. How do they map to code?
```

Output: Domain model, rate-of-change map, module decomposition table,
dependency direction verification.

---

### design

```
Architecture is approved. Design the carry signal system — dependency graph,
interfaces, file structure.
```

```
I want to build a data pipeline that ingests Bloomberg data, computes signals,
and outputs a ranked portfolio. Design it.
```

Output: Dependency graph (Mermaid), data flow with schemas at boundaries,
key Protocol definitions, file structure, testing strategy. Waits for
approval before any code is written.

---

### scaffold

**New project:**
```
Scaffold a new project called "carry-monitor" for the carry signal system.
```

**New module in existing project:**
```
Add a new momentum signal like the existing carry signal.
```

**From pattern:**
```
Add another data source like the Bloomberg one, but for ICE.
```

Output: Complete boilerplate files with TODOs marking where to fill in
domain-specific logic. Tests included.

---

### refactor

```
This pipeline.py works but it's a single 400-line function. Clean it up.
```

```
Ok that prototype works, now make it proper.
```

Output: Step-by-step refactoring plan (approved before execution), then
restructured code with all tests passing.

---

### review-architecture

```
Review the architecture of this project. Is the structure sound?
```

```
Before I build more features, check the foundations.
```

Output: Scored report across 7 dimensions (Boundary Quality, Dependency
Direction, Abstraction Fitness, DRY, Extensibility, Testability,
Parallelisation Readiness) with specific evidence for each finding.

---

### refactoring-plan

```
I just got the architecture review and code review results. What should I
fix first?
```

```
I have tech debt everywhere. Help me plan the cleanup.
```

Output: Consolidated findings, dependency DAG, priority-scored roadmap
grouped into phases. Each step sized with effort estimate and verification
checklist. Feeds directly into the refactor skill.

---

### code-review

```
Review this code.
```

```
Check strategy/carry.py for bugs and style issues.
```

Output: Severity-ranked findings with BEFORE/AFTER code examples.

## Complete Workflow Examples

### Example 1: New Project from Scratch

```
1. "I want to build a system that monitors credit spreads and generates
    carry signals. What are my options?"                        → ideate

2. "Let's go with approach 2. What should the components be?"  → architect

3. "Architecture looks good. Design it."                       → design

4. "Design approved. Scaffold the project."                    → scaffold

5. [Fill in domain logic in the TODO-marked locations]

6. "Review this code."                                         → code-review
```

### Example 2: Extending an Existing System

```
1. "I need to add a momentum signal to the carry system.
    Where does it fit?"                                        → architect

2. "Design the integration."                                   → design

3. "Scaffold the momentum module."                             → scaffold
```

### Example 3: Structural Health Check

```
1. "Review the architecture of carry-monitor."                 → review-architecture
   (produces scored diagnostic)

2. "Review the code too."                                      → code-review
   (produces file-level findings)

3. "OK, what should I fix first?"                              → refactoring-plan
   (synthesises both reviews into prioritised roadmap)

4. "Start executing phase 1."                                  → refactor
   (executes step by step, tests passing after each)

5. "Re-review the architecture."                               → review-architecture
   (re-score to measure improvement)
```

### Example 4: "This Works But It's a Mess"

```
1. "This pipeline works but it grew organically.
    What should I fix first?"                                  → refactoring-plan

2. "Execute the plan."                                         → refactor

3. "Actually the decomposition itself is wrong."               → architect
   (re-architect if the plan reveals structural issues)
```

## Shared Principles

All skills reference `shared-principles.md`, which enforces:

- **SRP** — one reason to change per module/class/function
- **Open/Closed** — extend without modifying
- **Dependency Inversion** — domain depends on abstractions, not infrastructure
- **Interface Segregation** — narrow, focused protocols
- **DRY with nuance** — deduplicate knowledge, not code; Rule of Three
- **Python conventions** — type hints, Protocol for interfaces, dataclasses/Pydantic, pytest, click/typer

## Tips

- **Skills chain naturally.** The output of one skill is the input to the next.
  You don't need to manually pass context — just say "proceed" or name the next step.
- **Every skill stops for approval.** Design, refactoring plans, and scaffold all
  present their output for review before writing code.
- **Quantitative problems get extra scrutiny.** ideate and design both add
  mathematical specification, degeneracy analysis, and overfitting checks when
  the problem involves strategies or statistical models.
- **Parallelisation is always considered.** Every skill flags embarrassingly
  parallel components and sequential bottlenecks.
