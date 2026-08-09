# Shared Engineering Principles

These principles are referenced by all skills in the family. They represent the structural
discipline that every piece of code — whether ideated, designed, refactored, or scaffolded —
must respect.

## Clean Code Principles

### Single Responsibility (SRP)
Every module, class, and function should have exactly one reason to change. The litmus test:
can you describe what it does in one sentence without using "and"? If not, split it.

### Open/Closed
Design for extension without modification. Prefer composition and protocols over inheritance
hierarchies. When you find yourself adding `if isinstance(...)` branches, you probably need
a protocol or strategy pattern instead.

### Dependency Inversion
High-level modules (strategy logic, orchestration) must not depend on low-level modules
(file I/O, API calls). Both should depend on abstractions (protocols/interfaces). This is
the single most important principle for maintainability — it's what allows you to swap data
sources, execution backends, or output formats without rewriting business logic.

### Interface Segregation
Don't force consumers to depend on methods they don't use. Prefer narrow, focused protocols
over fat interfaces. A `SignalGenerator` protocol with one method is better than a `Strategy`
protocol with ten.

## DRY — But With Nuance

DRY ("Don't Repeat Yourself") is often misapplied. The principle is about **knowledge
duplication**, not code duplication. Two pieces of code that look identical but represent
different domain concepts should NOT be merged — they'll diverge as requirements evolve,
and the premature abstraction becomes a coupling point.

### When to DRY
- Same business rule expressed in multiple places → extract
- Same data transformation applied identically in 3+ locations → extract
- Same config/constants duplicated → centralise

### When NOT to DRY
- Two similar-looking functions that serve different domain purposes → leave separate
- Boilerplate that is *structurally* similar but *semantically* distinct → use templates/scaffolding, not shared base classes
- "Just in case" abstractions for code that's only used once → wait until the third use

### The Rule of Three
Don't abstract on the second occurrence. Abstract on the third. By then you have enough
examples to know what the *actual* common pattern is, rather than guessing from two data points.

## Opinionated Defaults

Blueprint prescribes a small Python stack as sensible defaults. These are conventions that reduce decision fatigue at the scaffold stage, not frameworks.

| Convention | Default | Override at gate? |
|------------|---------|-------------------|
| Config modelling | Pydantic BaseModel | Yes — dataclasses acceptable if approved at design gate |
| Interfaces | typing.Protocol | Yes — ABC acceptable if approved at design gate |
| Testing | pytest | No — fixed |
| CLI entry points | click or typer | Yes — argparse acceptable |
| Type hints | Required on all public functions | No — fixed |

Blueprint does NOT prescribe:
- Web frameworks (FastAPI, Django, Flask)
- Infrastructure (Docker, K8s, Terraform)
- Databases or ORMs
- CI/CD tooling
- Package managers beyond "use pyproject.toml"

If a user's project already uses different conventions, the design gate is where this is surfaced and resolved. Scaffold follows whatever the approved design specifies.

## Extensibility Checklist

Before considering any piece of work "done", verify:

1. **Can a new variant be added without modifying existing code?** (e.g., new strategy type, new data source, new output format)
2. **Are configuration and behaviour separated?** (config in YAML/JSON, behaviour in code)
3. **Are the module boundaries tested?** (integration tests at interfaces, unit tests for logic)
4. **Is the dependency graph a DAG?** (no circular imports, clear layering)
5. **Could someone unfamiliar with the codebase understand the structure from the directory layout alone?**

## Python Conventions

These are the user's established patterns — respect them in all generated code:

- **Type hints**: Always. Use `typing.Protocol` for interfaces.
- **Data models**: `dataclasses` for internal structures, `Pydantic` for external boundaries (config, API contracts, serialisation).
- **CLI**: `click` or `typer` for command-line interfaces.
- **Data formats**: Parquet for intermediate/analytical data, JSON for configuration.
- **Project layout**:
  ```
  project/
  ├── src/
  │   └── package_name/
  │       ├── __init__.py
  │       ├── core/        # Domain logic, protocols, core abstractions
  │       ├── data/         # Data ingestion, transformation, I/O
  │       ├── strategy/     # Strategy-specific logic (if applicable)
  │       └── execution/    # Orchestration, CLI entry points, output
  ├── tests/
  │   ├── unit/
  │   └── integration/
  ├── config/
  │   └── default.yaml
  └── pyproject.toml
  ```
- **Testing**: `pytest`, with fixtures for shared setup. Property-based testing (`hypothesis`) for numerical code where edge cases matter.
- **Logging**: `logging` module with structured output. No print statements in library code.

## Gate Behaviour

Every skill with a checkpoint gate follows this protocol:

### Three Outcomes

1. **Approved** — user says "looks good", "approved", "yes", or equivalent. Proceed to the next phase or hand off to the downstream skill.
2. **Revision requested** — user asks for changes. Revise the output, re-run the Pre-Gate Self-Check, and present again. Do not proceed until approved.
3. **Contract violation** — the Pre-Gate Self-Check fails and cannot be fixed. Stop and report which contract requirement is unmet.

### Rules

- Gates are mandatory. Never skip a gate, even if the user says "just do it" — the gate exists to catch structural errors before they propagate.
- A gate approval covers only the output presented. If you materially change the output after approval, re-present at the gate.
- If the user approves with caveats ("looks good but change X"), apply the change and confirm before proceeding. Do not silently proceed with the caveat unaddressed.
- Before presenting at a gate, check `## Pressure Packs` below. If a pack applies, its
  Final checklist is part of what you verify — and any conflict it declares is reported
  at the gate, never resolved silently.

### Refusal Protocol

When the user does not approve at a gate, respond based on what they say:

| User says | Skill should |
|---|---|
| "No, X is wrong" or "Fix X" | Revise the specific section. Re-present ONLY the changed parts, prefixed with: "Revised [section]. Other sections unchanged." |
| "I'm not sure, what about Y?" | Present Y as an alternative. Compare trade-offs with the current approach. Ask the gate question again. |
| "Back up" or "Let me rethink" | Acknowledge. Suggest re-running the upstream skill. Do not attempt to patch the current output. |

This protocol applies to all gated skills. Skills must not invent additional refusal branches.

## Pressure Packs

A pressure pack is a checklist distilled from one engineering book, held in
`principles/<book-slug>.md`. Packs carry pressure, not policy: they add checks a
skill must satisfy before it presents at its gate. They never add a gate, never
remove one, and never overrule anything above.

### How a pack declares itself

Every pack's YAML frontmatter carries:

| Field | Meaning |
|---|---|
| `pack` | Slug; must equal the filename stem |
| `book` | Title and author |
| `source`, `upstream_rev`, `license` | Provenance. For diagnosis only — nothing syncs |
| `applies_to` | Skill directory names. Each must be a directory containing a `SKILL.md` |
| `when` | The codebase-observable condition that makes the pack apply |
| `conflicts_with` | The section of this file the pack argues with, or `none` |

`applies_to` resolves against the filesystem: `<blueprint-root>/<name>/SKILL.md`
must exist. Not against `README.md`, not against any table.

`when` must be checkable by looking at the code or the design under discussion —
"the module under change has no test file" is a condition; "refactoring" is not,
because it is always true wherever the pack could load.

### When a pack loads

At your gate — the `## Pre-Gate Self-Check` where a skill has one, otherwise the
`**STOP.**` at which the skill presents its output for approval. Read the packs
whose `applies_to` names your skill and whose `when` is true of the work in front
of you. Treat each pack's `## Final checklist` as additional Pre-Gate items.

**At most two packs load per gate.** On three or more matches, report which packs
matched and load the two with the fewest `applies_to` entries; break a tie
alphabetically. The cap is per gate, not per session — a later gate re-evaluates.

### Conflicts are surfaced, never resolved

A pack that declares `conflicts_with` argues with a section of this file. When such
a pack loads, name the conflict at the gate:

> Pack `<slug>` conflicts with `<section>`. `shared-principles.md` governs; the pack
> asks for `<what>`. Proceeding under the shared principle unless you say otherwise.

**This file wins.** Packs are subordinate. The requirement is that the
disagreement is said out loud where the user can overrule it, not that it is
decided in the pack's favour.

### Adding and removing

A pack is admitted only if at least one of its items changes a gate outcome that
the existing skills miss, and the pack cites the upstream line that justifies it.
Anything the skills already enforce is cut and recorded in the pack's
`## Excluded — already covered` block with a `file:line` citation.

Admission is evidenced, not argued. A candidate pack is pasted into the gate it
claims to improve and the artefact is compared against a control run with the pack
absent. See `docs/pack-draft/PASTE-TEST.md` for the protocol and
`PASTE-TEST-RESULT.md` for the run that admitted the first pack.

Packs go stale. That is accepted: `upstream_rev` records what they were derived
from and nothing reconciles them afterwards. To roll back a pack, delete the file.

## Minimum Viable Output

Every skill must produce at least the following. Outputs below this threshold should fail the Pre-Gate Self-Check.

| Skill | Minimum output |
|---|---|
| ideate | Decision Summary with chosen approach (1 sentence) + at least 2 load-bearing assumptions |
| spec-interview | At least 3 resolved questions + revised document path + Handoff with all MUST labels |
| architect | Module table with at least 3 rows + Mermaid domain model + DAG check result |
| design | File structure (at least 3 files) + at least 1 Protocol definition + config approach |
| code-review | Executive Summary + at least 2 findings with Finding IDs + Summary Table |
| review-architecture | Scorecard with all 7 dimensions scored + at least 3 findings with Finding IDs |
| review-depth | Depth scorecard + at least 2 findings with `DM-*` Finding IDs |
| compat-audit | Verdict matrix + at least 1 fully cited pair section with all 3 scores |
| navigator | Answer citing at least 1 concrete `path:line` location, or an explicit "not found" |
| orch | Dispatch decision (delegate / refuse) + the reason, and on delegate a file-disjoint task split |
| refactoring-plan | At least 1 phase with at least 2 steps, each with all MUST fields |
| scaffold | All files from design Handoff created + at least 1 smoke test file |
| refactor | At least 1 step executed with verification checklist completed |
| plan-tracker | Objective + at least 1 phase status table + verification criteria |

If a skill cannot meet its minimum, it MUST state why: "Minimum not met: only 2 findings identified because [reason]. Proceeding with reduced output." The user decides at the gate.

## Validation

After producing a skill output, optionally run:

    python tools/contract_lint.py <output-file> --skill <skill-name>

This checks contract compliance. Recommended before committing review artifacts
to the reviews/ directory.
