# Golden Example: plan-tracker — pricefeed

Demonstrates a complete plan-tracker output (Mode 1: Create Plan) for the
pricefeed refactoring. Utility skill — no Handoff section.

---

## Scenario

**Upstream:** refactoring-plan Handoff with 7 phased steps across 3 phases.

**Workflow:** W2 Refactor

---

## Example Output: PLAN-refactor-pricefeed.md

```markdown
# Plan: Refactor pricefeed

**Created:** 2025-03-15
**Workflow:** W2 Refactor
**Source:** refactoring-plan (from code-review + review-architecture findings)
**Target directory:** src/pricefeed/

## Objective

Eliminate circular dependencies, decompose the god function, extract protocols
for extensibility, add tests, and consolidate duplicated validation — leaving
the system functionally identical but structurally sound.

## Pre-Execution Snapshot

- **Architecture review score:**
  | Dimension | Score |
  |---|---|
  | Boundary Quality | 🟠 |
  | Dependency Direction | 🟠 |
  | Abstraction Fitness | 🟡 |
  | DRY & Knowledge | 🟡 |
  | Extensibility | 🔴 |
  | Testability | 🟠 |
  | Parallelisation | 🟡 |
- **File count:** 5 .py files
- **Total lines:** 680
- **Test status:** no tests

## Phases

### Phase 1: Foundation — Break Cycles and Add Types

| # | Step | Source | Status | Evidence | Notes |
|---|------|--------|--------|----------|-------|
| 1.1 | Break circular dependency between fetchers and cache | AR-DEP-001 | PENDING | | |
| 1.2 | Introduce package structure (core/, fetchers/, validators/, cache/, cli/) | AR-BND-001 | PENDING | | |
| 1.3 | Fix cache silent failure bug (remove fetch-on-miss) | CR-BUG-001 | PENDING | | Depends on 1.1 |
| 1.4 | Add type annotations to all public functions | CR-TYPE-001 | PENDING | | Depends on 1.1 |

### Phase 2: Structure — Decompose and Add Protocols

| # | Step | Source | Status | Evidence | Notes |
|---|------|--------|--------|----------|-------|
| 2.1 | Decompose god function run_all() into 4 focused functions | CR-SOLID-001 | PENDING | | Depends on 1.2 |
| 2.2 | Extract PriceFetcher protocol and fetcher registry | AR-EXT-001 | PENDING | | Depends on 1.2, 1.4, 2.1 |

### Phase 3: Quality — Tests and DRY

| # | Step | Source | Status | Evidence | Notes |
|---|------|--------|--------|----------|-------|
| 3.1 | Add unit and integration tests | AR-TST-001 | PENDING | | Depends on 1.1, 1.3 |
| 3.2 | Consolidate duplicated validation logic | CR-DRY-001, AR-DRY-001 | PENDING | | |

## Verification Criteria

- [ ] All steps DONE or explicitly SKIPPED with reason
- [ ] Tests pass (`pytest tests/`)
- [ ] No circular imports (each module importable independently)
- [ ] Adding a new data source requires only 1 new file + config entry
- [ ] No function exceeds 30 lines
- [ ] Architecture review scorecard improves on all 🟠/🔴 dimensions

## Execution Log

Every Execution Log entry MUST start with an ISO 8601 timestamp.
Format: `YYYY-MM-DDTHH:MM:SS`, local time.
```

---

## Checkpoint Output

Plan created at `PLAN-refactor-pricefeed.md`.

- **Objective:** Eliminate structural debt while preserving all external
  behaviour
- **Phases:** 3 phases, 8 total steps
- **Pre-execution snapshot:** 5 files, 680 lines, no tests, architecture
  score 🟠 overall
- **Phase 1:** Foundation — 4 steps (break cycle, package structure, fix bug,
  add types)

Ready to begin execution?

---

## Notes

- No `## Handoff` — plan-tracker is a utility skill
- Source column traces each step back to upstream Finding IDs
- Depends-on relationships recorded in Notes column
- Plan file is the single source of truth for execution state
