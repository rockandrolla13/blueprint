# CLAUDE.md

## Style

- Sacrifice grammar for concision
- Be technical; don't sacrifice content
- No time estimates in plans
- Don't overengineer: simple instruction beats elaborate framework
- Surgical edits: modify the minimum to fix the problem

## Rules

Multi-step tasks require explicit planning before implementation.

1. Create plan file — `docs/plans/YYYY-MM-DD-<task-name>.md`:
   * Objective (1 sentence)
   * Phases (numbered)
   * Dependencies between phases
   * Success criteria per phase
   * Risk register

## What This Repo Is

Composable Claude skills for architecture-first engineering. Not software — instruction
files (.md) that shape how Claude reasons about architecture, design, and maintenance of
Python codebases. Skills encode workflows with checkpoint gates; shared-principles encodes
engineering knowledge.

**Build workflow:** `ideate → architect → design → scaffold`
**Review workflow:** `code-review + review-architecture → refactoring-plan → refactor`

## Repo Structure

```
blueprint/
├── CLAUDE.md                      ← you are here
├── README.md                      # Skill map, installation, quick decision table
├── WORKFLOWS.md                   # Six execution workflows with concrete commands
├── shared-principles.md           # Engineering principles + Python conventions (SINGLE SOURCE OF TRUTH)
├── ideate/SKILL.md                # Explore solution space, stress-test thinking
├── architect/SKILL.md             # Domain decomposition, abstraction mapping, boundary drawing
├── design/SKILL.md                # Dependency graph, data flow, interfaces, file structure
├── scaffold/SKILL.md              # Generate boilerplate from reusable templates
├── refactor/SKILL.md              # Restructure existing code without changing behaviour
├── review-architecture/SKILL.md   # System-level structural diagnostic (scored, read-only)
├── refactoring-plan/SKILL.md      # Prioritised roadmap from review findings to execution
└── code-review/SKILL.md           # File-level Clean Code review (external, may not be present)
```

## File Roles — What Goes Where

| Content type | Location | Rule |
|---|---|---|
| Engineering principles (SOLID, DRY, KISS, PoLA, etc.) | `shared-principles.md` | Single source of truth. Never duplicate into skills. Skills reference it. |
| Python conventions (type hints, dataclasses, Pydantic, project layout) | `shared-principles.md` | Same — all convention knowledge lives here. |
| Workflow process (phases, checkpoints, reasoning steps) | `<skill>/SKILL.md` | Each skill owns its own workflow. |
| Trigger conditions (when to use, when NOT to use) | `<skill>/SKILL.md` YAML frontmatter | Must include both positive and negative triggers. |
| User-facing workflows (concrete commands, decision trees) | `WORKFLOWS.md` | The "how to use blueprint" reference. |
| Skill map, installation, repo overview | `README.md` | Keep synced when adding/removing skills. |
| Large reference material (>300 lines) | `<skill>/references/*.md` | Only when SKILL.md approaches 500 lines. |
| Templates for scaffolding | `scaffold/templates/` | Extracted when patterns stabilise. |

## Anatomy of a Skill

```yaml
---
name: skill-name
description: >
  What it does. When to trigger (positive). When NOT to trigger (negative).
  Descriptions are deliberately pushy to combat undertriggering.
---
```

Body follows this structure:
1. Role statement — what Claude is operating as
2. Reference to shared-principles.md
3. Phases with clear numbered steps
4. **Checkpoint gate** — hard stop requiring user approval before proceeding
5. Calibration notes — how to scale for small/medium/large tasks

## Editing Skills

**Before modifying any skill, read it fully.** Understand the existing phases and checkpoint
placement before making changes.

**Invariants — never violate these:**
- Every skill must have at least one checkpoint gate where Claude stops and asks for approval
- Skills are either read-only diagnostics OR action skills — never both in the same skill
- No skill writes code before a design/plan is approved
- Shared principles are never duplicated into individual skills

**When modifying a skill:**
- Preserve checkpoint gates — they are the core mechanism
- Maintain section numbering consistency (if you add 2.4, renumber 2.5+)
- Keep SKILL.md under 500 lines. If approaching, extract to `references/`
- Test the trigger description: would a user saying [X] activate this skill and NOT a sibling?

**When adding a new skill:**
1. Create `<skill-name>/SKILL.md` with YAML frontmatter
2. Include positive triggers ("use when...") AND negative triggers ("do NOT trigger for...")
3. Ensure negative triggers cover adjacent skills to prevent overlap
4. Add the skill to the README skill map table
5. Add the skill to the relevant workflow in WORKFLOWS.md
6. If the skill introduces new principles → add to shared-principles.md, reference from skill

**When adding a new principle:**
1. Add to `shared-principles.md`
2. Reference from relevant skills with `→ **Read**: shared-principles.md`
3. Do NOT copy the principle text into the skill

**When modifying WORKFLOWS.md:**
- Every workflow must have: concrete `claude` commands, checkpoint markers, exit state
- Update the decision tree at the top if adding/removing workflows
- Update the cheat sheet table at the bottom
- Update the transitions table if new workflow interactions exist

## Anti-Patterns to Avoid

| Anti-pattern | Why it's wrong | What to do instead |
|---|---|---|
| Duplicating principles into a skill | Divergence — two copies drift apart | Reference shared-principles.md |
| Skill that both diagnoses and fixes | Conflates read-only analysis with code changes | Split into review skill + action skill |
| Removing a checkpoint gate | Lets Claude skip user approval, defeats the purpose | Always preserve gates |
| Skill description that's too generic | Triggers on everything or nothing | Add specific positive AND negative triggers |
| Adding time estimates | Estimates are unreliable and create false precision | Describe scope and complexity instead |
| Fat SKILL.md (>500 lines) | Too much context for Claude to hold effectively | Extract to references/ subdirectory |
| Prescribing specific frameworks/libraries | Makes skills brittle and narrow | State the principle, let the project decide the tool |

## Testing Changes

This repo has no automated tests. Validation is manual:

1. **Read the modified skill end-to-end** — does it flow logically? Are phases numbered correctly?
2. **Check cross-references** — if you added a section to shared-principles.md, does at least one skill reference it?
3. **Trigger overlap check** — read the frontmatter descriptions of adjacent skills. Would a given user prompt trigger exactly one skill, not zero or two?
4. **Checkpoint presence** — confirm every skill has at least one "STOP / ask the user" gate.
5. **Consistency** — do the README skill table, WORKFLOWS.md decision table, and actual skill files all agree on what exists?

## Common Tasks

**"Add a new engineering principle"**
→ Edit `shared-principles.md`. Reference from relevant skills. Do not duplicate.

**"Add a new skill"**
→ Create directory + SKILL.md. Update README table. Update WORKFLOWS.md. Check trigger overlap.

**"Improve an existing skill"**
→ Read it fully. Make surgical edits. Preserve checkpoints. Maintain numbering.

**"Add a new workflow"**
→ Edit WORKFLOWS.md. Add to decision tree, cheat sheet, and transitions table. Update README.

**"User reports a skill triggers incorrectly"**
→ Adjust frontmatter description. Add or sharpen negative triggers. Check sibling skills for overlap.
