Run a review-refactor-review cycle. $ARGUMENTS

ROUND 1 — REVIEW:
Run review-architecture, code-review, and review-depth.
Present unified findings with Finding IDs.
Gate: I approve which findings to fix.

ROUND 2 — PLAN:
Build a refactoring plan from the approved findings only.
Present the plan with step-level tracking.
Gate: I approve the plan.

ROUND 3 — REFACTOR:
Execute the plan one step at a time.
Verify after each step. Commit after each step.

ROUND 4 — RE-REVIEW:
After all steps complete, re-run the same three review skills.
Present a before/after comparison:
- Which findings are resolved? (should match DONE steps)
- Which findings remain? (should match SKIPPED steps)
- Any NEW findings introduced by the refactoring?
- Scorecard delta across all dimensions

If new findings exist, ask: "Another cycle?"
