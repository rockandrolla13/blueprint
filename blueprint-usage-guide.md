# Blueprint Usage Guide — Prompts, Workflows & Skill Chaining

## How Skills Work Together

Skills are Markdown instructions that Claude Code reads automatically. You don't
need to invoke them by name — describe what you want and the right skills trigger.
But being explicit is faster and more reliable.

**Three ways to chain skills:**

1. **Natural language** — describe the task, skills trigger from context
2. **Explicit skill names** — "Run review-architecture then code-review"
3. **Slash commands** — `/blueprint refactor` (routes to the right chain)

All three produce the same result. Explicit names are most reliable.

---

## Quick Reference: All Workflows

| Workflow | When | Chain | Prompt shortcut |
|---|---|---|---|
| W0 Triage | "Something's wrong, not sure what" | review-arch + code-review → recommend | "Triage this codebase" |
| W1 Build | New project from scratch | ideate → architect → design → scaffold | "Build a new package for X" |
| W2 Refactor | Working code, painful structure | reviews → refactoring-plan → refactor | "Refactor this codebase" |
| W3 Redesign | Fundamentally wrong architecture | reviews → architect → design → refactor | "Redesign the architecture" |
| W4 Extend | Add feature to existing code | review-arch [opt] → ideate → architect → design → scaffold | "Add X to this codebase" |
| W5 Explore | Vague idea, need to think | ideate only → pick W1/W3/W4 | "Help me think through X" |
| W6 Rewrite | Nuclear option | Gate: "honest or impatient?" → W1 | "Rewrite everything" |

---

## Workflow Prompts

### W0 — Triage: "What's wrong?"

**When:** You have code that's broken, slow, confusing, or "needs work" but you
haven't diagnosed the problem.

**Basic:**
```
Triage this codebase. Run review-architecture and code-review.
Present findings and recommend a workflow.
```

**With review-depth (deep modules + cognitive load):**
```
Run a full triage: review-architecture, code-review, and review-depth.
I want to understand:
1. Are the boundaries right? (architecture)
2. Are there bugs or style issues? (code)
3. Is it hard to navigate and understand? (depth)
Present all three sets of findings together and recommend a workflow.
```

**For research code:**
```
Triage this research codebase. Run review-architecture, code-review,
and review-depth. Weight your scoring for research code:
- Multiple implementations of similar logic is OK if they serve
  different experiments
- Extensibility matters most: can I add a new experiment without
  touching existing modules?
- Progressive disclosure matters: can a new collaborator understand
  the package in 5 minutes?
Present findings and recommend a workflow.
```

**Against an existing analysis:**
```
There is an existing analysis at [path]. Read it as prior art.
Run review-architecture, code-review, and review-depth.
For each finding, state whether the existing analysis identified it,
missed it, or got it wrong.
Present findings and recommend a workflow.
```

---

### W1 — Build: "New project from scratch"

**When:** You're starting fresh. No existing code.

**Basic:**
```
I want to build a Python package that does X. Run ideate — explore
2-3 approaches, stress-test each, then present a Decision Summary.
Do not proceed to architecture until I approve.
```

**Interview mode (recommended for complex projects):**
```
I want to build X. Before proposing anything, interview me:
- What problem does this solve?
- Who uses the output?
- What are the inputs and outputs?
- What are the hard constraints?
- What existing tools/libraries should I integrate with?

Ask at least 5 questions. Then run ideate with the full context.
```

**After ideate approval:**
```
Approved. Proceed through the full build chain:
architect → design → scaffold. Gate at each step.
```

**Full chain in one prompt (if you know exactly what you want):**
```
Build a Python package called "draci" that does X.

Constraints:
- Must integrate with Y
- Must expose Z as the public API
- Research code, not production — optimise for extensibility
  and reproducibility over performance

Run ideate → architect → design → scaffold. Gate at each step.
Start with ideate.
```

---

### W2 — Refactor: "Fix the structure"

**When:** Working code, but the structure is painful. Tests exist (or should).

**After triage:**
```
Proceed with W2 Refactor. Build a refactoring plan from the triage
findings. Prioritise by: structural issues first, then DRY violations,
then extensibility improvements. Use the Finding IDs from both reviews.
```

**Without prior triage (runs reviews first):**
```
This codebase needs structural cleanup. Run review-architecture and
code-review first, then build a refactoring plan from the findings.
Present the plan for approval before making any changes.
```

**Targeted refactor (specific module):**
```
The [module-name] module is too complex. Run code-review and
review-depth on just this module. Then build a refactoring plan
targeting only this module. Do not touch other modules.
```

**With deep modules focus:**
```
Run review-depth on this codebase. Then build a refactoring plan
that specifically targets:
1. Shallow modules (depth ratio < 5) — deepen their interfaces
2. Missing progressive disclosure — add curated __init__.py files
3. High cognitive load modules — simplify interfaces

Use the DM-* Finding IDs in the plan.
```

**Execute an existing plan:**
```
There is a plan at [path]. Run plan-tracker to convert it into a
tracked PLAN-*.md with step-level status tracking. Present the
PLAN file for approval before starting execution.
```

**Continue execution after interruption:**
```
Resume execution of the plan at PLAN-[name].md. Check which steps
are DONE and which are PENDING. Start with the next PENDING step.
```

---

### W3 — Redesign: "Architecture is fundamentally wrong"

**When:** Triage revealed the structure is so wrong that refactoring within the
current architecture won't help. Need to rethink boundaries before fixing.

**After triage:**
```
The triage shows fundamental architecture problems. Proceed with W3
Redesign. Use the review findings to inform a new architecture:
architect → design → then refactoring-plan to migrate from old to new.
Gate at each step.
```

**Extract a subpackage:**
```
I want to extract [module] from this repo into a standalone package.
Run review-architecture on the current code to understand dependencies.
Then architect the new package as a separate entity. Design the
interfaces. Scaffold the new package structure. Finally, plan the
migration from embedded to standalone.
```

---

### W4 — Extend: "Add a feature"

**When:** Existing code is reasonably structured. You want to add something new.

**With review (recommended):**
```
I want to add [feature] to this codebase. Before designing anything,
run review-architecture to check the current boundaries are sound.
Then ideate the feature: explore 2-3 approaches. Gate before architect.
```

**Interview mode for unclear features:**
```
I want to extend this codebase with new capabilities. Before proposing
anything, interview me. Ask at least 5 questions about:
- What problem each feature solves
- Who consumes the output
- What format the output should be
- How it relates to existing functionality
- Whether it's one-off or recurring

Features I'm considering:
- [Feature 1]
- [Feature 2]
- [Feature 3]

After the interview, run ideate. Gate before architect.
```

**Direct extension (you know exactly what to add):**
```
Add a [specific feature] to this codebase. The feature should:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Run architect → design → scaffold. Do NOT overwrite existing modules —
extend only. Gate at each step.
```

---

### W5 — Explore: "I have a vague idea"

**When:** You're not sure what you want yet. Just thinking out loud.

```
I'm thinking about [vague idea]. I don't know if this is a new project,
a feature addition, or a refactor of something existing.

Run ideate in exploration mode. Present 3 different interpretations
of what I might mean, with trade-offs for each. Don't commit to an
approach — help me figure out what I actually want.
```

```
Help me think through [problem]. What are my options? I want to
understand the trade-offs before deciding what to build.
```

---

## Combined Skill Prompts

### Full diagnostic (all review skills)

```
Run all three review skills on this codebase:
1. review-architecture — boundaries, dependencies, extensibility
2. code-review — bugs, style, DRY, types
3. review-depth — module depth, progressive disclosure, cognitive load

Present a unified scorecard across all three, then list findings
sorted by severity. Recommend a workflow.
```

### Code quality + depth (no architecture)

Use when architecture is fine but individual modules are messy:

```
Run code-review and review-depth on [module or directory].
I want to know: are there bugs, and is the module well-designed
for someone who isn't me to navigate?
```

### Architecture + depth (no code review)

Use when code quality is fine but navigation and structure are painful:

```
Run review-architecture and review-depth. I don't care about code
style or bugs right now — I want to understand if the boundaries
are right and if the codebase is navigable.
```

### Pre-extension check

Use before W4 to make sure you're not extending into a broken foundation:

```
I'm about to add [feature]. Before I design anything, run
review-architecture and review-depth on the modules that will
be affected: [list modules]. Tell me if the current structure
will support the extension or if I need to refactor first.
```

### Post-refactor verification

Use after completing a refactoring plan:

```
The refactoring plan at PLAN-[name].md is complete. Run plan-tracker
in verification mode. Also re-run review-architecture and review-depth
to see if the scores improved. Compare before/after.
```

### Signposting pass (docstrings + types)

Use when the code works but is undocumented:

```
Run review-depth on this codebase. Focus only on signposting:
which public functions are missing docstrings and type hints?
Then build a refactoring plan that adds signposts to all public
functions, starting with the most-imported ones. Do not change
any logic — only add docstrings and type annotations.
```

### Deep modules enforcement

Use as a quality gate before merging or releasing:

```
Run review-depth. Flag any module with:
- Depth ratio below 5
- Missing __all__ in __init__.py
- More than 20 cognitive load score
- Public function without docstring

If any 🔴 findings, do not approve. List what needs fixing.
```

---

## Research-Specific Prompts

### Review a research codebase

```
This is a research codebase, not production. Run review-architecture,
code-review, and review-depth. Adjust scoring:
- Multiple implementations OK if for different experiments
- Extensibility is king: can I add a new experiment in one file?
- Registry/plugin patterns preferred over hard consolidation
- Reproducibility > test coverage > performance
Present findings weighted for research priorities.
```

### Extract a research tool into a package

```
I want to extract [tool] from this research repo into a standalone
package that other researchers can pip install.

Step 1: Run review-architecture on the current repo to map dependencies
Step 2: Run review-depth on [tool] to assess interface quality
Step 3: Ideate the package structure — interview me about:
  - Who installs this? (me only, my team, public)
  - What's the minimum viable public API?
  - What should be hidden as implementation detail?
Step 4: Architect the new package
Step 5: Design interfaces with progressive disclosure
Step 6: Scaffold

Gate at every step. Start with Step 1.
```

### Add a new experiment/analysis type

```
I want to add a new [experiment type] to this research codebase.
It should follow the same pattern as existing experiments but be
completely independent — no shared mutable state.

Interview me first:
- What data does this experiment consume?
- What outputs does it produce?
- Does it need to compare against existing experiments?
- Should results be stored in the same format?

Then ideate → architect → design → scaffold. Extend only, do not
modify existing experiment code.
```

### Build a results index

```
Run W4 Extend. I want an HTML index page for the results directory.
Requirements:
- Scans results/ recursively
- Groups by experiment type, then date
- Clickable links to each result file
- Flags known-broken results with a warning
- Regeneratable via a single command

Ideate first — ask me about groupings and filters I want.
```

---

## Maintenance Prompts

### Regular health check (run monthly)

```
Run review-architecture, code-review, and review-depth.
Compare against the last triage (if PLAN files exist in reviews/).
What improved? What regressed? Any new problems?
```

### Pre-commit quality gate

```
I'm about to commit changes to [files]. Run code-review on just
these files. Flag anything 🔴 or 🟠. Don't review the whole codebase —
just the changed files.
```

### Onboarding check

```
A new collaborator is joining this project. Run review-depth and
assess: can someone unfamiliar with this code understand the package
structure and start contributing within 30 minutes? If not, what
needs to change?
```

---

## Chaining via Slash Commands

If `/blueprint` is installed at `~/.claude/commands/blueprint.md`:

```
/blueprint                    → shows decision tree, asks what you want
/blueprint triage             → W0: review-arch + code-review → recommend
/blueprint build              → W1: ideate → architect → design → scaffold
/blueprint refactor           → W2: reviews → plan → refactor
/blueprint extend             → W4: review [opt] → ideate → architect → design → scaffold
/blueprint explore            → W5: ideate only
```

If `/hypothesis` is installed at `~/.claude/commands/hypothesis.md`:

```
/hypothesis src/module.py     → generate property-based tests for a module
/hypothesis focus on validators → generate tests for specific area
```

These are convenience shortcuts. You can always type the full prompt instead.

---

## Skill Inventory

### Blueprint (workflow skills — chained via contracts)

| Skill | Mode | What it does |
|---|---|---|
| ideate | READ-ONLY | Explore solution space, stress-test approaches, close on one |
| architect | READ-ONLY | Decompose domain into modules with boundaries |
| design | READ-ONLY | Define interfaces, protocols, file structure |
| scaffold | WRITES CODE | Generate project files from approved design |
| code-review | READ-ONLY | Severity-ranked code findings with CR-* IDs |
| review-architecture | READ-ONLY | 7-dimension architecture scorecard with AR-* IDs |
| review-depth | READ-ONLY | Deep modules + progressive disclosure with DM-* IDs |
| refactoring-plan | READ-ONLY | Phased steps from review findings |
| refactor | WRITES CODE | Execute plan steps with verification |
| plan-tracker | CROSS-CUTTING | Track plan progress, verify completion |

### Research (standalone — not part of Blueprint chains)

| Skill | What it does |
|---|---|
| paper-scout | Weekly literature scan by research track |
| paper-lit-finder | Quick top 4-5 paper finder |
| literature-mapper | Map a subfield, find gaps, propose claims |
| idea-refiner | Refine claims after reading new papers |
| paper-reviewer | Referee report for stat/ML manuscripts |
| core-paper-review-skill-special | Extended reviewer for measure theory / point processes |
| extract-algorithm | Extract core algorithm from paper into implementation spec |

### Reasoning (standalone)

| Skill | What it does |
|---|---|
| core-reviewer | Deep reasoning for proof verification, assumption auditing |

### Utility (standalone)

| Skill | What it does |
|---|---|
| skills-help | List available skills, disambiguate when unclear |
| state-of-repo | Quick snapshot of repo health |

---

## Common Mistakes

**1. Skipping triage before extending.**
"Add feature X" → ideate → architect → design on broken foundations.
Fix: Always run at least review-architecture before W4.

**2. Running refactor without a plan.**
"Just clean this up" → Claude makes ad-hoc changes with no tracking.
Fix: Always go through refactoring-plan → plan-tracker → refactor.

**3. Approving too fast at gates.**
The gate is where you catch mistakes. If the architect output looks wrong,
say so. "Revise" is cheaper than debugging a bad scaffold.

**4. Merging review findings manually.**
"I read the review, here's what I think we should fix" → skips Finding IDs.
Fix: Let refactoring-plan consume the Handoff sections directly.

**5. Not running review-depth.**
Architecture might be fine but the modules are shallow wrappers with no
progressive disclosure. review-architecture won't catch this.

**6. Using W6 Rewrite when W2 Refactor would work.**
Almost always, you're impatient, not honest about needing a rewrite.
