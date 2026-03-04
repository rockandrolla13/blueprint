Full deep clean: slim + navigate + review cycle. $ARGUMENTS

This chains three passes in order:

PASS 1 — SLIM (reduce bloat first):
Run /slim analysis. Present findings. Gate.
Fix approved items. Commit.

PASS 2 — NAVIGATE (improve discoverability):
Run /navigate analysis. Present plan. Gate.
Execute approved items. Commit.

PASS 3 — VERIFY:
Re-run review-architecture, code-review, and review-depth.
Present before/after scorecard comparison across all dimensions.
Flag any regressions.

Gate between each pass. I can stop after any pass.
