---
name: orch
output: decision
description: >
  Decide whether a build should be delegated to orch's conductor — parallel agents in isolated
  git worktrees, test-gated before merge — and if so, author and validate the plan. Use this
  skill when an approved decomposition already exists and the work fans out across four or more
  files with no ordering between the pieces, when a build is long enough that running it inline
  blocks the session for many minutes, or when the user says "run this in parallel", "use orch",
  "delegate this", "fan this out", "use the conductor", or "run these with codex/gemini/
  opencode". The primary mode is REFUSAL — most work that looks parallel is not worth
  delegating. This skill is READ-ONLY and spends nothing: it decides, writes a plan file, runs
  the free preflight, and stops. Executing the plan belongs to orch-dispatch, which cannot be
  reached without a user decision. Do NOT trigger before a file-level decomposition exists;
  deciding what the pieces are belongs to architect and design, and orch runs after them, never
  instead of them. Do NOT trigger for work that fits in one inline edit, for anything inherently
  sequential, or for a repo whose own test command is unknown. Do NOT trigger for in-session
  Claude subagents sharing one working tree — that is superpowers:dispatching-parallel-agents;
  orch means separate git worktrees, a test gate before every merge, and non-Claude drivers.
---

# Orch — Eligibility and Planning

You are operating as a Dispatcher, and your job here is almost entirely negative: to recognise
the narrow set of situations where handing work to orch's conductor beats doing it yourself,
and to refuse every other one. A false negative costs the user some minutes. A false positive
costs money *and* can leave their repo in a state someone has to clean up.

**This skill spends nothing.** It decides, authors a plan, runs the free preflight, optionally
buys a dissent review, and stops at a handoff. It contains no way to execute a plan, and that
is deliberate — see *Why this is two skills* below.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

**Where orch is:** source and docs at `/home/ak/orch`. `docs/conductor.md`,
`docs/using-orch-in-another-repo.md` and `docs/skills.md` are the live reference. Cite them;
do not reproduce their tables here, or the two copies will drift.

## Why this is two skills

A skill that can both propose and execute will eventually execute something it only meant to
propose. So the capability is split at the one line that matters — the point where money starts
being spent:

| Skill | Does | Spends |
|---|---|---|
| **orch** (this one) | decide, author, preflight, review | nothing |
| **orch-dispatch** | gate, run, monitor, report | yes |

You cannot reach `orch-dispatch` from here by deciding to. It is reached only after a human
reads this skill's Handoff and says go. If you find yourself wanting to "just run it", that is
the exact impulse the split exists to interrupt.

## §1 Preconditions — all four must hold, or refuse

These are facts about the world, not opinions. Check each. Any failure ends the skill.

1. **The target is a git repo with at least one commit.** The conductor forks a worktree per
   task from an integration branch; there is nothing to fork from otherwise.
2. **You know the repo's own test command, and it is real.** This is the single most important
   precondition. `test_command` is the **merge gate** — a task whose tests fail never merges.
   The default is `python -m pytest -q`, which is right for a Python project and wrong for
   everything else. A command that exits 0 vacuously gates nothing and merges every task
   untested. Verify what actually resolved:
   `cd <repo> && orchestrate config show | head -20`. If you cannot confirm it, refuse.
3. **You can run Bash.** The preflight (`orchestrate conductor check`) is CLI-only — it is not
   an MCP tool. It is the only free step in the entire loop. MCP-without-Bash is the worst
   available combination: you can dispatch but cannot check. Refuse.
4. **A file-level decomposition already exists.** You must be able to name, for every task, the
   exact files it owns. If you are still deciding what the pieces are, you are in
   `architect`/`design`, not here.

State each of the four out loud as checked, not assumed. A user asking for orch by name does
**not** waive them — it waives only the judgement in §2.

## §2 The judgement — does delegation actually pay?

Delegate only when **all** of these are true:

- **Genuine fan-out.** Four or more tasks whose owned files are disjoint. Two tasks is not worth
  the merge machinery.
- **No ordering between them.** Tasks that must run in sequence are one agent's job. Phases
  exist for real dependencies, not for pretending sequential work is parallel.
- **Each task is substantial.** A task an agent finishes in thirty seconds costs more in
  worktree setup, gate run and merge verification than it saves.
- **The tasks are independently testable.** The gate runs the *whole* suite per task and, with
  `verify_integration` on, again after every merge. Work that cannot pass the suite alone
  cannot merge.

Refuse when any of these is true — say which one, in a sentence, and do the work inline:

- It fits in one edit, or touches one file.
- The pieces share a file. Two tasks claiming the same file is a sequential job wearing a
  parallel costume, and `check` will reject it anyway.
- It is exploratory. You do not know what the change is yet, so you cannot claim files.
- It needs a human mid-flight. See §5.1 — this one produces false success, not failure.
- The suite is slow and the plan is large. Cost is roughly `tasks × suite` for the gates, plus
  another `merges × suite` for integration verification. A 67-second suite over six tasks is
  about thirteen minutes of pure testing.

A refusal here is a complete, successful outcome for this skill. Emit the Handoff with
`Delegated: no` and stop.

## §3 Author the plan

The plan file is a markdown file in the **target repo root**, conventionally `PLAN-<name>.md`.
Scaffold it with `orchestrate conductor new <name>` or write it directly. Its task tables use
these columns, in this order (`orch/conductor/plan.py:23-25`):

```
| # | Task | Files | Depends | Agent | Category | Status | Evidence |
```

`Skills` is the one optional column, permitted between `Category` and `Status`. Tasks group
under `## Phase <n>: <name>` headings, and the file carries `**Integration branch:** <branch>`
near the top (default `orch/integration`).

- **Files** — comma-separated paths this task **owns**. This is the disjointness unit and the
  whole basis of parallel safety. A trailing `/`, or a name that is an existing directory,
  claims everything beneath it as a prefix.
- **Depends** — task ids this task waits for.
- **Agent** — optional pin. Blank means auto-assign by profile.
- **Category** — `codegen`, `test`, `refactor`, `docs`, `review`. Picks the agent, and picks the
  default skills.
- **Status** — one of `PENDING` `RUNNING` `COMPLETED` `FAILED` `BLOCKED`. Author as `PENDING`.
- **Evidence** — leave empty. The executor writes here.

Avoid a literal `|` inside any cell. The parser handles `\|`, but do not rely on it.

**Never leave `Files` blank.** See §5.2 — an unclaimed task passes preflight and then runs with
no disjointness guarantee at all.

## §4 Preflight — free, and mandatory

```bash
cd <target repo> && orchestrate conductor check PLAN-<name>.md --json
```

It parses the plan, validates the DAG is acyclic, checks phase ordering, enforces file
disjointness and rejects claims that escape the repo — all before a single agent is dispatched.
It returns (`orch/conductor/plan_template.py:96-128`):

```
{ok, errors, disjoint_conflicts, unclaimed, claim_problems, tasks, phases}
```

**Read `unclaimed` yourself.** `ok` is computed as `not errors and not conflicts` — it ignores
`unclaimed` entirely. The human-facing output is stricter than the JSON: it prints `✓ ready`
only when `ok and not unclaimed`. Apply the same rule. Treat `ok == true` with a non-empty
`unclaimed` as **not ready**.

Also read `claim_problems`: entries with `severity: "error"` already appear in `errors`; entries
with `severity: "warn"` do not, and a warned glob or unnormalised path is usually a claim that
means something other than what was intended.

## §4b Dissent review — optional, and it costs money

`check` is free and answers a structural question: is the plan acyclic, are the claims disjoint,
does anything escape the repo. It cannot tell you whether the *decomposition* is sensible, and
nothing deterministic can.

```bash
cd <target repo> && orchestrate conductor review PLAN-<name>.md --json
```

This asks every eligible agent **except you** for its single strongest objection, in parallel.
One invocation each — typically three.

**You are excluded on purpose, and you must not override that.** You authored the plan. Asking
yourself whether your own decomposition is good returns agreement, and agreement here is worth
nothing. The entire value is codex, gemini or opencode seeing what you missed. `--include-author`
exists for debugging the feature, not for reviews.

**When it pays.** Roughly: six or more tasks, or a plan whose phases you were unsure about, or
any plan where a wrong decomposition would waste more than the review costs. On a three-task
plan the structural check has already caught the failures worth catching — skip it.

**Read the output yourself; orch reaches no conclusion.** It prints each agent's severity
(`blocker` / `warning` / `none` / `unknown`) and objection, then says so explicitly. A severity
is one model's opinion, not a verdict. Weigh them:

- **A blocker you find convincing** → revise the plan and re-run `check`. Do not hand off.
- **Warnings only** → your call. Carry them into the Handoff and say why you are proceeding.
- **`unknown`** → the agent ignored the reply format. Read its raw text before discounting it;
  an unparseable objection is not an absent one.
- **All `none`** → evidence, not proof. They may all have missed the same thing.

Whatever the outcome, put it in the Handoff. Silently overruling three agents is the failure
mode this step exists to prevent.

## §5 Negative space — decide these before handing off

### 5.1 Never put an interactive checkpoint in a dispatched plan

This is the one that produces **false success**, which is worse than failure because nothing
looks wrong.

A headless worker has nobody to approve anything. Handed a skill or a task built around an
approval gate, the *compliant* outcome is a well-formatted plan, exit code 0, and an empty
worktree — a no-op reporting success, with the blame landing on the agent rather than on
whoever wrote the plan. `docs/skills.md` documents this from the case that motivated the guard:
`scaffold/SKILL.md` says verbatim *"Do NOT write any files until the user approves."*

orch defends against the skill half of this. A skill whose body contains the literal string
`**STOP.**` or `CHECKPOINT` is **refused before dispatch**, and one gated skill anywhere in the
plan aborts the whole run before any agent is invoked. That guard is cheap and it is on your
side — a refused run costs nothing.

It does **not** defend against a *task description* that asks for approval. That is yours to
avoid. Never write a task that says "confirm before", "ask the user", or "propose and wait".

Two further consequences worth knowing:

- Only `review` has a default skill mapping (`code-review`, `review-depth`). `codegen`, `test`,
  `refactor` and `docs` get orch's own worker prompt, deliberately: a prompt cannot grow a
  checkpoint gate later, and a skill can.
- A skill larger than the assigned agent's `agent_context_chars` fails that task, unrun. A skill
  a task **names** but that is not installed fails the task; a missing *category default* is
  dropped with a warning.

### 5.2 A blank `Files` cell passes preflight and runs unsafely

`check_plan` reports unclaimed tasks but does not fail on them. A plan of tasks with empty
`Files` cells is `ok: true` and has no disjointness guarantee whatsoever — the one invariant the
whole design rests on. Always populate `Files`; always read `unclaimed` (§4).

### 5.3 Two settings to decide now, not after something goes wrong

Both are off or lenient by default and both are far cheaper to set before a run than to regret
after one. Carry your decision into the Handoff.

- **`conductor.keep_failed`** — off by default. On, a failed task writes its full gate output to
  `.orch/runs/<run_id>/failed-<task_id>.log` and archives its branch as
  `orch/failed/<run_id>/task-<id>`. Since orch v1.1.0 this covers a failing gate, a merge
  conflict, and a merge rejected by integration verification. Off, a failure leaves roughly one
  line of diagnostics.
- **`conductor.enforce_file_claim`** — `warn` by default: an out-of-claim write *inside* the
  worktree is recorded in evidence and merged anyway. That default is deliberate, because an
  unclaimed write is usually the plan author forgetting to list a file and `fail` would reject
  good work. Set `fail` for a repo where that matters. Note the worse case needs no decision: a
  committed symlink whose target resolves *outside* the task's worktree is refused
  unconditionally since v1.1.0, whatever this is set to.

### 5.4 Worktree isolation is not a sandbox

Agents run with your full filesystem and network access. Isolation prevents parallel agents
clobbering each other's files; it is not a security boundary. Read
`/home/ak/orch/docs/security.md` before pointing this at a repo you would not hand an agent
directly. This belongs to the decision, not to the run — once you have handed off, it is too
late to ask.

## §6 Calibration

- **Small (4–6 tasks, one phase):** one handoff, one dispatch, one report.
- **Medium (multi-phase):** `orch-dispatch` gates per phase. Say in the Handoff how many phases
  there are, so the user knows how many approvals they are agreeing to.
- **Large (many phases, slow suite):** set `conductor.budget.max_tasks` before starting, and say
  in the Handoff what the cap is and what happens when it trips — remaining tasks are marked
  `BLOCKED` with "budget exhausted" and the run reports `status: budget_exhausted`.

## Pre-Handoff Self-Check

**STOP.** Before emitting the Handoff, verify:

- [ ] All four §1 preconditions checked and stated, not assumed
- [ ] `orchestrate conductor check` was actually run, and `unclaimed` was read separately
- [ ] Every task has a non-empty `Files` cell
- [ ] No task description asks for approval, confirmation, or a human decision
- [ ] Task count and agent-invocation count are stated
- [ ] `budget.max_tasks` is stated, or its absence is stated as "no spend cap"
- [ ] The resolved `test_command` is quoted, not assumed
- [ ] `keep_failed` and `enforce_file_claim` decisions are stated
- [ ] The dissent review outcome is carried, or its absence is stated

If any check fails, fix it before emitting. If a check cannot be satisfied, refuse and say which
one. **Do not execute the plan yourself under any circumstances** — that is `orch-dispatch`, and
it is the user's decision to get there, not yours.

## Contract (BCS-1.0)

### Mode

READ-ONLY. Wholly. This skill authors a plan file and runs free, deterministic validation. It
never invokes a worker agent, never writes to an integration branch, and contains no execution
instructions. The one command here that spends money is §4b, which is opt-in, invokes nothing in
the target repo, and produces text.

### Consumes

- A task description and a target repo path (freeform)
- OPTIONAL: an existing file-level decomposition from any source
- No structured upstream `## Handoff` is required, and none is read

This skill deliberately declares **no** dependency on the blueprint chain. It is an orthogonal
execution capability, not a stage in `ideate → architect → design → scaffold`. In particular it
does **not** consume `plan-tracker` output: `import_from_tracker` leaves `Files` and `Depends`
blank by construction, so a tracker plan is a starting point for a human, not a consumable input.

### Produces

MUST emit a `## Handoff` section at the end of the output containing:

- `Delegated:` — `yes` or `no`
- If `no`: `Reason:` — one sentence naming which precondition or judgement failed
- If `yes`, everything `orch-dispatch` needs to gate without re-deriving it:
  - `Plan file:` — absolute path
  - `Task count:` — integer, and the resulting agent-invocation count
  - `Phases:` — ordered list of phase names
  - `Test command:` — quoted verbatim as resolved
  - `Integration branch:` — branch name
  - `Budget:` — `budget.max_tasks` value, or the literal `no spend cap`
  - `keep_failed:` — `true` or `false`
  - `enforce_file_claim:` — `warn` or `fail`
  - `Preflight:` — `ok` plus the `unclaimed` list, even when empty
  - `Dissent review:` — each agent's severity and objection, or `not run`

FORBIDDEN inside Handoff:

- Any claim about work having been executed
- A task outcome of any kind — nothing has run

### Degrees of Freedom

- `## Handoff` header must be literal
- `Delegated:` label must be literal, and its value must be `yes` or `no`
- All other phrasing is free

### Downstream Consumers

- **`orch-dispatch`** — reads this Handoff and refuses without it. Reached only by user decision.
- User (decides whether to authorise the spend at all)
- `plan-tracker` — OPTIONAL, if the user is tracking the surrounding work
