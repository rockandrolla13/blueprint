# PASTE-TEST — does verification-time pressure change anything?

A zero-file experiment. Nothing is written to `/home/ak/blueprint`. Nothing is
written to the target repo. Two `refactor` runs, one diff, one decision.

**The question:** does a pack read at the gate change the plan, or does it arrive
too late to matter?

**Why it decides something.** If verification-time pressure works, the pack layer
ships as designed and the router stays deferred forever. If it does not, the only
version worth building is generation-time, which costs a router and re-opens the
zero-`SKILL.md`-edits question. This experiment is the difference between shipping
`CONSOLIDATED-DESIGN.md` and rewriting it.

---

## 1. The target module

**Concrete candidate, verified present on this machine:**

```
/home/ak/research_worker/src/research_harness/runner/backends.py    (86 lines)
```

It qualifies on every criterion below:

| Criterion | Evidence |
|---|---|
| Real code, not a fixture | Two live callers: `src/research_harness/runner/__init__.py:1`, `src/research_harness/runner/execute.py:30` and `:205` |
| Genuinely untested | `grep -rn "backends\|LocalBackend\|ExecutionBackend\|ExecutionResult\|BACKENDS" tests/` returns nothing. The repo has 22 test files, so this is a gap, not an untested repo |
| Ambient inputs that block repeatable tests | `time.monotonic()` (`:44`, `:62`), `now_iso()` (`:43`, `:61`), `platform.node()`/`platform()`/`processor()` (`:63-64`) — WELC `M18` verbatim |
| Hard output | `subprocess.Popen` constructed inline at `:47`; two file handles opened at `:46` — WELC `M7` "hard outputs, hard construction" |
| Module-level global | `BACKENDS` dict at `:84-86` — WELC `M7` "globals, statics" |
| A branch that cannot be observed without a seam | The `TimeoutExpired` → `SIGTERM` → `kill` escalation at `:50-57`. Reaching it in a test requires controlling a real subprocess's death |
| Small enough that two plans are legible side by side | 86 lines. The diff between plans is the artefact; it must be readable |

**If it has changed or been deleted**, select a replacement by these criteria, in
order:

1. Under 150 lines, one module, at least one class.
2. Zero references from any test file — check by name, not by import path.
3. At least two of: a clock/environment/randomness read, an inline `subprocess`,
   `open()`, or network client construction, a module-level mutable global.
4. At least one error-recovery branch not reachable from a normal call.
5. Has at least one caller in the same repo — a module nobody uses produces a plan
   about nothing.

Do not use a file from `/home/ak/blueprint`; blueprint has no Python worth
refactoring and the test would measure nothing.

---

## 2. Protocol

Both runs start from a clean context. **Run B must not be a continuation of run A**
— the whole experiment is invalid if the second plan can see the first.

### Run A — control

Prompt, verbatim:

> Refactor `/home/ak/research_worker/src/research_harness/runner/backends.py` so it
> can be tested. Do not write any files. Stop at the Phase 3 plan.

Save the Phase 3 output — sections 3.1 Refactoring Steps and 3.2 Migration Safety —
to `run-A.md`.

### Run B — treatment

Same prompt, same module, fresh context, plus: paste the entire `## Final checklist`
section of `principles/working-effectively-with-legacy-code.md` and prefix it with

> Before presenting the Phase 3 plan at the Review Checkpoint, verify the plan
> against this checklist and revise it where it does not satisfy an item.

Save the same two sections to `run-B.md`.

**Paste point.** `refactor/SKILL.md:142-146`, the Phase 3.3 Review Checkpoint. Not
the Pre-Gate Self-Check — `refactor` does not have one. Only 8 of blueprint's 12
skills do, and `refactor` is not among them. This is a correction to the brief; see
`CONSOLIDATED-DESIGN.md` § Pushback P1 and P2.

The Review Checkpoint is the right target anyway: it is the gate immediately before
the plan is acted on, so it is exactly the verification-time load point the design
specifies.

---

## 3. What to diff

Not a text diff. Five specific questions, answered from both plans:

| # | Question | Run A | Run B |
|---|---|---|---|
| D1 | How many steps does the plan contain? | | |
| D2 | Does any step name a seam by `file:line` or `Class.method`? | | |
| D3 | Does any step say whether a seam is for sensing, separation, or both? | | |
| D4 | For each dependency broken, is the *barrier* named (constructor work / global / ambient read / hard output), or only the technique ("extract a protocol")? | | |
| D5 | Does the plan's Remaining debt name a retirement condition for any test-only structure it introduces? | | |

D2–D5 are the four things the pack claims to add. D1 is a control: if run B is
simply longer without differing on D2–D5, the pack added words, not pressure.

**Predicted control result.** Run A very likely produces something close to:
"extract a `Clock` protocol, extract a `ProcessLauncher` protocol, inject both".
That is a competent plan and blueprint gets there without any pack. The question is
not whether run A is bad. It is whether run B is *different in kind* — whether it
names `LocalBackend.execute:47` as the seam, says it is for separation, identifies
`subprocess.Popen` as hard construction distinct from `time.monotonic()` as an
ambient read, and books a cleanup obligation for whatever it injects.

---

## 4. Decision rule

**Material difference — ship the design as written.**

At least three of D2–D5 flip from absent in A to present in B. Verification-time
pressure changes the artefact. `principles/` plus the `shared-principles.md`
section is the whole mechanism; the router stays deferred indefinitely.

**No difference — verification-time is too late.**

D2–D5 identical, or run B differs only in wording. The pack arrived after the plan
was already committed to its shape, and the model rationalised rather than revised.
Only generation-time loading is worth building: a generated `principles/PACKS.md`
router read on skill entry, with the `SKILL.md`-edit question reopened. **Do not
ship the packs on a null result** — four unread files are worse than none, because
they look like coverage.

**Partial — one or two of D2–D5 flip.**

Ship WELC alone and re-run this test against `release-it` at the `design` gate
before adding a second pack. A partial result most likely means the pack is doing
work where blueprint is silent (seams, which blueprint never mentions) and failing
where blueprint already speaks (dependency breaking, which
`design/SKILL.md:100-101` half-covers). That is useful information about which
items survive.

---

## 5. Recording it

One file, `PASTE-TEST-RESULT.md`, in the same staging directory. The D1–D5 table
filled in, both plans quoted in full, and one sentence naming which branch of § 4
fired. If the result is ambiguous it is a null result — the design does not get the
benefit of the doubt from its own author.

---

## 6. What this does not test

- Whether the *other three* packs work. Only WELC is exercised.
- Whether a pack helps a user who is not the model. It measures artefact change,
  not decision quality.
- Whether the two-pack cap or the conflict-surfacing protocol behave correctly —
  only one pack loads, and WELC declares `conflicts_with: none`. Those need a
  separate exercise at the `design` gate where `release-it` fires.
- Whether the checklist items are *right*. A plan can satisfy all seven items and
  still be a bad plan.
