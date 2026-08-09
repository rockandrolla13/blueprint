---
name: code-review
output: scored-report
description: "Use when reviewing Python code FILE BY FILE for correctness, conciseness, and adherence to project conventions. Produces a severity-ranked Markdown report of CR-* findings. Triggers: user says 'review this code', 'code review', 'check this for bugs', or asks for feedback on Python source files. Do NOT trigger for system-level structure, boundary quality, or dependency direction — that is review-architecture. Do NOT trigger for module interface depth, cognitive load, or information hiding — that is review-depth. Do NOT trigger for conflicts between instruction files, skills, or rule sets — that is compat-audit. Do NOT trigger to CHANGE code — this skill is read-only; execution is refactor. Do NOT trigger for paper/manuscript review or general writing feedback."
---

# Code Review Skill

FEEDBACK ONLY. Reviews Python code and produces a severity-ranked Markdown report. Never modifies, creates, or overwrites source files. The only file this skill creates is the review report.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

## Philosophy

Two non-negotiable priorities, in order:
1. Avoidance of subtle bugs — correctness above all.
2. Minimal, economical code — every line should earn its place.

These are not in tension. Concise code has less surface area for bugs.

## Workflow

1. **Ingest** — Read files from the repository or conversation context.
2. **Analyze** — Evaluate against CLAUDE.md conventions and governance documents. Categorize each finding by pillar and severity.
3. **Report** — Produce the review as a Markdown file using the Output Template below. Print the full review to the user AND save to disk.

## Severity Levels

| Level | Meaning |
|-------|---------|
| 🔴 Critical | Likely bugs, silent data corruption, security holes |
| 🟠 Major | Significant maintainability / readability / correctness risk |
| 🟡 Minor | Style, naming, small conciseness improvements |
| 🔵 Suggestion | Optional — idiomatic or economy improvements |

## Output Template

Every finding MUST include a Finding ID as the first element.
Format: `CR-<TYPE>-<NNN>`
TYPE is one of: BUG, STYLE, SOLID, DRY, PERF, TYPE
NNN is zero-padded sequential starting at 001.

```markdown
# Code Review Report

**Files reviewed:** [list]
**Date:** [date]
**Overall health:** [🟢 Good | 🟡 Needs attention | 🔴 Needs significant work]

## Executive Summary
[2–4 sentences: overall impression, dominant patterns, top priority action.]

## Findings

### CR-BUG-001: [Finding title]
- **Severity:** 🟠 Major
- **Pillar:** Single Responsibility / Conciseness / etc.
- **Location:** `filename.py:L42-L58`

BEFORE:
[original snippet — quote the relevant code exactly]

AFTER:
[illustrative sketch ≤10 lines — NOT copy-paste-ready code]

WHY:
[one-line rationale linking to the principle violated]

## Summary Table
| Finding ID | Severity | Pillar | Location | Finding |
|------------|----------|--------|----------|---------|

## Positive Highlights
[2–3 things the code does well.]
```

## Pre-Gate Self-Check

Before saving the report, verify your output against the contract:

- [ ] Every finding has a Finding ID in format CR-<TYPE>-<NNN>
- [ ] `## Handoff` section exists at the end of the output
- [ ] Handoff contains summary table with columns: Severity | Pillar | Location | Finding | Finding ID
- [ ] Handoff contains NO BEFORE/AFTER code snippets (keep those in report body only)
- [ ] Output meets minimum: ≥ 2 findings with IDs + Summary Table

If any check fails, fix the output before saving.

## Review Checkpoint

**STOP.** Present the review — Executive Summary, findings, Summary Table — in the session
first. Then ask: *"Save this to `reviews/`?"*

Do NOT write the file until the user approves. This skill declares `Mode: READ-ONLY`; writing
a versioned file into the repo unasked would make that declaration false. If the user declines,
the review still stands — it has already been delivered in the session.

## Constraints

- Every AFTER sketch must be semantically equivalent to its BEFORE. If a change would alter behaviour, flag it explicitly.
- Keep control flow explicit — never suggest clever tricks that obscure logic.
- Every suggested edit must have a clear, articulable purpose.
- Do NOT change public interfaces (function signatures, class APIs) without noting downstream impact.
- Reference specific line numbers in every finding.
- Do NOT add tests. If tests would be valuable, note: `[SUGGEST: add test for X]`.
- For large files (>500 lines), prioritise 🔴 and 🟠 in the executive summary.
- If the user asks to apply changes, remind them this skill is feedback-only and suggest a separate refactoring workflow.
- Never generate diffs, patches, or replacement files.
- Never run linters, formatters, or fixers that alter files.

## File Storage & Versioning

- **Path:** `reviews/` (relative to repository root)
- **Format:** `YYYY_mm_dd_<scope>_review.md` where `<scope>` is descriptive (e.g., `orderFlow`, `compute_zscore_signal`, `imbalance`)
- **Purpose:** Creates a permanent record for implementation tracking and future reference.
- **Versioning:** Use Glob to check for `YYYY_mm_dd_<scope>_review*.md`. If matches exist, parse the highest version number and increment. Original without suffix is implicitly v1; first duplicate gets `_v2`.
- **Confirm:** Notify user of the full versioned filename after saving.

## Handling Reviewer Notes

When reviewer notes are provided instead of (or alongside) code:
1. Parse individual feedback items — split numbered lists, bullet points, unnumbered feedback.
2. Extract distinct change requests. Clarify ambiguous items before starting.
3. Use TaskCreate to create actionable tasks — break down complex feedback, make tasks specific and measurable.
4. Mark first task as in_progress before starting work.

## Contract (BCS-1.0)

### Mode
READ-ONLY

### Consumes
- Python source files from the user's project
- No structured upstream Handoff required

### Produces
MUST emit a `## Handoff` section at the end of the output containing:
- Summary table with columns: Severity | Pillar | Location | Finding | Finding ID
- Finding IDs format: CR-<TYPE>-<NNN> where TYPE is: BUG, STYLE, SOLID, DRY, PERF, TYPE
FORBIDDEN inside Handoff:
- BEFORE/AFTER code snippets (keep in report body only)

### Degrees of Freedom
- Severity: 🟢🟡🟠🔴
- Location: path/to/file.py or path/to/file.py:L42 or path/to/file.py:L42-L58
- Pillar: Correctness | Style | SOLID | DRY | Performance | Types
- Finding title text is free

### Downstream Consumers
- refactoring-plan (reads Handoff only, merges with review-architecture)
