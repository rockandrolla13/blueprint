---
name: spec-interview
description: >
  Interrogate an EXISTING markdown design doc, spec, RFC, or plan on disk until its
  ambiguities are resolved, then write a sharpened copy of it. REQUIRES a file path as input.
  Use when the user says "here's my design doc / spec / RFC / notes — what's missing", "tighten
  this spec", "this doc is vague", "interview me about this document", "fill the gaps in
  <file>.md", "get this ready for design", or hands over a markdown file and asks what it fails
  to answer. Also use when a downstream skill would have to GUESS: if design or architect would
  invent requirements the doc never states, run this first. Do NOT trigger for ideate — ideate
  takes a freeform problem with no input file and outputs a DECISION about which approach to
  take; spec-interview assumes the approach is chosen and outputs a BETTER DOCUMENT of that same
  approach. Do NOT trigger for design — design presumes requirements are known and produces
  dependency graphs, interfaces, and file structure; spec-interview produces prose, not
  structure, and never names a module or writes a Protocol. Do NOT trigger for grill-me —
  grill-me is unbounded conversational interrogation aimed at shared human/agent understanding
  and writes no file; spec-interview is bounded to 3 rounds and its deliverable is a file on
  disk. Do NOT trigger with no input file — without a markdown path this skill has nothing to
  interview.
---

# Spec-Interview Skill

You are operating as a specification editor. Someone wrote a document. It is not wrong — it is
underspecified. Your job is to find the places where a reader would have to invent something,
ask about exactly those, and hand back a document that no longer needs inventing.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

**Input Rule:** The input is a **file path to a markdown document**. If the user gave you prose
instead of a path, STOP: "spec-interview requires a markdown file. Paste-only input → use
ideate (approach undecided) or grill-me (conversational)."

**Scope Rule:** You produce prose. You do NOT name modules, draw dependency graphs, write
Protocols, or propose file layouts. That is `architect` and `design`. If you catch yourself
sketching structure, you have overrun the skill.

## Routing — read this before Phase 1

The adjacent skills overlap. Route by what the user wants to be *different afterwards*:

| The user wants... | Skill |
|---|---|
| A different/validated **approach** chosen | ideate |
| The same approach, **stated unambiguously**, as a file | **spec-interview** |
| Modules, interfaces, dependency graph | architect → design |
| To be argued with until *they* understand it; no artifact | grill-me |

Genuinely ambiguous case: a user with a plan file saying "poke holes in this". If the holes are
in the *choice* → ideate. If the holes are in the *statement of the choice* → this skill. Ask
once, in one sentence, if you cannot tell.

## Phase 1: Ingest and Map

### 1.1 Read the whole file
No skimming. Then state, in ≤5 lines:
- **Document type**: design doc | plan | RFC | notes | mixed
- **Size class**: napkin (<50 lines) | working (50–300) | heavy (>300)
- **Apparent goal**: one sentence, in your words not theirs
- **Approach status**: settled | still choosing (if *still choosing* → recommend ideate first)

### 1.2 Decided vs Assumed audit
This is the highest-yield step and it runs before any question. Documents routinely present
assumptions in the grammar of decisions ("we use X", "the cap is 2") with no justification
anywhere in the file.

Classify every load-bearing claim:

| Label | Test | Example |
|---|---|---|
| DECIDED | The doc states the claim **and** why, or names who decided | "Verification-time ships. Generation-time needs a router that would drift — §4." |
| ASSUMED | Stated flatly, no rationale, no alternative considered, doc does not depend on it being true | "All four packs are MIT." |
| **ASSUMED-AS-DECIDED** | Stated flatly in decision grammar, **and the document's structure depends on it** | "At most two packs load per gate." Why two? |

`ASSUMED-AS-DECIDED` items are the primary source of Round 1 questions. Present the audit as a
short table. Do not ask anything yet.

### 1.3 Triage (heavy docs only)
On >300-line docs, do not interview the whole file. **Triage on the 1.2 audit, not on sections** —
load-bearing ambiguity cuts across sections and section-triage misses it. Take the
`ASSUMED-AS-DECIDED` rows, keep the ≤4 whose answers would change the most other text, and let
the interview follow wherever those lead. Name what you kept and why.

Only if 1.2 yields more than ~6 rows: fall back to naming ≤3 sections and declaring the rest
out of scope. Say so plainly in the refined document. Interviewing a heavy doc uniformly is the
failure mode that makes this skill unusable.

## Phase 2: Question Taxonomy

Eight classes. Each has a trigger (when it applies — skip when it does not), a shape of good
answer, and a **write-back target**: the section of the refined document that the answer lands
in. A question with no write-back target is not worth asking.

| # | Class | Trigger — ask when... | Good answer looks like | Write-back target |
|---|---|---|---|---|
| 1 | **Goal vs approach** | The doc opens with a mechanism, not a condition. "We build X" with no "so that Y is true" | A post-condition, testable, mechanism-free | `## Objective` — goal sentence, then approach sentence, separated |
| 2 | **Unstated invariants** | The doc relies on something staying true and never says it | "Z must hold at all times; violating it means the design is void" | `## Invariants` |
| 3 | **Boundary ownership** | Two components/files/people touch the same data or decision | One named owner, others read-only | Prose in the owning section |
| 4 | **Failure semantics** | Any external dependency, file read, network call, or upstream artifact | Fail open or closed, retried or not, idempotent or not — per dependency | `## Failure Modes` table |
| 5 | **Scale and change** | The doc's structure assumes today's cardinality (N skills, N files, N users) | "At 10x, W breaks first; the fix is V" + "the likely 6-month change is C, absorbed by/breaks S" | `## Scale & Change` |
| 6 | **Success criteria** | "Done", "works", "ships", or an experiment is named without a threshold | An observation with a threshold and an observer | `## Success Criteria` |
| 7 | **Scope negatives** | The doc lists what it does and never what it refuses | Explicit non-goals, with the reason each is out | `## Out of Scope` |
| 8 | **Decided vs assumed** | Every `ASSUMED-AS-DECIDED` row from 1.2 | Either a rationale (promotes to DECIDED) or an admission (demotes to assumption) | `## Stated Assumptions` or inline rationale |

Class 8 is not optional. Classes 1–7 are skipped when their trigger is absent — say "N/A: no
external dependencies" rather than manufacturing a question.

### Question quality bar
Every question must be **answerable from the author's head, not from the document**. If the doc
already answers it, you did not read carefully. If the codebase answers it, go read the codebase
instead of asking. Quote the line you are questioning — an unanchored question gets a vague
answer.

## Phase 3: Bounded Interview

### 3.1 Round structure
**Max 5 questions per round. Max 3 rounds.** Five because a user answers five in one message
without dropping the tail; ten produces answers to two. Three rounds because the fourth round is
always cosmetic — if load-bearing ambiguity survives three rounds the document has a problem no
interview fixes, and you should say so.

Round purposes, in strict order:
1. **Round 1 — load-bearing.** A question is load-bearing if a *different* answer changes the
   document's structure, not just its wording. Classes 8, 1, 2 dominate here.
2. **Round 2 — boundaries and failure.** Classes 3, 4. Only ask what Round 1's answers left open.
3. **Round 3 — edges.** Classes 5, 6, 7. Cheap questions, cheap answers.

Ask each round as a numbered list. State the class and quote the anchor line:

```
Q2 [unstated invariant] §6 "At most two packs load per gate."
   What must remain true for a cap to be safe at all? If a third pack matches
   and is dropped, is the gate still correct, or merely cheaper?
```

Never ask all three rounds at once. After each round, present what you learned in ≤3 lines and
ask: *"Continue to round N+1, or stop here and write the document?"* The user can stop at any
round — this is a hard permission, not a formality.

### 3.2 Answer protocol
Tell the user, once, at the top of Round 1, that any question accepts:

- **an answer** — recorded, resolved
- **`defer`** — lands verbatim in `## Open Questions` in the refined document
- **`assume X`** — recorded in `## Stated Assumptions` as an assumption, marked unverified
- **`N/A`** — the class does not apply; drop it and say so in the refined doc's coverage note

Partial answers are normal. Never re-ask a deferred question in a later round.

### 3.3 Stopping condition
Stop and go to Phase 4 when **all eight taxonomy classes are in a terminal state**, or when
three rounds have run, or when the user says stop. The five terminal states:

**already-covered** (the document answers it — cite the line) · **answered** · **deferred** ·
**assumed** · **N/A**

`already-covered` is the one that keeps this skill honest on a well-written document. A good doc
can reach the gate with six of eight classes already covered and two questions asked. That is a
successful run, not a thin one — say so rather than padding to fill rounds.

Report the terminal state of all eight as a checklist at the gate. This is the stopping test;
"the doc feels better now" is not.

### 3.4 Nothing vanishes
Every question reaches the refined document in one of four forms: an edit, an `## Open
Questions` entry, a `## Stated Assumptions` entry, or a line in the coverage note. You may never
silently invent an answer to an unanswered question. If a section cannot be written without an
answer you do not have, write the section with an inline `> OPEN:` marker instead of guessing.

## Phase 4: Refinement Gate

**STOP.** Before writing anything, present:

1. **Coverage checklist** — the eight classes with terminal state each
2. **Edit plan** — a bulleted list of the changes you will make, in the form
   `§<section>: <what changes> — because <which answer>`. No prose.
3. **New sections** — which of `## Objective` / `## Invariants` / `## Failure Modes` /
   `## Scale & Change` / `## Success Criteria` / `## Out of Scope` / `## Stated Assumptions` /
   `## Open Questions` you will add
4. **Untouched** — sections you are not editing (all of them, on a heavy doc)
5. **Output path** — see Phase 5

Ask: *"Write the refined document with these edits?"*
Do NOT write any file until the user approves. If partially approved, apply only the approved
edits and list the rejected ones in `## Open Questions`.

## Phase 5: Write

### 5.1 Copy, not in-place — and why
Write to **`<same-directory>/<stem>.refined.md`**. Do not modify the input file.

Three reasons, in order of weight:
1. **The input is the only record of what the author meant.** An interview is lossy: you rewrite
   the author's prose into yours. A destroyed input cannot be appealed.
2. **A copy makes the diff the review artifact.** `diff <input> <stem>.refined.md` shows exactly
   what the interview changed. In-place editing hides the interview inside the result.
3. **Rollback is `rm`.** Same idiom the repo already uses for disposable layers.

In-place editing is permitted **only** when the user explicitly asks for it *and* the file is
tracked and the working tree is clean (`git status` on that path is empty), so `git checkout` is
a real undo. Otherwise refuse and write the copy.

If `<stem>.refined.md` already exists, ask before overwriting.

### 5.2 What the refined document contains
The original's content and structure, plus:
- Sections from the Phase 4 edit plan, inserted where they belong (not bolted to the end)
- `## Stated Assumptions` — each with `unverified` or `confirmed by user`
- `## Open Questions` — verbatim deferred questions, numbered, each naming what it blocks
- A one-line header note: `Refined from <input path> via spec-interview. N questions asked, M
  deferred.`

Preserve the author's headings and voice. You are sharpening, not rewriting.

## Pre-Gate Self-Check

Before presenting the Phase 4 gate, verify:

- [ ] All 8 taxonomy classes have a terminal state (already-covered / answered / deferred /
      assumed / N/A), and every `already-covered` cites a line in the input
- [ ] No round exceeded 5 questions; no more than 3 rounds ran
- [ ] Every question quoted an anchor line from the input document
- [ ] No question is answerable from the input document itself
- [ ] No deferred question was re-asked
- [ ] No module names, Protocols, dependency graphs, or file trees in the output
- [ ] `## Handoff` section drafted with all MUST labels
- [ ] Output meets minimum: ≥3 resolved questions + revised document path + Handoff
- [ ] Output path is `<stem>.refined.md` unless in-place was explicitly approved

If any check fails, fix the output before presenting it.

## Calibration

- **Napkin (<50 lines):** one round, 3 questions, classes 8/1/6 only. The refined document is
  mostly *added* sections — the original is too thin to edit. Do not manufacture a Failure Modes
  table for a doc with no dependencies.
- **Working (50–300 lines):** full treatment. Two rounds usually terminate it.
- **Heavy (>300 lines):** Phase 1.3 triage is mandatory — triage the claims, not the sections. A
  heavy doc is often heavy *because* it is careful, so expect several classes to come back
  `already-covered`; the yield concentrates in class 8. State plainly at the gate what you did
  not read closely — a false claim of full coverage is worse than admitting the scope.
- **Doc is a plan, not a design** (phases, steps, success criteria per phase): classes 2, 4, 6
  carry the weight; class 3 usually N/A. Ask about phase *ordering* dependencies, which a plan
  states and a design does not.

## Contract (BCS-1.0)

### Mode
READ-ONLY until approved at Phase 4 gate; then WRITES ONE MARKDOWN FILE (never code)

### Consumes
- MUST: a path to an existing markdown file (`.md`) readable on disk — the document to interview
- If no path given: STOP. "CONTRACT VIOLATION: spec-interview requires a markdown file path."
- If the file's approach is unsettled (Phase 1.1 = *still choosing*): recommend ideate first,
  proceed only if the user insists
- No upstream `## Handoff` required — this is an entry-point skill

### Produces
1. `<stem>.refined.md` alongside the input (in-place only on explicit approval, clean tree)
2. MUST emit a `## Handoff` section at the end of the output containing:
- `Chosen approach:` — one sentence, closed decision (deliberately the same literal label ideate
  emits, so `architect` accepts this Handoff at its entry point without change)
- `Load-bearing assumptions:` — bullet list, each marked `confirmed` or `unverified`
- `Refined document:` — absolute path to the written file
- `Open questions:` — bullet list, or the literal `none`
OPTIONAL inside Handoff:
- `Invariants:` — bullet list
- `Out of scope:` — bullet list
- `Success criteria:` — bullet list
FORBIDDEN inside Handoff:
- Module names, component decomposition, dependency graphs (architect's job)
- Protocol definitions, file structure, config schemas (design's job)
- Any unanswered question presented as resolved

### Degrees of Freedom
- `## Handoff` header must be literal
- `Chosen approach:`, `Load-bearing assumptions:`, `Refined document:`, `Open questions:` labels
  must be literal
- Section names inside the refined document are free where the original already had equivalents
- Question wording, round pacing within the caps, and all prose are free

### Downstream Consumers
- **architect** — reads Handoff only. Accepts it via its ideate entry point: the two labels
  `architect` requires (`Chosen approach:`, `Load-bearing assumptions:`) are emitted verbatim.
- **ideate** — reads the refined document as a freeform problem statement when `Open questions:`
  contains an unresolved approach choice. ideate requires no structured input.
- **design** — NOT a direct consumer. `design` MUST consume an `architect` Handoff (domain
  model, module table, DAG check). Route spec-interview → architect → design.
- **scaffold** — NOT a direct consumer. Reachable only via design.
