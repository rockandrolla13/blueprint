# After Reboot — Do This

Written 2026-08-07 before a reboot. Action checklist. For *why* any of it, read
`docs/RESUME-STATE.md` — this file is what to do, that file is what happened.

---

## Step 1 — Verify nothing was lost

```bash
cd /home/ak/blueprint
git status --short          # expect exactly: ?? docs/  and  ?? orch/
find docs -type f | sort    # expect 10 files
wc -l docs/pack-draft/*.md docs/pack-draft/principles/*.md | tail -1   # expect 1366
wc -l docs/plans/2026-08-07-first-pass-prerequisites.md                # expect 544
```

If `docs/` is missing, the work is gone and nothing below applies. It was rescued
out of the session scratchpad in `/tmp`, which does not survive a reboot.

Two things deliberately live outside this repo and are expected to be affected:

- The upstream clone of `agent-rules-books` was in `/tmp` and is **gone**. Fine —
  it is public, pinned at `a7d7649044505b9c377c8dca28d2d6a543bc7f8c` (2026-05-13),
  and every drafted pack already carries `source:` and `upstream_rev:`. Only re-clone
  if you want to re-verify a citation:
  `git clone https://github.com/rockandrolla13/agent-rules-books && git -C agent-rules-books checkout a7d7649`
- The paste-test target is in a different repo. Confirm it still exists:
  `wc -l /home/ak/research_worker/src/research_harness/runner/backends.py` (expect 86).
  If it has moved, selection criteria are in `docs/pack-draft/PASTE-TEST.md`.

**Optional but recommended:** `git add docs/ && git commit -m "Pressure-pack design drafts and prerequisite plan"`.
Nothing under `docs/` is tracked yet. One `rm -rf docs` and it is all gone again.

---

## Step 2 — Answer three decisions

Nothing downstream should start until these are settled.

### Decision 1 — Gate invariant wording  ← blocks the most

`CLAUDE.md` states: *"Every skill must have at least one checkpoint gate where Claude
stops and asks for approval."* Three read-only diagnostics cannot satisfy this without
inventing a ritual — they emit a report and have no subsequent write to withhold.

| Option | Cost |
|---|---|
| **A (recommended)** — amend the invariant to name two legitimate forms: action skills need an approval gate; read-only diagnostics need a `## Pre-Gate Self-Check` and a Contract block | 2 lines in `CLAUDE.md`, 1 in `domain.md:100`. Deletes no gate. Leaves `navigator` as the sole genuine violation |
| B — add literal `**STOP.**` to `code-review`, `review-architecture`, `review-depth` | 3 skill files gain gates that gate nothing. The pack layer inherits the ritual at every checklist |

Blocks prerequisite Phase 4. Two independent agents reached this from different
directions, which is why it is first.

### Decision 2 — Three packs or four

`code-complete` scores 🔁 Overlap 78% "choose one" against Clean Code upstream, and
blueprint's `code-review` is a Clean Code skill by construction. Its cut ratio is the
worst of the four: 32 upstream rules → 4 retained, 12 excluded as already covered.

**Recommended: drop it.** Ship `working-effectively-with-legacy-code`, `release-it`,
`designing-data-intensive-applications`. If dropped, delete
`docs/pack-draft/principles/code-complete.md` and remove its row from `WRITE-PLAN.md`.

### Decision 3 — Run the paste test before building anything

**Recommended: yes.** It writes zero files and can return "do not ship this design."

---

## Step 3 — Run the paste test

Full protocol in `docs/pack-draft/PASTE-TEST.md`. Shape of it:

1. Target: `/home/ak/research_worker/src/research_harness/runner/backends.py` (86 lines,
   zero test references across 22 test files, two live callers).
2. Run blueprint's `refactor` skill against it **as-is**. Capture the Phase 3 plan.
3. Run it again with WELC's `## Final checklist` pasted into
   `refactor/SKILL.md:142-146` — §3.3 Review Checkpoint. **Not** a Pre-Gate Self-Check;
   `refactor` does not have one.
4. Diff the two Phase 3 plans.

| Outcome | What it means | Do next |
|---|---|---|
| Plans differ materially | Verification-time pressure works. Design B earns its keep | Step 4 |
| Plans identical | Pressure arrives too late at the gate | Build only the **generated** router (generation-time). Do not ship the gate mechanism |
| Second run is worse | Pressure is fighting blueprint's own guidance | Stop. Re-examine the conflict-declaration rule before anything else |

Restore `refactor/SKILL.md` afterwards — `git checkout refactor/SKILL.md`.

---

## Step 4 — Execute, in this order only

Only if Step 3 says proceed.

| # | Work | Source |
|---|---|---|
| 4.1 | Two one-line unblockers: add `→ **Read**: shared-principles.md` to `review-depth/SKILL.md`; declare that `applies_to` resolves against the filesystem | `docs/pack-draft/WRITE-PLAN.md` |
| 4.2 | Prerequisite Phases 0–4 | `docs/plans/2026-08-07-first-pass-prerequisites.md` |
| 4.3 | Re-run the per-pack exclusion audit — Phase 3 adds a `CMNT` finding type that covers `code-complete` item 4 exactly | `WRITE-PLAN.md` conflict C1 |
| 4.4 | Insert the `## Pressure Packs` section into `shared-principles.md` | `docs/pack-draft/shared-principles.PRESSURE-PACKS-SECTION.md` |
| 4.5 | Copy the approved packs into `principles/` | `docs/pack-draft/principles/` |

Three known conflicts between the pack plan and the prerequisite plan are tabled in
`WRITE-PLAN.md`. Only **C2** needs a real decision: the new section shifts
`shared-principles.md`'s Minimum Viable Output table from lines 141–151 to 189–199, so
prerequisite Phase 4's `S13` check must anchor on the `## Minimum Viable Output` heading
rather than line numbers. Either ordering works if it is heading-anchored; neither works
if it is not.

---

## Do not

- **Do not hand-write `principles/PACKS.md`.** The router is deferred. If ever built it
  is generated from pack frontmatter with a `--check` mode. Blueprint is 0-for-5 at
  keeping hand-synced registries in sync, and `ARCHITECTURE-QA.md:346` already records
  "Don't add a router."
- **Do not add a `Packs applied:` field to any Handoff.** It would require editing every
  named skill's `### Produces` contract, destroying the zero-`SKILL.md`-edits property
  that is the entire reason Design B was chosen. Deferred to v2.
- **Do not put the pack load rule inside `shared-principles.md`'s `Gate Behaviour`
  section.** Gate semantics are near-frozen; the pack rule will churn. Separate section.
- **Do not build an upstream sync mechanism.** Staleness is accepted. `upstream_rev:` is
  for diagnosis only. Rollback is deleting the file.
- **Do not admit `patterns-of-enterprise-application-architecture`.** The only two hard
  conflicts in upstream's 14×14 grid are DDD❌PoEAA and IDDD❌PoEAA, and blueprint's
  `architect` is DDD-flavoured.

---

## Watch for

**The riskiest thing in the design.** `when:` is the entire targeting mechanism and is
the one field a lint provably cannot check. A pack written as `when: refactoring` fires
at every `refactor` gate, permanently occupies one of the two cap slots, and starves the
pack that actually applied. Mitigation is procedural: the admission review must read
`when:` and reject always-true conditions. No mechanism fix — one would be the
elaborate-framework failure `CLAUDE.md` warns against.

**Coverage moves, and nothing detects it.** A pack admitted today can be invalidated by a
skill edit tomorrow. Step 4.3 handles the one known instance. There is no general detector.
