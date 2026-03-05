Resolve PR review comments thoroughly. $ARGUMENTS

PHASE 1 — UNDERSTAND THE REVIEW

Read all PR review comments. For each comment classify it:

| Type | Meaning | Example |
|---|---|---|
| QUICK | Style, naming, typo, missing type hint | "rename this variable" |
| LOGIC | Bug, wrong behaviour, edge case missed | "this fails when input is empty" |
| STRUCTURAL | Reviewer wants a different design approach | "this should be a separate module" |
| CLARIFICATION | Reviewer doesn't understand, needs docs or explanation | "what does this function do?" |
| DISAGREE | I may want to push back on this | flag for my decision |

Present the classified list. Do not fix anything yet.
Gate: I confirm classifications and flag any DISAGREE items.

PHASE 2 — CROSS-REFERENCE

Run code-review and review-depth on ONLY the files touched by the PR.
For each reviewer comment, check:
- Does Blueprint's analysis agree with the reviewer?
- Did Blueprint find additional issues the reviewer missed?
- Is a STRUCTURAL comment actually a symptom of a deeper problem
  (e.g., reviewer says "split this function" but the real issue is
  a shallow module or leaky abstraction)?

Present a merged findings table:

| # | Reviewer comment | Blueprint finding | Agree? | Deeper issue? |
|---|---|---|---|---|

Gate: I approve which findings to address.

PHASE 3 — PLAN

Build a fix plan ordered by:
1. LOGIC fixes first (correctness)
2. STRUCTURAL fixes (may change file boundaries)
3. QUICK fixes (batch by file)
4. CLARIFICATION (add docstrings/comments)
5. Skip DISAGREE items I flagged

Each fix gets:
- Step ID (N.M)
- Source: reviewer comment + Blueprint finding ID if applicable
- Files touched
- Verification: how to confirm the fix is correct
- Risk: does this fix affect other parts of the PR?

Present the plan. Gate before execution.

PHASE 4 — EXECUTE

One step at a time.
After each step: run tests, show diff, wait for approval.
After all steps: run code-review on changed files to verify
no new issues introduced.

PHASE 5 — RESPONSE DRAFT

For each reviewer comment, draft a reply:
- QUICK/LOGIC/STRUCTURAL: "Fixed in [commit] — [one line description]"
- CLARIFICATION: "Added docstring/comment explaining [what]"
- DISAGREE: Draft a respectful pushback with reasoning for my review

Present all replies for my approval before posting.
