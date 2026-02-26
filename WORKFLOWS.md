# Workflows

## How to Decide Which Workflow

```
┌──────────────────────────────────────────────────────┐
│                 What are you doing?                   │
├───────────┬───────────┬──────────┬───────────────────┤
│ Building  │ Improving │ Extending│ Not sure /         │
│ new       │ existing  │ existing │ exploring          │
│           │           │          │                    │
│ → W1      │ Run arch  │ → W4     │ → W5              │
│           │ review    │          │                    │
│           │ first     │          │                    │
│           │    │      │          │                    │
│           │    ▼      │          │                    │
│           │ Scorecard │          │                    │
│           │ result:   │          │                    │
│           │           │          │                    │
│           │ 🟢🟡 → W2│          │                    │
│           │ 🟠   → W3│          │                    │
│           │ 🔴   → W3│          │                    │
│           │ (or rare  │          │                    │
│           │  rewrite) │          │                    │
└───────────┴───────────┴──────────┴───────────────────┘
```

| Workflow | Name | When |
|---|---|---|
| W1 | Build New | Greenfield project from scratch |
| W2 | Refactor | Code works, structure is messy |
| W3 | Redesign | Boundaries are wrong, code has value |
| W4 | Extend | Add capability to existing system |
| W5 | Explore | Vague problem, need to think before committing |

---

## W1: Build New

**When:** Starting a project from scratch. No existing code.

**Skill chain:** `ideate → architect → design → plan-tracker → scaffold → plan-tracker (verify)`

```bash
mkdir ~/Gitrepos/new-project && cd ~/Gitrepos/new-project
git init

# Step 1: Explore approaches
claude "I want to build [describe the problem]. Help me ideate —
       what are my options and what are the trade-offs?"
# → Decision Summary with chosen approach
# → CHECKPOINT: you pick an approach

# Step 2: Decompose into components
claude "architect this — what should the components be,
       where do the boundaries go?"
# → Domain model, module decomposition, abstraction decisions
# → CHECKPOINT: you approve the decomposition

# Step 3: Wire it together
claude "design the architecture — dependency graph, interfaces,
       data flow, file structure"
# → Dependency graph, protocols, file tree, error handling strategy
# → CHECKPOINT: you approve the design

# Step 4: Create plan and scaffold
claude "create a tracked plan and scaffold the project"
# → PLAN-*.md created with scaffolding steps + pre-execution snapshot
# → Project files created following your conventions
# → Plan updated as each file is created
# → You fill in the domain logic

# Step 5: Verify
claude "verify the plan"
# → Confirms all scaffolding steps completed
# → Lists files created, test fixtures in place
```

**Exit state:** Scaffolded project with protocols, config, CLI entry point, test fixtures, and TODO markers where domain logic goes.

---

## W2: Refactor

**When:** Code works but the structure is painful. The components are right, the organisation is wrong.

**Indicators:** Architecture review scorecard mostly 🟢/🟡 with a few 🟠. You're not questioning *what* the pieces are, just *how* they're arranged.

**Skill chain:** `review-architecture → code-review → refactoring-plan → plan-tracker → refactor → plan-tracker (verify)`

```bash
cd ~/Gitrepos/existing-project

# Step 1: Diagnose system-level structure
claude "review the architecture of this project"
# → Scored diagnostic: 7 dimensions, dependency graph, findings
# → architecture-review.md produced

# Step 2: Diagnose file-level code quality
claude "review the code in src/"
# → Severity-ranked findings with BEFORE/AFTER snippets
# → code-review.md produced

# Step 3: Prioritise and plan
claude "create a refactoring plan from the review findings"
# → Consolidated findings, dependency DAG, Pareto analysis
# → Phased roadmap produced
# → PLAN-*.md created with all steps PENDING + pre-execution snapshot
# → CHECKPOINT: you approve the plan

# Step 4: Execute phase by phase
claude "execute Phase 1 of the refactoring plan"
# → Changes made, tests pass after each step
# → PLAN-*.md updated: steps move PENDING → DONE/FAILED
# → On failure: Claude stops and asks retry/skip/abort
# → Repeat for each phase

# Step 5: Verify
claude "verify the plan"
# → Completion check (all steps DONE or SKIPPED?)
# → Diff summary (files, lines, tests before vs after)
# → Architecture re-review with before/after scorecard
# → Verdict appended to PLAN-*.md
```

**Rules:**
- External behaviour never changes during refactoring
- Tests pass after every single step — if they don't, the step is wrong
- Never refactor and add features simultaneously
- If during refactoring you discover the decomposition itself is wrong → switch to W3

**Exit state:** Same functionality, better structure, improved scorecard.

---

## W3: Redesign

**When:** The module boundaries are in the wrong places. The core abstraction doesn't fit anymore. Individual code is fine but the architecture isn't.

**Indicators:** Architecture review scorecard has 🟠 or 🔴 on Boundary Quality, Dependency Direction, or Extensibility. Adding a new capability requires touching 5+ files (shotgun surgery). The pain is structural, not cosmetic.

**Skill chain:** `review-architecture → architect → design → refactoring-plan → plan-tracker → refactor → plan-tracker (verify)`

```bash
cd ~/Gitrepos/existing-project

# Step 1: Understand what exists and what's broken
claude "review the architecture of this project"
# → Scorecard identifies structural problems
# → architecture-review.md produced

# Step 2: Re-decompose — what SHOULD the components be?
claude "the architecture review found [summarise key findings].
       Re-architect this project — what should the components be,
       where should the boundaries go?"
# → New domain model, new boundary decisions, new abstractions
# → Side-by-side: current decomposition vs proposed decomposition
# → CHECKPOINT: you approve the new decomposition

# Step 3: Design the target state
claude "design the new architecture for the approved decomposition"
# → New dependency graph, new interfaces, new file structure
# → This is the TARGET — what the project looks like when done
# → CHECKPOINT: you approve the target design

# Step 4: Plan the migration
claude "create a refactoring plan to migrate from the current
       architecture to the new design"
# → Ordered steps from current state to target state
# → Each step leaves the system working — no big bang
# → PLAN-*.md created with all steps PENDING + pre-execution snapshot
# → CHECKPOINT: you approve the migration plan

# Step 5: Execute phase by phase
claude "execute Phase 1 of the migration plan"
# → Incremental structural changes, tests pass at each step
# → PLAN-*.md updated as steps complete
# → On failure: Claude stops and asks retry/skip/abort
# → Repeat for each phase

# Step 6: Verify
claude "verify the plan"
# → Completion check, diff summary, architecture re-review
# → Before/after scorecard confirms structural improvement
# → Verdict appended to PLAN-*.md
```

**Rules:**
- Migration is incremental. No "delete everything and start over" steps.
- Every intermediate state is a working system with passing tests.
- If a migration step can't be done safely, break it into smaller steps.
- The plan may include writing adapter code that bridges old and new structures temporarily — this is expected and gets cleaned up in later phases.

**How it differs from W2 (Refactor):**
- W2 keeps the existing module boundaries and cleans up within them
- W3 moves the boundaries themselves — modules get split, merged, renamed, or replaced
- W3 has an architect + design phase that W2 doesn't need
- W3 is harder and riskier, which is why the migration plan is critical

**Exit state:** Same functionality, fundamentally better architecture, new scorecard.

---

## W4: Extend

**When:** Adding a new capability (new strategy, new data source, new CLI command, new pipeline stage) to an existing system.

**Skill chain:** `review-architecture (optional) → architect → design → plan-tracker → scaffold → plan-tracker (verify)`

```bash
cd ~/Gitrepos/existing-project

# Step 0 (optional but recommended): Health check first
# If you haven't reviewed this repo recently, do it now.
# Adding features to a weak foundation makes the foundation weaker.
claude "review the architecture of this project"
# → If scorecard is mostly 🟢/🟡: proceed
# → If scorecard has 🟠/🔴: consider W2 or W3 first

# Step 1: Where does the new capability fit?
claude "I want to add [describe capability] to this project.
       Architect where it fits — new module? extends existing?
       where do the boundaries go?"
# → Analysis of existing structure
# → Where new code lives, what it depends on, what depends on it
# → Whether existing boundaries need adjustment
# → CHECKPOINT: you approve the placement

# Step 2: Design the integration
claude "design the integration — interfaces, data flow, how it
       wires into the existing system"
# → New/modified protocols, config changes, test strategy
# → CHECKPOINT: you approve the design

# Step 3: Create plan and scaffold
claude "create a tracked plan and scaffold the new [strategy/pipeline/module]"
# → PLAN-*.md created with scaffolding + integration steps
# → Files created following existing project conventions
# → Wired into existing CLI, config, and test structure
# → TODO markers where domain logic goes

# Step 4: Verify
claude "verify the plan"
# → Confirms all steps completed, files created, integration wired
```

**Rules:**
- Read existing code before proposing new structure. Match conventions.
- New module should be testable in isolation before integrating.
- If adding the capability reveals that existing boundaries are wrong → note it, finish the extension, then run W3 to fix the structure.

**Exit state:** New capability integrated, following existing patterns, with tests.

---

## W5: Explore

**When:** You have a vague problem or idea. You're not ready to build, redesign, or refactor. You need to think.

**Skill chain:** `ideate` (may lead to W1, W3, or W4 depending on outcome)

```bash
# Can be run from anywhere — not repo-specific
claude "I'm thinking about [describe the problem/idea].
       Help me explore the options and stress-test my thinking."
# → Mode A (open): 2-3 structurally different approaches with trade-offs
# → Mode B (stress-test): assumption audit, inversion, second-order consequences
# → Decision Summary

# Then based on outcome:
# "Build it new"       → W1
# "Redesign existing"  → W3
# "Extend existing"    → W4
# "Need more info"     → stay in W5, iterate
```

**Exit state:** Decision Summary with chosen approach, key trade-offs, and load-bearing assumptions. Ready to enter W1, W3, or W4.

---

## W6: Rewrite (rare)

**When:** The existing code's architecture is so tangled that every refactoring step would break something else. The cost of migration exceeds the cost of starting fresh.

**Bar is very high.** Most code that feels 🔴 is actually W3 (redesign). Before choosing W6, ask: "Am I being honest or just impatient?"

**Skill chain:** `review-architecture (old) → ideate → W1 (new project)`

```bash
# Step 1: Learn from the old code — don't just abandon it
cd ~/Gitrepos/old-project
claude "review the architecture of this project. Focus on:
       what works well, what's fundamentally broken, and what
       domain logic should be preserved in a rewrite."
# → Review becomes a LESSONS LEARNED document
# → Identifies salvageable domain logic (algorithms, formulas, rules)

# Step 2: Start fresh with the lessons
mkdir ~/Gitrepos/new-project && cd ~/Gitrepos/new-project
git init

claude "I'm rewriting old-project from scratch. Here's what the
       review found: [paste key findings]. Ideate the right
       approach for the new version."
# → Then follow W1: architect → design → scaffold
```

**Rules:**
- Do NOT copy-paste old code into new structure. Re-implement from the new design.
- Reference old code only for domain logic that was correct (algorithms, formulas, business rules).
- The new project should pass the architecture review with 🟢 across all dimensions from day one.

**Exit state:** New project with sound architecture, informed by lessons from the old one.

---

## Multi-Repo Workflow

When reviewing and improving multiple repos:

```bash
# Review all repos first — diagnose before treating
for repo in orch dynamic-melo credit-analytics; do
    cd ~/Gitrepos/$repo
    claude "review the architecture of this project"
done

# Compare scorecards across repos
# Prioritise: which repo's structural debt is blocking you most?
# Execute the appropriate workflow (W2/W3/W4) per repo
```

---

## Workflow Decision Cheat Sheet

| Situation | Workflow | First command |
|---|---|---|
| "I want to build something new" | W1 Build | `claude "ideate..."` |
| "This code works but it's messy" | W2 Refactor | `claude "review the architecture..."` |
| "The structure is fundamentally wrong" | W3 Redesign | `claude "review the architecture..."` |
| "I want to add a new feature" | W4 Extend | `claude "review the architecture..."` then `claude "architect where [X] fits..."` |
| "I have a vague idea" | W5 Explore | `claude "ideate..."` |
| "This is beyond saving" | W6 Rewrite | `claude "review the architecture..."` (lessons learned) then W1 |

---

## Common Transitions

Workflows aren't always linear. Common mid-workflow transitions:

| During | You discover | Switch to |
|---|---|---|
| W2 Refactor | Boundaries are wrong, not just messy | W3 Redesign |
| W3 Redesign | A specific module needs extending too | Finish W3, then W4 |
| W4 Extend | Existing structure can't accommodate the feature | W3 Redesign first, then W4 |
| W5 Explore | The problem maps to an existing repo | W4 Extend or W3 Redesign |
| W5 Explore | The problem is genuinely new | W1 Build |
| Any | Review scorecard is worse than expected | Step back, re-evaluate scope |
