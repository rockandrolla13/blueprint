---
name: orch
description: >
  Decide whether to delegate a build to orch's conductor — parallel agents in isolated git
  worktrees, test-gated before merge — and if so, dispatch it safely. Use this skill when an
  approved decomposition already exists and the work fans out across four or more files with
  no ordering between the pieces, when a build is long enough that running it inline blocks
  the session for many minutes, or when the user says "run this in parallel", "use orch",
  "delegate this", "fan this out", "use the conductor", or "run these with codex/gemini/
  opencode". The primary mode is REFUSAL — most work that looks parallel is not worth
  delegating, and a wrong dispatch costs real money and can leave a broken integration
  branch. Do NOT trigger before a file-level decomposition exists; deciding what the pieces
  are belongs to architect and design, and orch runs after them, never instead of them. Do
  NOT trigger for work that fits in one inline edit, for anything inherently sequential, or
  for a repo whose own test command is unknown. Do NOT trigger for in-session Claude
  subagents sharing one working tree — that is superpowers:dispatching-parallel-agents;
  orch means separate git worktrees, a test gate before every merge, and non-Claude drivers.
---

# Orch Delegation Skill

You are operating as a Dispatcher. Your job is almost entirely negative: to recognise the
narrow set of situations where handing work to orch's conductor beats doing it yourself, and
to refuse every other one. Dispatch is **irreversible spend** — N agent invocations, commits
onto an integration branch, and wall-clock the user cannot get back. Every other blueprint
skill is read-only until a gate; this one authorises money. Weight your judgement accordingly:
a false negative costs the user some minutes, a false positive costs money *and* can leave
their repo in a state someone has to clean up.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

**Where orch is:** source and docs at `/home/ak/orch`. `docs/conductor.md`,
`docs/using-orch-in-another-repo.md` and `docs/skills.md` are the live reference. Cite them;
do not reproduce their tables here, or the two copies will drift.

## Mode Question — ask this out loud, do not infer it

Before anything else, state which mode you are in and why. Say it in the response, so the
user can correct you before money is spent.

> **Mode A (Eligibility)** — nobody has decided to delegate. I must decide, and the default
> answer is no.
>
> **Mode B (Dispatch)** — eligibility is already settled, either because the user asked for
> orch by name or because Mode A passed in this session. I run the loop.

If you cannot tell, you are in Mode A. Arriving in Mode B because the user said "use orch"
does **not** skip the preconditions in Mode A §1 — it skips only the judgement in §2.

## Mode A: Eligibility

### A.1 Preconditions — all four must hold, or refuse

These are facts about the world, not opinions. Check each. Any failure ends the skill.

1. **The target is a git repo with at least one commit.** The conductor forks a worktree per
   task from an integration branch; there is nothing to fork from otherwise.
2. **You know the repo's own test command, and it is real.** This is the single most
   important precondition. `test_command` is the **merge gate** — a task whose tests fail
   never merges. The default is `python -m pytest -q`, which is right for a Python project
   and wrong for everything else. A command that exits 0 vacuously gates nothing and merges
   every task untested. Verify what actually resolved:
   `cd <repo> && orchestrate config show | head -20`. If you cannot confirm it, refuse.
3. **You can run Bash.** The preflight (`orchestrate conductor check`) is CLI-only — it is
   not an MCP tool. It is the only free step in the entire loop. MCP-without-Bash is the
   worst available combination: you can dispatch but cannot check. Refuse.
4. **A file-level decomposition already exists.** You must be able to name, for every task,
   the exact files it owns. If you are still deciding what the pieces are, you are in
   `architect`/`design`, not here.

### A.2 The judgement — does delegation actually pay?

Delegate only when **all** of these are true:

- **Genuine fan-out.** Four or more tasks whose owned files are disjoint. Two tasks is not
  worth the merge machinery.
- **No ordering between them.** Tasks that must run in sequence are one agent's job. Phases
  exist for real dependencies, not for pretending sequential work is parallel.
- **Each task is substantial.** A task an agent finishes in thirty seconds costs more in
  worktree setup, gate run and merge verification than it saves.
- **The tasks are independently testable.** The gate runs the *whole* suite per task and,
  with `verify_integration` on, again after every merge. Work that cannot pass the suite
  alone cannot merge.

Refuse when any of these is true — say which one, in a sentence, and do the work inline:

- It fits in one edit, or touches one file.
- The pieces share a file. Two tasks claiming the same file is a sequential job wearing a
  parallel costume, and `check` will reject it anyway.
- It is exploratory. You do not know what the change is yet, so you cannot claim files.
- It needs a human mid-flight. See §D.1 — this one produces false success, not failure.
- The suite is slow and the plan is large. Cost is roughly `tasks × suite` for the gates,
  plus another `merges × suite` for integration verification. A 67-second suite over six
  tasks is about thirteen minutes of pure testing.

## Mode B: Dispatch

### B.1 Author the plan

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
- **Category** — `codegen`, `test`, `refactor`, `docs`, `review`. Picks the agent, and picks
  the default skills.
- **Status** — one of `PENDING` `RUNNING` `COMPLETED` `FAILED` `BLOCKED`. Author as `PENDING`.
- **Evidence** — leave empty. The executor writes here.

Avoid a literal `|` inside any cell. The parser handles `\|`, but do not rely on it.

**Never leave `Files` blank.** See §D.2 — an unclaimed task passes preflight and then runs
with no disjointness guarantee at all.

### B.2 Preflight — free, and mandatory

```bash
cd <target repo> && orchestrate conductor check PLAN-<name>.md --json
```

It parses the plan, validates the DAG is acyclic, checks phase ordering, enforces file
disjointness and rejects claims that escape the repo — all before a single agent is
dispatched. It returns (`orch/conductor/plan_template.py:96-128`):

```
{ok, errors, disjoint_conflicts, unclaimed, claim_problems, tasks, phases}
```

**Read `unclaimed` yourself.** `ok` is computed as `not errors and not conflicts` — it
ignores `unclaimed` entirely. The human-facing output is stricter than the JSON: it prints
`✓ ready` only when `ok and not unclaimed`. Apply the same rule. Treat `ok == true` with a
non-empty `unclaimed` as **not ready**.

Also read `claim_problems`: entries with `severity: "error"` already appear in `errors`;
entries with `severity: "warn"` do not, and a warned glob or unnormalised path is usually a
claim that means something other than what was intended.

### B.3 The gate

**STOP.** Before the first dispatch, present:

- the task table — id, one-line description, owned files, category
- the **task count** and the resulting number of agent invocations
- whether `conductor.budget.max_tasks` is set, and its value if so. If it is unset, say
  plainly that the run has **no spend cap**
- the resolved `test_command`, quoted
- the integration branch name
- this warning, verbatim in substance: *"If a task fails, its worktree and its error output
  are deleted. You will get roughly one line of diagnostics."*

Then ask: *"Dispatch this phase?"* Do not call `execute_plan` until the user approves.

The gate **recurs per phase**. One approval authorises one phase, never a whole run — which
is why §B.4 teaches `auto=false`. This matches `shared-principles.md`: a gate approval covers
only the output presented.

### B.4 Run

```
execute_plan(plan_path, auto=False, integration_branch=None, project_dir=None)
```

Signature from `orch/conductor/mcp_server.py:98-100`. `project_dir` defaults to the directory
containing the plan file — which is why the plan belongs in the target repo root. (The CLI's
cwd-only behaviour, documented in `docs/using-orch-in-another-repo.md`, is a property of
`orchestrate conductor`, not of this tool.)

Three things about this call that will otherwise mislead you:

**It blocks.** `execute_plan` runs the work inline and returns only when the phase or run is
finished. There is no handle to poll while it is outstanding. Do not write a submit-then-poll
loop; it cannot execute. Your pre-dispatch estimate at the gate is the only cost control you
get, which is why §B.3 insists on the task count.

**`auto=False` runs exactly one phase, then returns.** The MCP default is `False`; the CLI's
default is the opposite (`orchestrate conductor run` runs every phase unless `--pause`). Keep
`auto=False` and call again per phase — completed phases are skipped on re-entry, so the plan
file resumes correctly. This is deliberate: it makes the gate recur and bounds the spend.

**A partial run reports `status: "running"`.** The status is rolled up from task statuses, and
untouched later-phase tasks are still `PENDING`, which rolls up to `running` even though
nothing is executing. After a successful `auto=False` phase this is the *expected* result, not
a failure. Values are `completed` | `running` | `stopped` | `budget_exhausted`.

On success the reply is `{ok: true, run_id, plan, phases, status, budget}`. `phases` is a list
of `{phase, tasks: {task_id: STATUS}}`.

On failure it is `{ok: false, error, run_id, progress}`, where `progress` is
`{started, merged, total, tasks}`. **Read `progress`.** It is what distinguishes a plan
rejected before execution from one that put half its tasks onto the integration branch — and
the second leaves commits someone has to deal with.

### B.5 Status and cancel

```
status(run_id=None)      cancel(run_id=None)
```

**Call `status()` with no argument.** The `run_id` you get back from a successful
`execute_plan` is *not* the handle the registry uses. The server mints `run-1`, `run-2`, … but
the executor's own timestamped id overrides it in the success reply (`mcp_server.py:118`
spreads the executor result last). Passing the id you were given back to `status` returns
`{ok: false, error: "unknown run_id"}`. The `run-N` handle appears only in a *failure* reply.

Given that `execute_plan` blocks, `status` has exactly three honest uses: inspecting a run
whose call already returned, querying from a different session, and recovering after an
interruption. Nothing else.

Returns `{ok: true, run_id, status, plan, tasks}` when there is something to report;
`{ok: true, status: "idle", run_id: null}` when no run exists; and
`{ok: false, error: "unknown run_id", run_id}` for an id it does not hold. The `plan` and
`tasks` keys are absent in the idle case — do not index them unconditionally.

`cancel` stops the executor **dispatching new tasks**; it does not kill work already in
flight. Returns `{ok: true, run_id, cancelled: true}`, or
`{ok: true, cancelled: false, error: "no active run"}`. Because `execute_plan` blocks, a
cancel must come from a different session than the one that dispatched.

**Do not treat `run_id` as durable.** The registry is process-local, capped at 32 runs, with
finished runs evicted and the counter reset on every server restart. The durable artifact is
the plan file — statuses and evidence are written back into it as tasks complete, which is
what makes `orchestrate conductor report PLAN-<name>.md` work after the fact.

### B.6 Report the outcome

```bash
cd <target repo> && orchestrate conductor report PLAN-<name>.md
```

When you relay results:

- **Quote the `Evidence` cell verbatim.** Never paraphrase it, never summarise it, never
  reword a test failure into your own description of a test failure. It is frequently the
  only diagnostic that exists.
- Name every `FAILED` and `BLOCKED` task, and say which dependents were blocked by which
  failure.
- If `verify_integration` was off, say so — tasks merged without the merged result ever
  being tested.
- Say plainly what landed on the integration branch and what did not.

## Negative space — what reliably wastes money or fakes success

### D.1 Never put an interactive checkpoint in a dispatched plan

This is the one that produces **false success**, which is worse than failure because nothing
looks wrong.

A headless worker has nobody to approve anything. Handed a skill or a task built around an
approval gate, the *compliant* outcome is a well-formatted plan, exit code 0, and an empty
worktree — a no-op reporting success, with the blame landing on the agent rather than on
whoever wrote the plan. `docs/skills.md` documents this from the case that motivated the
guard: `scaffold/SKILL.md` says verbatim *"Do NOT write any files until the user approves."*

orch defends against the skill half of this. A skill whose body contains the literal string
`**STOP.**` or `CHECKPOINT` is **refused before dispatch**, and one gated skill anywhere in
the plan aborts the whole run before any agent is invoked. That guard is cheap and it is on
your side — a refused run costs nothing.

It does **not** defend against a *task description* that asks for approval. That is yours to
avoid. Never write a task that says "confirm before", "ask the user", or "propose and wait".

Two further consequences worth knowing:

- Only `review` has a default skill mapping (`code-review`, `review-depth`). `codegen`,
  `test`, `refactor` and `docs` get orch's own worker prompt, deliberately: a prompt cannot
  grow a checkpoint gate later, and a skill can.
- A skill larger than the assigned agent's `agent_context_chars` fails that task, unrun. A
  skill a task **names** but that is not installed fails the task; a missing *category
  default* is dropped with a warning.

**This skill trips that guard, by design.** The gate in §B.3 contains the literal marker, so
this file can never be dispatched to a headless worker. That is correct and intended: a skill
whose job is deciding whether to spend money has no business running somewhere nothing can
decide. Do not "fix" it by removing the gate.

### D.2 A blank `Files` cell passes preflight and runs unsafely

`check_plan` reports unclaimed tasks but does not fail on them. A plan of tasks with empty
`Files` cells is `ok: true` and has no disjointness guarantee whatsoever — the one invariant
the whole design rests on. Always populate `Files`; always read `unclaimed` (§B.2).

### D.3 A failed task destroys its own evidence

Verified on the first real conductor run (`/home/ak/orch/HANDOFF.md`, item 6): a task ran for
nine minutes, failed its gate, and left one line — `opencode: tests FAILED: 1 skipped, 1 error
in 0.08s`. The traceback was in the worktree, and `_fail()` removes the worktree and its
branch. Nothing recovers it.

So: **capture what you need before a task can fail.** Warn the user at the gate (§B.3) that
failure diagnostics will be about one line. If they need more, check whether a
`conductor.keep_failed` setting exists in the installed version before dispatching — it was
the planned fix as of 2026-08-06 and may have landed since. Do not promise a transcript you
cannot produce.

### D.4 A task can write outside its claim, and the default merges it anyway

`enforce_file_claim` defaults to `warn`: an out-of-claim write is recorded in evidence and
merged regardless. On the first live run an agent created `.venv` as a symlink into a *sibling
task's worktree*; `git add -A` committed it, it merged, and it arrived broken in the user's
repo (`HANDOFF.md`, item 8). Worktrees are sibling directories under a predictable path and
nothing stops an agent walking across. For a repo where that matters, set
`enforce_file_claim: fail` before dispatching.

### D.5 Worktree isolation is not a sandbox

Agents run with your full filesystem and network access. Isolation prevents parallel agents
clobbering each other's files; it is not a security boundary. Read
`/home/ak/orch/docs/security.md` before pointing this at a repo you would not hand an agent
directly.

### D.6 A partial run leaves the integration branch held

A fully completed run tears its integration worktree down; a partial one does not, and
`git checkout orch/integration` then fails with a bare "already used by worktree at …".
`conductor report` names the path. Free it with `git worktree remove <path>`, or discard the
branch with `git branch -D orch/integration`. Tell the user this happened rather than leaving
them to discover it.

## Calibration

- **Small (4–6 tasks, one phase):** one gate, one `execute_plan`, one report.
- **Medium (multi-phase):** gate per phase. Between phases, re-read the plan file and tell the
  user what merged before asking to proceed.
- **Large (many phases, slow suite):** set `conductor.budget.max_tasks` before starting, and
  say at the first gate what the cap is and what happens when it trips — remaining tasks are
  marked `BLOCKED` with "budget exhausted" and the run reports `status: budget_exhausted`.

## Pre-Gate Self-Check

Before presenting the gate in §B.3, verify:

- [ ] All four Mode A preconditions checked and stated, not assumed
- [ ] `orchestrate conductor check` was actually run, and `unclaimed` was read separately
- [ ] Every task has a non-empty `Files` cell
- [ ] No task description asks for approval, confirmation, or a human decision
- [ ] Task count and agent-invocation count are stated
- [ ] `budget.max_tasks` is stated, or its absence is stated as "no spend cap"
- [ ] The resolved `test_command` is quoted, not assumed
- [ ] The failure-diagnostics warning is present

If any check fails, fix it before presenting. If a check cannot be satisfied, refuse to
dispatch and say which one.

## Contract (BCS-1.0)

### Mode

READ-ONLY until approved at gate

Mode A is wholly read-only. Mode B before §B.3 is read-only (authoring a plan file and running
the free preflight). Everything after the §B.3 gate spends money and writes to the target
repo's integration branch, and is unreachable without explicit user approval.

### Consumes

- A task description and a target repo path (freeform)
- OPTIONAL: an existing file-level decomposition from any source
- No structured upstream `## Handoff` is required, and none is read

This skill deliberately declares **no** dependency on the blueprint chain. It is an orthogonal
execution capability, not a stage in `ideate → architect → design → scaffold`. In particular it
does **not** consume `plan-tracker` output: `import_from_tracker` leaves `Files` and `Depends`
blank by construction, so a tracker plan is a starting point for a human, not a consumable
input.

### Produces

MUST emit a `## Handoff` section at the end of the output containing:

- `Delegated:` — `yes` or `no`
- If `no`: `Reason:` — one sentence naming which precondition or judgement failed
- If `yes`:
  - `Plan file:` — absolute path
  - `Phases run:` — count
  - `Task outcomes:` — table with columns `Task | Status | Evidence`, Evidence quoted verbatim
  - `Integration branch:` — branch name, and whether it is clean or held by a worktree

OPTIONAL inside Handoff:

- `Budget:` — the `budget` snapshot from the reply
- `Cleanup required:` — commands the user must run

FORBIDDEN inside Handoff:

- Any paraphrase of an Evidence cell
- A claimed outcome for a task that did not reach `COMPLETED`
- A `run_id` presented as durable

### Degrees of Freedom

- `## Handoff` header must be literal
- `Delegated:` label must be literal, and its value must be `yes` or `no`
- Evidence must be reproduced character-for-character
- All other phrasing is free

### Downstream Consumers

- User (decides whether to keep, revert, or clean up the integration branch)
- `plan-tracker` — OPTIONAL, if the user is tracking the surrounding work
- No blueprint skill reads this Handoff as a required input
