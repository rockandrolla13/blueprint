# PASTE-TEST — result

**Run:** 2026-08-07. Protocol: `PASTE-TEST.md`.
**Target:** `/home/ak/research_worker/src/research_harness/runner/backends.py` (86 lines,
unchanged — verified `git status` clean in both repos before and after).
**Pack under test:** `principles/working-effectively-with-legacy-code.md`, `## Final checklist`.

## Verdict

**PARTIAL — § 4 branch three fired.** Two of D2–D5 flipped. The rule required three to
ship the design as written.

**Action: ship WELC alone. Re-run this test against `release-it` at the `design` gate
before admitting a second pack.**

## D1–D5

| # | Question | Run A (control) | Run B (treatment) | Flip |
|---|---|---|---|---|
| D1 | Step count | 8 | 6 | control only — B is *shorter*, so the pack did not merely add words |
| D2 | Seam named as `file:line` / `Class.method` | **present** | **present** | no — already present without the pack |
| D3 | Sensing vs separation declared per seam | absent | **present** | **YES** |
| D4 | Barrier named before technique | **present** | **present** | no — already present without the pack |
| D5 | Retirement condition for test-only structure | absent | **present** | **YES** |

## What this actually showed

The control plan was substantially better than the design predicted. `PASTE-TEST.md:104-110`
forecast run A would produce "extract a `Clock` protocol, extract a `ProcessLauncher` protocol,
inject both" — unlocated and undiagnosed. It did not. Run A cites `lines 63-65`, `lines 50-57`,
`line 43`, `LocalBackend.execute`, and diagnoses a distinct barrier per step with a distinct
technique for each. D2 and D4 were therefore satisfied with no pack at all.

**Because D2 and D4 were already present in the control, three flips were arithmetically
impossible before run B was read.** This was recorded before opening run B.

The protocol predicted the shape of this outcome at `PASTE-TEST.md:134-138`: a partial result
means "the pack is doing work where blueprint is silent (seams, which blueprint never mentions)
and failing where blueprint already speaks". That is exactly what happened. D3 and D5 are
seam-lifecycle concepts — is this seam for observing or replacing, and what retires it — that
appear nowhere in blueprint. D2 and D4 are location and diagnosis, which blueprint already does.

Run B labelled all six steps with `Barrier removed`, `Kind`, `Purpose`, and `Seam lifetime`,
and correctly marked four seams PERMANENT (production structure with a production default,
nothing retires them) against two TEMPORARY with named retirement conditions. That distinction
is the substance of D5, not vocabulary compliance.

## Deviation from protocol

`PASTE-TEST.md:78` specifies pasting the checklist into `refactor/SKILL.md` at §3.3 and
restoring afterwards. The checklist was instead delivered inline in run B's prompt, marked as
a requirement at §3.3 Review Checkpoint.

Reason: `refactor/SKILL.md` is now committed, and both runs executed concurrently. Editing the
file mid-run risked the control reading the treatment, which invalidates the experiment
outright. Inline delivery applies the pressure at the same phase and gate. The paste point had
also moved from `:142-146` to `:163` because of unrelated repair work committed the same day.

Both agents ran in separate contexts, neither aware of the other or that a comparison existed.
Neither was told what the checklist was expected to add.

## Consequences for the design

- `CONSOLIDATED-DESIGN.md` ships, but scoped to one pack.
- The router stays deferred, as designed.
- The remaining three packs are NOT admitted on this evidence. `release-it` must earn
  admission at the `design` gate under the same protocol.
- Open question this raises: blueprint's `refactor` is stronger than the pack design assumed.
  The same pre-reboot document that sized the gap also wrongly claimed `refactor` does not
  require tests (it has a hard stop at `refactor/SKILL.md` Phase 1.3). Re-measure before
  assuming a gap for any further pack.

---

## Run A — control, verbatim

# Refactor Plan — `research_harness/runner/backends.py`

Produced by the `refactor` skill (`/home/ak/blueprint/refactor/SKILL.md`), Phase 3, standalone
invocation (no upstream `refactoring-plan` Handoff). Phases 1 and 2 were completed against the
target module and its callers. Execution (Phase 4) was NOT performed.

## 3.1 Refactoring Steps

Target: `/home/ak/research_worker/src/research_harness/runner/backends.py` (86 lines).
Stated pain: **dependency/testability** — the module has no direct test file; `LocalBackend.execute()`
is a single 28-line method that fuses process spawning, timeout escalation, wall-clock reads, host
fingerprinting and hardware probing, with no seam at any of them.

Callers that must keep working unchanged: `/home/ak/research_worker/src/research_harness/runner/__init__.py:1`
(re-exports `BACKENDS`, `LocalBackend`) and `/home/ak/research_worker/src/research_harness/runner/execute.py:30,205-211`
(`BACKENDS[backend]()` then a keyword-only `.execute(...)` call).

---

**Step 1 [RF-TEST-001]: Characterization tests for the module as it stands**
  Before: no test file references `runner/backends.py`. `LocalBackend` is exercised only indirectly,
  through `execute_run`, in `tests/golden/test_demo_slice.py`, `tests/integration/test_run_workflow.py`,
  `tests/integration/test_paper.py`, `tests/integration/test_claims.py`, `tests/integration/test_mlflow.py`,
  `tests/integration/test_contradictions.py`, `tests/leakage/test_leakage.py`, `tests/reproduction/test_reproduce.py`.
  `SlurmBackend`, `DatabricksBackend`, `BACKENDS` and the timeout branch have no coverage at all,
  direct or indirect.
  After: new `/home/ak/research_worker/tests/unit/test_backends.py`, every test labelled
  `# Characterization test — captures existing behaviour, not specification`. No production file is
  touched in this step. Pins:
   - `LocalBackend().name == "local"`; `SlurmBackend().name == "slurm"`; `DatabricksBackend().name == "databricks"`.
   - Success path: run `[sys.executable, "-c", "..."]` writing to both streams; assert `exit_code == 0`,
     `timed_out is False`, stdout/stderr files contain exactly what the child wrote, `wall_time_seconds`
     is a float rounded to 3 dp, `started_at`/`ended_at` match the `now_iso()` format, `host_fingerprint`
     starts with `"sha256:"`, `hardware` has exactly keys `{"cpu","gpu","memory_gb"}` with `gpu == ""`
     and `memory_gb == 0`.
   - Non-zero exit: assert `exit_code` propagates verbatim, `timed_out is False`.
   - Timeout path: a child that sleeps, `timeout_s=1`; assert `timed_out is True` and that the process
     is reaped (negative `exit_code`). Marked `@pytest.mark.slow` — this is the branch that currently
     costs real wall-clock, which Step 4 fixes.
   - `env` isolation: child asserts a key passed in `env` is visible and an unrelated parent key is not.
   - Stubs: `pytest.raises(NotImplementedError)` for both `SlurmBackend` and `DatabricksBackend`,
     matching the message text.
   - Registry: `set(BACKENDS) == {"local","slurm","databricks"}` and each value is the corresponding
     class object.
  Tests: this step *is* the tests. Baseline: full `pytest` green before and after; the new file must
  pass against unmodified source.

**Step 2 [RF-PROTO-001]: Make the backend contract checkable, and make the stubs honour it**
  Before: `ExecutionBackend` is a bare `Protocol` (line 27). Nothing verifies that `LocalBackend`
  satisfies it. `SlurmBackend.execute(self, *a, **k)` and `DatabricksBackend.execute(self, *a, **k)`
  (lines 73, 80) accept any call shape and are untyped — they are structurally incompatible with the
  Protocol and no test could have caught that.
  After: `ExecutionBackend` decorated `@runtime_checkable`. Both stubs get the full typed signature
  copied from the Protocol (`command`, `cwd`, `env`, `stdout`, `stderr`, `timeout_s`, `-> ExecutionResult`),
  body unchanged — still a single `raise NotImplementedError` with the identical message.
  Tests: new conformance test asserting `isinstance(cls(), ExecutionBackend)` for all three classes
  (use `isinstance`, not `issubclass` — `ExecutionBackend` has the non-method member `name`, so
  `issubclass` raises `TypeError`), plus
  `inspect.signature(cls.execute) == inspect.signature(ExecutionBackend.execute)` for all three.
  Step 1's `NotImplementedError` tests must still pass, now called with keywords.

**Step 3 [RF-SEAM-001]: Extract host and hardware probing out of the result constructor**
  Before: `host_fingerprint=sha256_text(platform.node() + platform.platform())` and the `hardware={...}`
  literal are inline arguments to `ExecutionResult(...)` (lines 63-65). Machine-dependent values are
  unreachable except by running a real subprocess.
  After: two module-level functions — `def host_fingerprint() -> str:` returning
  `sha256_text(platform.node() + platform.platform())`, and `def hardware_profile() -> dict:` returning
  `{"cpu": platform.processor() or platform.machine(), "gpu": "", "memory_gb": 0}`. `execute` calls
  them. Expressions moved verbatim; no logic change.
  Tests: direct unit tests — `host_fingerprint()` is deterministic across two calls and prefixed
  `"sha256:"`; `hardware_profile()` falls back to `platform.machine()` when `platform.processor()`
  returns `""` (monkeypatch `backends.platform`). Step 1's assertions on these two `ExecutionResult`
  fields must be unchanged and still pass.

**Step 4 [RF-SEAM-002]: Extract timeout escalation, name the grace period**
  Before: lines 50-57 — a nested `try/except subprocess.TimeoutExpired` inside the outer one, with a
  magic literal `10` as the SIGTERM grace period. Testing this branch requires a real slow child *and*
  ten real seconds to reach the `kill()` path, so the `kill()` path is effectively untestable.
  After: module constant `TERMINATE_GRACE_S = 10` and
  `def _terminate(proc: subprocess.Popen, grace_s: float = TERMINATE_GRACE_S) -> None:` containing
  exactly the existing sequence — `send_signal(signal.SIGTERM)`, `wait(timeout=grace_s)`, on
  `TimeoutExpired` → `kill()`, `wait()`. The `except subprocess.TimeoutExpired:` handler in `execute`
  becomes `timed_out = True; _terminate(proc)`. **The call stays inside the `with open(...)` block**
  so the stdout/stderr file descriptors are still held open until the process is reaped.
  Tests: unit test `_terminate` with a fake proc object (records `send_signal`/`kill` calls, raises
  `TimeoutExpired` on the first `wait`) and `grace_s=0.0` — asserts SIGTERM-then-kill order and that
  the second `wait()` is called. Second test with a fake that exits on the first wait — asserts `kill`
  is never called. Step 1's slow timeout characterization test still passes unmodified.

**Step 5 [RF-SRP-001]: Split `execute` into process handling and result assembly**
  Before: `LocalBackend.execute` is one method doing file opening, spawn, wait, timeout handling, two
  clock reads and `ExecutionResult` construction — more than one level of abstraction, and the only
  way to reach any part of it is to spawn a real process.
  After: `def _run_process(self, command, cwd, env, stdout, stderr, timeout_s) -> tuple[subprocess.Popen, bool]:`
  owns the `with open(...)`/`Popen`/`wait`/`_terminate` block and returns `(proc, timed_out)`.
  `execute` shrinks to: read start time, call `_run_process`, assemble `ExecutionResult` from
  `proc.returncode`, the clocks, `host_fingerprint()`, `hardware_profile()` and `timed_out`. Both
  functions land under 20 lines. Public signature of `execute` is unchanged.
  Tests: result assembly becomes testable without a subprocess — monkeypatch `LocalBackend._run_process`
  to return a stub with a fixed `returncode` and assert the field-by-field mapping into
  `ExecutionResult`, including `timed_out` passthrough. All of Step 1 must pass byte-identically.

**Step 6 [RF-SEAM-003]: Inject the clock into `LocalBackend`**
  Before: `execute` calls the module-global `now_iso()` (line 43) and `time.monotonic()` (lines 44, 62)
  directly. `started_at`, `ended_at` and `wall_time_seconds` are therefore unassertable beyond format
  checks. `time.monotonic` in particular can only be faked by mutating the shared `time` module for the
  whole process, which leaks into every other test running in-process.
  After: `LocalBackend.__init__(self, *, now: Callable[[], str] = now_iso, monotonic: Callable[[], float] = time.monotonic) -> None`
  storing both as instance attributes; `execute` calls `self._now()` and `self._monotonic()`.
  Keyword-only with defaults, so `BACKENDS[backend]()` at `execute.py:205` continues to work with no
  argument. `LocalBackend` stays a plain class (not a dataclass) so the `name = "local"` class attribute
  keeps satisfying the Protocol without `ClassVar` gymnastics.
  Tests: construct `LocalBackend(now=lambda: "2026-01-01T00:00:00.000000Z", monotonic=iter([10.0, 12.5]).__next__)`
  and assert `started_at == ended_at == "2026-01-01T00:00:00.000000Z"` and `wall_time_seconds == 2.5`
  — pinning the `round(..., 3)` behaviour exactly. Default-construction test asserts real timestamps
  still appear.

**Step 7 [RF-TYPE-001]: Tighten the registry annotation**
  Before: `BACKENDS: dict[str, type]` (line 84) — the value type carries no contract, so nothing
  (static or runtime) links the registry to `ExecutionBackend`.
  After: `BACKENDS: dict[str, type[ExecutionBackend]]`. Annotation-only; zero runtime effect. The dict
  contents, key names and `__init__.py` re-export are untouched, and `execute.py:205` is not modified.
  Tests: extend the Step 2 conformance test to iterate `BACKENDS.values()` rather than a hardcoded
  class list, so any future registry entry is contract-checked automatically. `ruff check` clean.

**Step 8 [RF-PARAM-001] — GATED, public interface change, do not execute without explicit approval:**
  Before: `ExecutionBackend.execute` and `LocalBackend.execute` take six parameters, against the ≤3
  rule in the skill's Phase 4.4. Every test must construct six arguments.
  After: an `ExecutionRequest` dataclass (`command`, `cwd`, `env`, `stdout`, `stderr`, `timeout_s`)
  and `execute(self, request: ExecutionRequest) -> ExecutionResult`, with the call site at
  `execute.py:206-211` updated to build one.
  Tests: all prior tests rewritten to build an `ExecutionRequest` fixture.
  **This changes the Protocol signature and the `execute.py` call site — it is a public interface
  change and is excluded from Steps 1-7. Recommendation: defer.** The six-parameter shape is fixed by
  the Protocol and has exactly one call site, so the parameter count costs little; Steps 1-7 deliver
  the stated testability goal without it. Listed here so the deviation from the parameter rule is a
  recorded decision rather than an omission.

**Explicitly out of scope (remaining debt, not fixed here):** `BACKENDS[backend]()` at `execute.py:205`
raises a bare `KeyError` for an unknown backend name, *after* the `Run` entity has already been created
and transitioned to `running` (`execute.py:103-122`). Neither `ExperimentConfig.backend`
(`schemas/config.py:29`), `Run.backend` (`schemas/entities.py:69`), the CLI `--backend` option
(`cli.py:173`) nor the MCP facade (`mcp_facade.py:371`) constrains the value. Converting that to a
`ValidationFailure` raised before run allocation would change observable behaviour and touch a second
module — it belongs in `refactoring-plan`, not in this standalone clean-up.

---

## 3.2 Migration Safety

Baseline for every step: `pytest` over the full `tests/` tree, recorded green before Step 1 begins.
`ruff check src tests` (config at `pyproject.toml`, line-length 100, rules `E4,E7,E9,F,I,W`) after
every step.

**Step 1 [RF-TEST-001]**
- **Rollback**: delete `tests/unit/test_backends.py`. No production file was modified, so rollback is
  total and risk-free.
- **Verification**: `pytest tests/unit/test_backends.py -v` passes against unmodified source. Full
  `pytest` still green. Every test carries the characterization label.
- **Risk**: writing tests that assert *intent* rather than *current reality* — e.g. asserting
  `hardware["memory_gb"]` reports actual memory when the code hard-codes `0`, or asserting a
  `ValueError` for an unknown backend key when the code raises `KeyError`. If a characterization test
  fails on unmodified source, the test is wrong, not the code. Secondary risk: the timeout test is
  genuinely slow and may be flaky on a loaded CI box — mark it `slow` and give the sleeping child ample
  margin over `timeout_s`.

**Step 2 [RF-PROTO-001]**
- **Rollback**: `git revert` the single commit; the change is confined to three signature lines and one
  decorator.
- **Verification**: conformance test passes for all three classes. Step 1's `NotImplementedError` tests
  still pass. `pytest tests/integration/test_run_workflow.py tests/golden/test_demo_slice.py` green —
  these are the suites that reach `execute.py:205`.
- **Risk**: replacing `*a, **k` narrows what the stubs accept. Any caller passing positionally, or
  passing an argument name not in the Protocol, would now raise `TypeError` instead of
  `NotImplementedError`. Verified mitigated: the only call site, `execute.py:206-211`, passes all six
  arguments by keyword, and neither stub is reachable from any test. Second risk: `@runtime_checkable`
  invites `issubclass(LocalBackend, ExecutionBackend)`, which raises `TypeError` because `name` is a
  data member — the test must use `isinstance` on an instance. Third: `isinstance` against a
  runtime-checkable Protocol only checks attribute *presence*, never signatures, which is why the
  `inspect.signature` assertion is a separate, non-redundant check.

**Step 3 [RF-SEAM-001]**
- **Rollback**: inline the two function bodies back into the `ExecutionResult(...)` call. Mechanical,
  no state involved.
- **Verification**: Step 1's assertions on `host_fingerprint` and `hardware` pass unchanged. Both new
  unit tests pass. `pytest tests/golden/test_demo_slice.py` green — the golden slice writes these
  values into a manifest.
- **Risk**: `host_fingerprint` is written into run manifests via `execute.py:245-247`, so any change to
  the concatenation order (`platform.node() + platform.platform()`) or to the `sha256_text` prefix
  silently invalidates historical manifest comparisons. Move the expressions verbatim; do not "tidy"
  them. Also confirm the golden test does not pin an absolute fingerprint value — it is
  machine-dependent and would already be failing if it did.

**Step 4 [RF-SEAM-002]**
- **Rollback**: re-nest the `try/except` inside `execute` and restore the literal `10`.
- **Verification**: both `_terminate` unit tests pass. Step 1's slow timeout characterization test
  passes unmodified — this is the load-bearing check, since the fakes cannot prove the real signal path
  still works.
- **Risk**: **highest-risk step.** Two specific failure modes. (a) If `_terminate` is called from
  *outside* the `with open(stdout,...) as out, open(stderr,...) as err:` block, the file descriptors
  close before the child is reaped, and a child still writing during the SIGTERM grace window gets
  `EPIPE`/`EBADF` — output silently truncated in `stderr.log`, and no existing test would catch it
  because the timeout path is only exercised by one slow test. The call must stay inside the `with`.
  (b) `signal.SIGTERM` and the SIGTERM-then-SIGKILL escalation are POSIX semantics; on Windows
  `send_signal(SIGTERM)` behaves as `terminate()`. That is pre-existing behaviour, unchanged by this
  step, but the fake-proc tests must not assume a real signal was delivered.

**Step 5 [RF-SRP-001]**
- **Rollback**: re-inline `_run_process` into `execute`.
- **Verification**: all of Step 1 passes byte-identically — same `exit_code`, same file contents, same
  `timed_out`. Plus the new stubbed-`_run_process` assembly test. Run the full indirect-coverage set:
  `pytest tests/golden tests/reproduction tests/integration/test_run_workflow.py tests/leakage`.
- **Risk**: `proc.returncode` is currently read *after* the `with` block exits (line 59), which is only
  correct because `proc.wait()` has already completed on every path. Moving the block into
  `_run_process` and returning `proc` preserves that ordering only if `_run_process` returns after the
  `with` closes — verify no early `return` is introduced inside the `with`. Second risk: the clock reads
  (`started`, `t0`) must stay in `execute`, before the `_run_process` call. Pulling `t0` inside
  `_run_process` would exclude the file-open cost from `wall_time_seconds` and shift every recorded
  duration.

**Step 6 [RF-SEAM-003]**
- **Rollback**: remove `__init__`, restore direct `now_iso()` / `time.monotonic()` calls.
- **Verification**: the injected-clock test yields exactly `wall_time_seconds == 2.5` and identical
  `started_at`/`ended_at`. A default-construction test confirms `LocalBackend()` still works with zero
  arguments. `pytest tests/integration/test_run_workflow.py` green — this proves `BACKENDS[backend]()`
  at `execute.py:205` is unaffected.
- **Risk**: the callable defaults must be stored as *instance* attributes in `__init__`
  (`self._now = now`), not left as class attributes — a plain function set as a class attribute becomes
  a bound method on access and would be called with `self` as its first argument, raising `TypeError`.
  Storing on the instance avoids the descriptor protocol entirely. Second risk: making `LocalBackend`
  a `@dataclass` instead would turn `name = "local"` into an `__init__` parameter and change the
  construction contract at `execute.py:205`; keep it a plain class. Third: `time.monotonic` is captured
  as a default at class-definition time, so a test that monkeypatches `backends.time` after import no
  longer affects it — that is the intended improvement, but any Step 1 test relying on such a
  monkeypatch must be updated to use injection.

**Step 7 [RF-TYPE-001]**
- **Rollback**: revert one annotation.
- **Verification**: `ruff check src tests` clean.
  `python -c "from research_harness.runner import BACKENDS, LocalBackend"` succeeds, confirming the
  `__init__.py:1` re-export path is intact. The registry-iterating conformance test passes.
- **Risk**: essentially none at runtime — annotations are not evaluated (`from __future__ import annotations`
  is at line 3). The only exposure is that the tighter type may surface a pre-existing mismatch if any
  type checker is added later; there is no type checker in `pyproject.toml` today, so nothing will fail
  now.

**Step 8 [RF-PARAM-001]**
- **Rollback**: revert both `backends.py` and `execute.py` together; they cannot be reverted
  independently.
- **Verification**: full `pytest` green, with particular attention to
  `tests/integration/test_run_workflow.py`, `tests/reproduction/test_reproduce.py` and
  `tests/golden/test_demo_slice.py`.
- **Risk**: this is a breaking Protocol change with a cross-module blast radius — `backends.py`,
  `execute.py`, and any future third-party backend implementing `ExecutionBackend`. It requires explicit
  acknowledgment at the gate under the behaviour-preservation rule (no public interface change without
  it). **Recommendation: do not execute.** Steps 1-7 achieve the testability objective and leave every
  public signature intact.

---

## Run B — treatment, verbatim

# Refactoring plan — `src/research_harness/runner/backends.py`

Produced by `refactor` (blueprint) Phase 3, standalone invocation (no upstream
`refactoring-plan` Handoff). Not executed. No file in `/home/ak/research_worker`
or `/home/ak/blueprint` was created or modified.

Target: `/home/ak/research_worker/src/research_harness/runner/backends.py` (86 lines).
Callers: `/home/ak/research_worker/src/research_harness/runner/__init__.py:1` (re-export),
`/home/ak/research_worker/src/research_harness/runner/execute.py:30` (import) and `:205` (construction).

---

## 3.1 Refactoring Steps

Scope note carried into the plan: this is one finding (`backends.py` has no test-reachable seams) with a single-call-site consequence in one caller. It does not need cross-finding risk ordering, so it stays in `refactor` Phase 3 rather than routing to `refactoring-plan`. New protocol declarations land in a new private module `src/research_harness/runner/_ports.py` so that `backends.py` keeps its current public surface of six names (`ExecutionResult`, `ExecutionBackend`, `LocalBackend`, `SlurmBackend`, `DatabricksBackend`, `BACKENDS`).

---

### Step 1 [RF-CHAR-001]: Characterization tests through the module-namespace link seam

**Barrier removed:** none. This step crosses the existing barriers using the one seam Python already provides — module-global rebinding in `research_harness.runner.backends`' namespace — so that Steps 2–6 have assertions to preserve. Per skill §1.3, no production code is touched until this exists.

**Seam:** `research_harness.runner.backends` module namespace, specifically the names bound at `backends.py:5` (`platform`), `:6` (`signal`), `:7` (`subprocess`), `:8` (`time`), and `:13` (`now_iso`, `sha256_text`).
**Kind:** both — substitution (fake `subprocess` module returning a recording process) and observation (the recorder's call log).
**Purpose:** separation for `subprocess`/`platform`/`time`/`now_iso`; sensing for the recorder's ordered call log, which no return value exposes.
**Seam lifetime:** TEMPORARY. Retirement condition: each patch target is deleted from the test file at the step that injects the corresponding collaborator — `time`/`now_iso` at Step 3, `platform` at Step 4, `subprocess` at Step 5. `signal` is the exception and is discussed in Remaining debt.

**Test point (traced from the change point, not from the file boundary):**
Change point is `LocalBackend.execute`, `backends.py:39-67`. Four effect paths leave it:

1. return value — the `ExecutionResult` constructed at `backends.py:58-67`;
2. call to a collaborator — `subprocess.Popen(...)` at `:47`, argument capture;
3. call to a collaborator — the escalation sequence `proc.wait(timeout=timeout_s)` `:49`, `proc.send_signal(SIGTERM)` `:52`, `proc.wait(timeout=10)` `:54`, `proc.kill()` `:56`, `proc.wait()` `:57`;
4. output stream — `open(stdout,"w")` / `open(stderr,"w")` at `:46`, which truncate both files even when the child writes nothing.

Paths 1, 3 and 4 all converge on one function returning one object. **Pinch point: the `ExecutionResult` at `backends.py:58-67` plus the recorder's call log.** Both are named as the observation points; neither is "the public API of the module".

**Before → After:**

- Before: `tests/` contains 22 files, none referencing `backends.py`. `LocalBackend.execute` is exercised only transitively through `execute_run` in `tests/golden/test_demo_slice.py:28`, `tests/integration/test_run_workflow.py`, `tests/reproduction/test_reproduce.py:17` and five others — all of which spawn a real Python child process. Those cover only `exit_code == 0` and, at `tests/integration/test_run_workflow.py:70`, `exit_code != 0`. The timeout escalation at `backends.py:50-57` is reached by no test in the repository — `timed_out` appears in zero test files.
- After: new file `tests/unit/test_backends.py`, header comment `# Characterization test — captures existing behaviour, not specification`, containing:
  - `test_popen_receives_command_cwd_env_and_open_file_handles` — asserts path 2.
  - `test_completed_process_returns_exit_code_and_not_timed_out` — asserts path 1 happy case, including `wall_time_seconds` rounded to 3 places against the faked monotonic delta.
  - `test_timeout_escalates_sigterm_then_returns` — first `wait` raises `subprocess.TimeoutExpired`, second `wait` succeeds; asserts call log is exactly `[wait(timeout_s), send_signal(SIGTERM), wait(10)]` and `timed_out is True`.
  - `test_timeout_escalates_sigterm_then_kill` — both `wait` calls raise `TimeoutExpired`; asserts call log is exactly `[wait(timeout_s), send_signal(SIGTERM), wait(10), kill(), wait()]`.
  - `test_exit_code_is_read_after_the_context_manager_closes` — asserts `exit_code` reflects the `returncode` value set by the fake *after* its final `wait`, pinning the current ordering of `backends.py:46-59`.
  - `test_host_fingerprint_and_hardware_are_derived_from_platform` — asserts `host_fingerprint == sha256_text(node + platform_string)` and `hardware == {"cpu": <processor>, "gpu": "", "memory_gb": 0}` against a faked `platform`, pinning the exact expressions at `:63-65` and the `processor() or machine()` fallback at `:64`.
  - `test_streams_are_truncated_even_when_child_writes_nothing` — pre-seeds both files with content, asserts both are empty after; pins path 4.

**Barrier-crossing check (checklist item 7):** these tests spawn no process, open no socket, touch no database, and read no wall clock — `time` and `now_iso` are faked. The only filesystem writes are the two `stdout`/`stderr` paths, which the test supplies from pytest's `tmp_path`. If any of them cannot run under those constraints, the seam is on the wrong side of the barrier and Steps 2–6 must not begin.

**Behaviour:** unchanged — no production file modified.

---

### Step 2 [RF-SEAM-002]: Extract the timeout-escalation policy out of the process-launch body

**Barrier removed:** inline policy with no call boundary. The three escalation outcomes at `backends.py:48-57` sit inside the `with open(...)` block at `:46` and can only be reached by making a real child process ignore SIGTERM. There is no function boundary to call.
**Technique (follows from that barrier):** Extract Method. Not injection — nothing is allocated here that needs replacing; what is missing is a callable boundary.

**Seam:** new module-level function `backends._await_completion(proc: ProcessHandle, timeout_s: int | None) -> bool`, placed above `class LocalBackend` (currently `backends.py:36`). `ProcessHandle` Protocol declared in the new `runner/_ports.py`: attribute `returncode: int | None`; methods `wait(timeout: float | None = ...) -> int`, `send_signal(sig: int) -> None`, `kill() -> None`.
**Kind:** both — substitution (the test passes any object satisfying `ProcessHandle`) and observation (the returned `bool` *is* `timed_out`).
**Purpose:** both. Separation: it replaces the child process, which the test cannot otherwise supply without spawning one. Sensing: `timed_out` is currently a local variable at `backends.py:45` that only reaches a test blended into a seven-field result object; the extracted return value exposes it alone.
**Seam lifetime:** TEMPORARY, private-for-test. `_await_completion` is underscore-prefixed and reached by tests as `backends._await_completion`. Retirement condition: when `SlurmBackend` (`backends.py:70-74`) is implemented and needs the same declared timeout policy (spec §69), promote it to a named `TimeoutPolicy` collaborator injected into both backends and delete the direct-private-call tests. Until that happens the private-call tests stand.

**Test point:** the returned `bool` (all three paths converge on this single return) plus the ordered call log on the fake `ProcessHandle`. The convergence is the reason this boundary was chosen — `escalate-to-SIGTERM`, `escalate-to-kill` and `no-escalation` are three changed paths through one function.

**Before → After:**

- Before: `backends.py:45-57` — `timed_out = False` then the `try/except subprocess.TimeoutExpired` chain nested inside `with open(...)`.
- After: `backends.py` gains `_await_completion`, containing the body of `:48-57` verbatim and returning `timed_out`. `LocalBackend.execute` becomes `timed_out = _await_completion(proc, timeout_s)` as the single statement inside the `with` block after `Popen`. `subprocess.TimeoutExpired` is still the exception caught, so `subprocess` remains imported.

**Tests:** `test_timeout_escalates_sigterm_then_returns` and `test_timeout_escalates_sigterm_then_kill` from Step 1 pass unchanged through `execute`. Add two direct tests against `_await_completion` asserting the same call logs, so the escalation is covered without constructing a backend.

**Behaviour:** unchanged. Same call order, same exception type caught, same value assigned to `timed_out`.

---

### Step 3 [RF-SEAM-003]: Break the ambient-clock dependency

**Barrier removed:** ambient context — clock. `now_iso()` at `backends.py:43` and `:61`; `time.monotonic()` at `:44` and `:62`. Three of the seven `ExecutionResult` fields (`started_at`, `ended_at`, `wall_time_seconds`) are unassertable because the value is read from process-global state.
**Technique (follows from that barrier):** Parameterize Constructor with a production default. A default is mandatory, not stylistic: `execute.py:205` constructs the backend with zero arguments via `BACKENDS[backend]()`, so a required parameter would break the only production call site.

**Seam:** new `LocalBackend.__init__` at `backends.py:36` (immediately after `name = "local"` at `:37`), keyword-only parameter `clock: Clock = _SYSTEM_CLOCK`. `Clock` Protocol in `runner/_ports.py`: `now_iso() -> str`, `monotonic() -> float`. `_SYSTEM_CLOCK` is a module-private singleton in `backends.py` whose two methods are `return now_iso()` and `return time.monotonic()`.
**Kind:** substitution.
**Purpose:** separation — it replaces a collaborator (the system clock) the test cannot otherwise supply.
**Seam lifetime:** PERMANENT. It is production structure with a production default, not a test affordance; nothing retires it.

**Test point:** the `ExecutionResult` at `backends.py:58-67` — specifically `started_at`, `ended_at`, `wall_time_seconds`. Path from change point to observation is the return value. With a scripted clock the test asserts `wall_time_seconds == round(t1 - t0, 3)` exactly, and that `started_at` is sampled *before* `t0` and `ended_at` *after* the `with` block, which is currently unobservable.

**Before → After:**

- Before: `started = now_iso()` `:43`, `t0 = time.monotonic()` `:44`, `ended_at=now_iso()` `:61`, `wall_time_seconds=round(time.monotonic() - t0, 3)` `:62`.
- After: the same four expressions read `self._clock.now_iso()` / `self._clock.monotonic()`. Sampling order at `:43-44` and `:61-62` is preserved exactly — `started` before `t0`, `ended_at` before `wall_time_seconds`.

**Tests:** Step 1's `test_completed_process_returns_exit_code_and_not_timed_out` is rewritten to inject a scripted `Clock` instead of patching `backends.time` and `backends.now_iso`; the two patch targets are deleted from the test file (Step 1 retirement obligation, partially discharged). Add `test_started_at_is_sampled_before_monotonic_baseline`.

**Behaviour:** unchanged when the default is used. `_SYSTEM_CLOCK.now_iso` delegates to the same `now_iso` imported at `backends.py:13`, so timestamp format (`util.py` — UTC, microsecond precision, `Z` suffix) is untouched.

---

### Step 4 [RF-SEAM-004]: Break the ambient-host dependency

**Barrier removed:** ambient context — host identity. `platform.node()`, `platform.platform()` at `backends.py:63`; `platform.processor()`, `platform.machine()` at `:64`. `host_fingerprint` and `hardware` are machine-derived, so a test on any other machine can only assert `host_fingerprint.startswith("sha256:")` — a tautology that does not test the derivation.

This is the same *kind* of barrier as Step 3 (ambient context) and therefore correctly takes the same technique. It is a separate step because the two collaborators have independent failure modes and each step must remain independently safe.

**Technique:** Parameterize Constructor with a production default, for the same call-site reason as Step 3.

**Seam:** `LocalBackend.__init__` at `backends.py:36`, keyword-only parameter `host_probe: HostProbe = _probe_host`. `HostProbe` Protocol and frozen dataclass `HostInfo(fingerprint: str, hardware: dict)` in `runner/_ports.py`; `HostProbe.__call__(self, /) -> HostInfo`. `_probe_host` is a module-private function in `backends.py` holding the expressions from `:63-65` verbatim, including `sha256_text` (imported at `:13`) and the `processor() or machine()` fallback.
**Kind:** substitution.
**Purpose:** separation.
**Seam lifetime:** PERMANENT.

**Test point:** the `ExecutionResult` at `backends.py:58-67` — `host_fingerprint` and `hardware`. Path is the return value. Second observation point: `_probe_host` called directly, which lets `test_host_fingerprint_and_hardware_are_derived_from_platform` assert the concatenation order `node() + platform()` — a detail that a faked `HostProbe` deliberately hides.

**Before → After:**

- Before: `host_fingerprint=sha256_text(platform.node() + platform.platform())` `:63`; `hardware={"cpu": platform.processor() or platform.machine(), "gpu": "", "memory_gb": 0}` `:64-65`.
- After: `host = self._host_probe()` before the return, then `host_fingerprint=host.fingerprint, hardware=host.hardware`. `_probe_host` returns `HostInfo(fingerprint=sha256_text(platform.node() + platform.platform()), hardware={...})` with the dict literal byte-identical.

**Tests:** Step 1's `test_host_fingerprint_and_hardware_are_derived_from_platform` splits in two — one injecting a stub `HostProbe` and asserting the fields reach the result, one calling `_probe_host` with `backends.platform` patched and asserting the exact fingerprint string. The `backends.platform` patch target is then confined to that single test (Step 1 retirement obligation, further discharged).

**Behaviour:** unchanged when the default is used. The produced `host_fingerprint` string and `hardware` dict are byte-identical, which matters because they are written into the finalized manifest at `execute.py:245-246` and hashed by `finalize_manifest` at `execute.py:255`.

---

### Step 5 [RF-SEAM-005]: Break the hidden process allocation

**Barrier removed:** hidden allocation. `subprocess.Popen(command, cwd=cwd, env=env, stdout=out, stderr=err)` is constructed inside the method at `backends.py:47`. No caller can supply the process, so every test of `execute` end-to-end must launch a real one.
**Technique (follows from that barrier):** Parameterize Constructor with a production default of `subprocess.Popen` itself. Extract-and-Override Factory Method was the alternative and is rejected here: it would make the seam subclass-only and therefore temporary, and the repository has no other subclass of `LocalBackend` to justify the inheritance.

**Seam:** `LocalBackend.__init__` at `backends.py:36`, keyword-only parameter `launch: ProcessLauncher = subprocess.Popen`. `ProcessLauncher` Protocol in `runner/_ports.py`, declared with a **positional-only** first parameter so that `subprocess.Popen`'s own parameter name (`args`) does not break structural assignability: `def __call__(self, command: list[str], /, *, cwd: Path, env: dict[str, str], stdout: IO[str], stderr: IO[str]) -> ProcessHandle: ...`.
**Kind:** both — substitution (fake launcher) and observation (the launcher records its arguments, which is the only way to see what `execute` actually passed to the child).
**Purpose:** both. Separation: replaces the child process. Sensing: the argument capture observes `cwd`, `env` and the two open file handles, values that appear in no return value and reach no other observable.
**Seam lifetime:** PERMANENT.

**Test point:** two, both traced. (a) The launcher's captured call arguments — the only path by which `command`, `cwd`, `env` and the file handles are observable. (b) The `ExecutionResult.exit_code` at `backends.py:59`, reading `proc.returncode` *after* the `with` block closes at `:58`; the fake sets `returncode` on its final `wait`, which pins that ordering.

**Before → After:**

- Before: `proc = subprocess.Popen(command, cwd=cwd, env=env, stdout=out, stderr=err)` `:47`.
- After: `proc = self._launch(command, cwd=cwd, env=env, stdout=out, stderr=err)`. `subprocess` remains imported at `:7` — `_await_completion` still catches `subprocess.TimeoutExpired`.

**Tests:** Step 1's `test_popen_receives_command_cwd_env_and_open_file_handles` and `test_streams_are_truncated_even_when_child_writes_nothing` are rewritten to inject a fake `ProcessLauncher` instead of replacing `backends.subprocess`. The `backends.subprocess` patch target is deleted from the test file (Step 1 retirement obligation discharged for `subprocess`). Add `test_backend_is_fully_deterministic_under_injected_collaborators`, which constructs `LocalBackend(clock=…, host_probe=…, launch=…)` and asserts the complete seven-field `ExecutionResult` against an exact expected value.

**Behaviour:** unchanged when the default is used. Note for the gate: `LocalBackend.__init__` now takes three keyword-only parameters, which is exactly at the shared-principles limit of three. A fourth collaborator must be bundled into a dataclass rather than added as a fourth parameter.

---

### Step 6 [RF-SEAM-006]: Open `execute_run` to a supplied backend

**Barrier removed:** two, stacked. (a) Module-level global — `BACKENDS: dict[str, type]` at `backends.py:84-86`. (b) Factory call — `BACKENDS[backend]()` at `execute.py:205`. Together these mean `execute_run` selects and constructs its own backend from a global table; a test can only substitute one by monkeypatching another module's global, which mutates shared state for the whole session.
**Technique (follows from those barriers):** Parameterize Method, not Parameterize Constructor — `execute_run` (`execute.py:49-61`) is a function, so there is no constructor to parameterize.

**Seam:** `execute_run` signature at `execute.py:49-61`, new keyword-only parameter `backend_impl: ExecutionBackend | None = None`; consumed at `execute.py:205`, which becomes `impl = backend_impl if backend_impl is not None else BACKENDS[backend]()`.
**Kind:** substitution.
**Purpose:** separation — replaces the execution backend, which the test cannot otherwise supply without spawning a real Python subprocess through the demo entrypoint.
**Seam lifetime:** PERMANENT. It is the same shape as the existing `backend: str = "local"` parameter at `execute.py:55` and is part of the function's supported surface.

**Test point:** traced from the change point at `execute.py:205-211` forward. `result` has exactly three consumers: the artifact-collection guard at `execute.py:216` (`result.exit_code == 0`), the manifest write at `execute.py:240-248` (six fields), and the status decision at `execute.py:288-294` (`result.timed_out` → `timed_out`, `exit_code == 0` → `succeeded`, else → `failed` with `failure_class="execution_error"`). **Pinch point: `result` itself** — one object through which all three changed paths pass. Observation points are the finalized manifest read back via `load_manifest` and the `Run.status` / `Run.failure_class` returned at `:295`. The `timed_out` → `"timed_out"` branch at `execute.py:288-289` is reached by no test in the repository today; this seam is what makes it reachable.

**Before → After:**

- Before: `backend_impl = BACKENDS[backend]()` `:205`, then `backend_impl.execute(...)` `:206-211`.
- After: as above. Also narrow the annotation `BACKENDS: dict[str, type]` at `backends.py:84` to `dict[str, type[ExecutionBackend]]`, so a future registration is checked against the protocol rather than against bare `type`.

**Tests:** add `tests/integration/test_run_workflow.py::test_timed_out_backend_records_timeout_status`, injecting a stub backend returning `ExecutionResult(timed_out=True, exit_code=-15, …)` and asserting `run.status == "timed_out"`, `run.failure_class == "timeout"`, and `manifest["execution"]["wall_time_seconds"]` round-trips. All eight existing `execute_run` callers in `tests/` pass unchanged — the new parameter defaults to `None`.

**Behaviour:** public interface change, requiring explicit acknowledgment at the gate per the skill's behaviour-preservation clause 2. It is additive and keyword-only with a default, so no existing call site changes. The `BACKENDS` annotation change is erased at runtime; the repository declares no type checker in `pyproject.toml` (`dev = ["pytest>=8", "ruff>=0.4"]`), so it is documentary until one is added.

---

## 3.2 Migration Safety

### Step 1 [RF-CHAR-001] — characterization tests

- **Rollback:** `git rm tests/unit/test_backends.py`. No production file is touched, so rollback cannot regress anything.
- **Verification:** `uv run pytest tests/unit/test_backends.py -q` — all seven pass against unmodified `backends.py`. Then confirm the barrier-crossing constraint holds by inspection of the file: no `socket`, no `subprocess.Popen`, no `sqlite3`/`Ledger`, no `time.sleep`, no `datetime.now`, and every path argument derived from `tmp_path`.
- **Risk:** the fake `subprocess` module is under-specified — if it omits `TimeoutExpired`, the `except` at `backends.py:50` raises `AttributeError` rather than matching, and the escalation tests pass vacuously. Mitigation: the fake re-exports the real `subprocess.TimeoutExpired` rather than defining its own, and each escalation test asserts the exact call log, which cannot be produced by an exception that was never caught.
- **Second risk:** a characterization test asserts an aspiration instead of reality. Mitigation: every assertion in this file must be derivable from the source lines cited in the step; if a test fails on first run, the test is wrong, not the code.

### Step 2 [RF-SEAM-002] — extract `_await_completion`

- **Rollback:** `git revert` the single commit. The extraction is a pure move; no call site outside `LocalBackend.execute` exists.
- **Verification:** `uv run pytest tests/unit/test_backends.py -q` (escalation call logs identical before and after), then `uv run pytest -q` for the whole suite.
- **Risk:** the extracted function is defined outside the `with open(...)` scope at `backends.py:46` and must not accidentally capture `out`/`err`. It takes only `proc` and `timeout_s`; if it needed the file handles the extraction boundary would be wrong.
- **Second risk:** `timed_out` is currently initialised at `:45` *before* the `with` block. After extraction it is assigned inside. If `_await_completion` raises, `timed_out` is unbound — but so was the old code's path, because the exception propagated out of `execute` before reaching `:58` either way. Verified by the fact that `:58` is unreachable on any exception from `:47-57`.

### Step 3 [RF-SEAM-003] — clock injection

- **Rollback:** `git revert`. Reverting also reverts the Step 1 test rewrite in the same commit, so test and production stay consistent.
- **Verification:** `uv run pytest tests/unit/test_backends.py -q`, then `uv run pytest tests/golden/test_demo_slice.py -q` — the golden vertical slice constructs the backend through `BACKENDS[backend]()` at `execute.py:205` with zero arguments and is the direct check that the production default is wired.
- **Risk:** missed call site. `LocalBackend` is referenced in exactly two places outside `backends.py` — `runner/__init__.py:1` (re-export only, never instantiated) and `execute.py:205` (zero-argument construction). Both are covered by keyword-only parameters with defaults. Confirm with `grep -rn "LocalBackend" src/ tests/` after the change; the count must not exceed those two plus the new test file.
- **Second risk:** sampling order silently changes and `wall_time_seconds` shifts. `started_at`/`t0` at `:43-44` and `ended_at`/`wall_time` at `:61-62` must keep their relative order. `test_started_at_is_sampled_before_monotonic_baseline` is the guard.

### Step 4 [RF-SEAM-004] — host-probe injection

- **Rollback:** `git revert`.
- **Verification:** the direct `_probe_host` test asserting the exact fingerprint string with `backends.platform` faked. This is the load-bearing check: `host_fingerprint` and `hardware` are written into the manifest at `execute.py:245-246` and then hashed by `finalize_manifest` at `execute.py:255`, so any change to the derivation changes `manifest_hash` and breaks `verify_manifest`. Then `uv run pytest tests/integration/test_run_workflow.py -q`, which asserts on `manifest_hash` at `:49-52`.
- **Risk:** the `processor() or machine()` fallback at `backends.py:64` is silently dropped during the move. On many Linux hosts `platform.processor()` returns `""`, so dropping the fallback yields `"cpu": ""` and a different manifest on exactly the hosts that matter. The direct test asserts both branches: `processor()` returning a value, and `processor()` returning `""`.
- **Second risk:** `HostInfo.hardware` is a mutable `dict` on a frozen dataclass, so a caller could mutate it after construction. No caller does — `execute.py:246` only reads it into the manifest — but this is why `HostInfo` is frozen rather than a bare tuple.

### Step 5 [RF-SEAM-005] — launcher injection

- **Rollback:** `git revert`.
- **Verification:** `uv run pytest -q` in full. The eight integration and golden tests that call `execute_run` are the real check — they go through the default `subprocess.Popen` path and spawn real children, so if the `ProcessLauncher` call is malformed they fail immediately. Then `test_backend_is_fully_deterministic_under_injected_collaborators` asserting all seven `ExecutionResult` fields exactly.
- **Risk:** implicit dependency on `Popen`'s keyword names. The production default is the real `subprocess.Popen`, and the call at `backends.py:47` passes `cwd`, `env`, `stdout`, `stderr` as keywords with `command` positional. The `ProcessLauncher` protocol must therefore declare `command` positional-only; if it does not, a type checker added later flags a false mismatch against `Popen`'s `args` parameter name.
- **Second risk:** the fake launcher returns a handle that does not truncate the stdout/stderr files, masking the fact that `open(..., "w")` at `backends.py:46` is what creates them. `test_streams_are_truncated_even_when_child_writes_nothing` is retained after the rewrite specifically to keep that effect asserted.

### Step 6 [RF-SEAM-006] — `execute_run` backend parameter

- **Rollback:** `git revert`. The parameter is additive with a `None` default, so reverting cannot orphan a caller.
- **Verification:** `uv run pytest -q` in full, with attention to `tests/golden/test_demo_slice.py` and `tests/reproduction/test_reproduce.py` — the latter re-executes a run and compares outputs, so any change to how the backend is selected shows there. Then the new `test_timed_out_backend_records_timeout_status`, which is the first test in the repository to reach `execute.py:288-289`.
- **Risk:** this is the one step that changes a public signature. `execute_run` is called from `tests/` in eight files and from the CLI. Confirm with `grep -rn "execute_run" src/ tests/` that no call site passes positional arguments past `experiment_id` — the existing signature is already keyword-only after `experiment_id` (`execute.py:51`), so it is structurally safe, but verify rather than assume.
- **Second risk:** `backend_impl` and the existing `backend: str` parameter can disagree — a caller could pass `backend="slurm"` with a local `backend_impl`. The manifest at `execute.py:170` records `backend` (the string), not the implementation, so the manifest would misreport. Accept and document: `backend` remains the recorded label, `backend_impl` overrides only the execution. Do not add a consistency check — that is new behaviour, not refactoring.

### Remaining debt (identified, deliberately not addressed by this plan)

- **`backends.signal` patch target survives Step 1's retirement schedule.** `signal.SIGTERM` at `backends.py:52` is a module-level constant, not an injected collaborator, and `_await_completion` still reads it from the module namespace. Retirement condition: when the containerized-cloud backend from spec §67 lands and needs a non-POSIX termination path, `SIGTERM` becomes a field on a `TimeoutPolicy` object and the patch target is deleted. Until then the fake `ProcessHandle` records whatever integer it receives and the test asserts against `signal.SIGTERM` directly, which is honest but keeps the module-namespace read alive.
- **`_await_completion` is private-for-test.** Carried from Step 2 with the retirement condition stated there: promotion to an injected `TimeoutPolicy` when `SlurmBackend` is implemented.
- **`SlurmBackend.execute` and `DatabricksBackend.execute` accept `(*a, **k)`** (`backends.py:73`, `:80`) and therefore satisfy any signature structurally, so narrowing `BACKENDS` to `dict[str, type[ExecutionBackend]]` in Step 6 does not actually constrain them. Giving them the real signature would change behaviour — `SlurmBackend().execute()` currently raises `NotImplementedError` and would then raise `TypeError` — so it is out of scope for a behaviour-preserving refactor.
- **`host_fingerprint` includes `platform.platform()`** (`backends.py:63`), which embeds the kernel release string. A kernel upgrade changes the fingerprint of the same physical host, so manifests are not comparable across it. Not a testability problem and not fixed here.
- **`hardware` reports `{"gpu": "", "memory_gb": 0}`** as literals (`backends.py:65`). These are placeholders, not measurements. Step 4's `HostProbe` seam is where a real implementation would go, but supplying one is new behaviour.
- **The three keyword-only parameters on `LocalBackend.__init__` sit exactly at the shared-principles limit.** A fourth collaborator must arrive as a bundled dataclass, not a fourth parameter.
