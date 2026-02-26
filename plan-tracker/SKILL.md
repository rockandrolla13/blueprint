---
name: plan-tracker
description: >
  Create, update, and verify tracked execution plans for multi-step work. Use this skill
  whenever starting any multi-step workflow (refactor, redesign, build, extend). Also use
  when the user says "create a plan", "track this", "what's the status", "verify the plan",
  or "show me what's done". This skill MUST be triggered before any multi-step execution
  begins — it creates the plan file that other skills update as they work. Do NOT trigger
  for single-step tasks, quick questions, or exploratory ideation that hasn't committed to
  an approach.
---

# Plan Tracker Skill

You are the execution tracking system. Your job is to create structured plans that persist
as markdown files, update them as work progresses, and verify completion at the end. Every
multi-step workflow in blueprint flows through you.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

## Three Modes

### Mode 1: Create Plan

Triggered at the start of any multi-step workflow. Takes input from upstream skills
(refactoring-plan, architect, design) and produces a tracked plan file.

**Plan file location:** Same directory as the code being changed.
**Plan file name:** `PLAN-<task-name>.md` (e.g., `PLAN-refactor-orch.md`)

**Plan file format:**

```markdown
# Plan: <task name>

**Created:** <date>
**Workflow:** <W1/W2/W3/W4>
**Source:** <what produced this plan — e.g., refactoring-plan, architect + design>
**Target directory:** <path to code being changed>

## Objective

<1-2 sentences: what this plan achieves when complete>

## Pre-Execution Snapshot

<captured before any changes — used for verification at the end>

- **Architecture review score:** <scorecard if available, otherwise "not run">
- **File count:** <number of .py files in target>
- **Total lines:** <line count>
- **Test status:** <passing/failing/no tests>

## Phases

### Phase 1: <name>

| # | Step | Status | Notes |
|---|------|--------|-------|
| 1.1 | <description> | PENDING | |
| 1.2 | <description> | PENDING | |
| 1.3 | <description> | PENDING | |

### Phase 2: <name>

| # | Step | Status | Notes |
|---|------|--------|-------|
| 2.1 | <description> | PENDING | |
| 2.2 | <description> | PENDING | |

## Verification Criteria

<what must be true when all phases are DONE — derived from objective>

- [ ] All steps DONE or explicitly SKIPPED with reason
- [ ] Tests pass
- [ ] <objective-specific criterion>
- [ ] <objective-specific criterion>

## Execution Log

<append-only log — each entry timestamped>
```

**Rules for plan creation:**
- Every step must be small enough to complete in a single Claude Code turn
- Every step must leave the system in a working state (tests pass)
- Steps within a phase are sequential; phases may have dependencies noted
- Capture the pre-execution snapshot immediately — file count, line count, test status
- If an architecture review was run, record the scorecard scores

### Mode 2: Update Plan

Triggered during execution. Other skills (refactor, scaffold, etc.) call into this mode
to update step status.

**Status values:**

| Status | Meaning |
|---|---|
| `PENDING` | Not started |
| `IN PROGRESS` | Currently executing |
| `DONE` | Completed successfully |
| `FAILED` | Attempted, did not succeed |
| `SKIPPED` | Deliberately skipped with reason |
| `BLOCKED` | Cannot proceed — dependency not met |

**Update protocol:**

1. Before starting a step: set status to `IN PROGRESS`
2. After completing a step: set status to `DONE`, add brief note of what changed
3. On failure: set status to `FAILED`, add error description to Notes column
4. Append an entry to the Execution Log with timestamp and detail

**On FAILED status — stop and ask the user:**

Present three options:
- **Retry** — attempt the step again (possibly with a different approach)
- **Skip** — mark as `SKIPPED`, record the reason, continue to next step
- **Abort** — stop execution, leave plan in current state for later resumption

Do NOT continue to the next step without the user's explicit choice.

### Mode 3: Verify Plan

Triggered when all phases are complete, or when the user asks "verify the plan" or
"are we done?"

**Verification produces three things:**

#### 3.1 Completion Check

Read the plan file. For every step:
- `DONE` → pass
- `SKIPPED` → pass (with reason recorded)
- `FAILED` → fail — flag it
- `PENDING` → fail — work remains
- `BLOCKED` → fail — unresolved dependency

Report:
```
## Completion: X/Y steps done, Z skipped, W failed
```

#### 3.2 Diff Summary

Compare pre-execution snapshot to current state:

```
## Changes
- **Files:** <before> → <after> (net +/- N)
- **Lines:** <before> → <after> (net +/- N)
- **Tests:** <before status> → <after status>
- **Key changes:** <bullet list of major structural changes>
```

#### 3.3 Architecture Re-Review (if applicable)

If the pre-execution snapshot included an architecture review score, re-run
`review-architecture` and produce a before/after scorecard:

```
## Architecture Comparison

| Dimension              | Before | After |
|------------------------|--------|-------|
| Boundary Quality       | 🟡     | 🟢    |
| Dependency Direction   | 🟠     | 🟡    |
| ...                    | ...    | ...   |
```

#### 3.4 Final Verdict

```
## Verdict

<COMPLETE / PARTIAL / INCOMPLETE>

<1-2 sentence summary: what was achieved, what remains if anything>
```

Write the verification output to the plan file itself, appended at the bottom under
a `## Verification Report` heading. The plan file is now the complete record of what
was planned, what happened, and what the outcome was.

## Plan File Discovery

When asked to update or verify, find the plan file by:
1. Look for `PLAN-*.md` in the current working directory
2. If multiple exist, ask the user which plan to work with
3. If none exist, tell the user no active plan was found

## Resumption

Plans are designed to be resumable. If the user returns after an interruption:
1. Read the plan file
2. Find the first step that is `PENDING` or `IN PROGRESS`
3. Confirm with the user: "Last completed step was X. Resume from Y?"
4. Continue execution

## Calibration

- **Small task (3-5 steps):** Single phase, minimal plan overhead
- **Medium task (6-15 steps):** 2-3 phases, full plan format
- **Large task (15+ steps):** Multiple phases, consider splitting into multiple plans

For tasks with fewer than 3 steps, skip the plan file — the overhead isn't worth it.
Just execute directly.
