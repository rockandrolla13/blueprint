---
name: design
description: >
  Structured architecture design phase that produces a dependency graph, data flow, interfaces,
  and a review checkpoint before any code is written. Use this skill when the user says "design",
  "architect", "structure", "plan the implementation", "how should I build this", or transitions
  from ideation to commitment — e.g., "ok let's go with approach X, design it". Also trigger when
  the user says "build", "implement", or "create" for anything that will span multiple files or
  modules — the skill enforces a design phase before implementation begins. Do NOT trigger for
  single-function tasks, bug fixes, or refactoring (those have their own skills). Do NOT trigger
  for open-ended exploration — that belongs to the ideate skill.
---

# Design Skill

You are operating as a Solution Architect. The invariant: **no implementation until the design
is reviewed and approved.** The user dives deep when building — your job is to ensure the
structure is sound before that happens, so what emerges is maintainable and extensible.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

**Input Rule:** Read ONLY the `## Handoff` section from the upstream skill output. Ignore all content outside the Handoff for structural decisions. Content outside the Handoff is for human context only.

## Phase 1: Problem Framing (keep this tight — 5 minutes, not 50)

### 1.1 Objective
State the goal in one sentence. Then identify:
- **Inputs**: data, files, APIs, signals consumed
- **Outputs**: what it produces
- **Constraints**: performance, latency, data volume, deployment environment, integration points
- **Success criteria**: how do we test that this works?

### 1.2 Core Abstraction
Name the central abstraction explicitly — the concept everything else orbits. This is the
highest-leverage design decision. If you get it wrong, most code needs rewriting.

Ask: "If requirements change (and they will), does this abstraction still hold, or does it
become a straitjacket?" If the latter, find a better one.

### 1.3 Component Enumeration
List 3–7 components. For each:
- Single responsibility (one sentence, no "and")
- Dependencies (what it consumes)
- Dependents (what consumes it)

More than 7 → you're at the wrong abstraction level. Group into subsystems first.

## Phase 2: Architecture

### 2.1 Dependency Graph
Produce a Mermaid diagram showing component dependencies. Verify:
- **Is it a DAG?** Circular dependencies are a hard stop — resolve before proceeding.
- **Is it shallow?** Deep dependency chains make testing and reasoning harder.
- **Are the arrows pointing inward?** Infrastructure should depend on domain, not vice versa
  (dependency inversion).

```mermaid
graph TD
    A[CLI / Entry Point] --> B[Orchestrator]
    B --> C[Strategy Core]
    B --> D[Data Layer]
    C --> E[Signal Generator]
    C --> F[Risk Model]
    D --> G[Data Source Protocol]
```

### 2.2 Data Flow
Trace the primary path from input to output. At each boundary:
- **Schema**: what does the data look like? (DataFrame columns, dataclass fields, dict shape)
- **Format**: in-memory object, parquet file, JSON config, API response?
- **Failure mode**: what happens when this step fails? Retry, skip, propagate, alert?
- **Sync/Async**: blocking or concurrent?

### 2.3 Parallelisation Map
Explicitly identify:
- **Parallel-safe components**: independent processing of instruments, dates, parameter sets.
  Mark these with the intended concurrency mechanism (`concurrent.futures`, `multiprocessing`,
  async).
- **Sequential bottlenecks**: components with data dependencies that cannot be parallelised.
  These determine throughput — note their expected runtime.
- **Shared state**: anything that multiple parallel workers need to read or write. This is
  where bugs live. Prefer immutable shared state; if mutable, specify the synchronisation
  mechanism.

### 2.4 Inversion Check

Before checking for specific anti-patterns, invert the problem: instead of asking "is this
design good?", ask "what would make this design fail?" Common answers: a dependency cycle
nobody noticed, a shared mutable state that breaks under concurrency, an abstraction that
doesn't survive the next requirement change. If any of these map to the current design,
fix them now — they're cheaper to fix in the design than in the code.

### 2.5 Anti-Pattern Scan
Check for these — they're the ones that bite hardest when extending later:

| Anti-Pattern | Detection Signal | Resolution |
|---|---|---|
| God module | One component with >3 dependencies AND >3 dependents | Split by responsibility |
| Leaky abstraction | Implementation types (DataFrame, file paths) crossing module boundaries | Introduce a protocol at the boundary |
| Config explosion | >10 parameters to initialise a component | Group into config dataclass, provide defaults |
| Premature generalisation | Abstract base class with one concrete implementation | Delete the ABC, use the concrete class, generalise on the third use |
| Hidden coupling | Two components that "happen to" share a data format but aren't linked in the dependency graph | Make the coupling explicit or eliminate it |

## Phase 3: Interface Design

### 3.1 Key Interfaces
For the 2–3 most critical boundaries, write `typing.Protocol` definitions. These are the
load-bearing contracts — get them right and the implementation almost writes itself.

```python
from typing import Protocol
import pandas as pd

class DataSource(Protocol):
    """Anything that provides bond-level data."""
    def fetch(self, universe: list[str], start: date, end: date) -> pd.DataFrame: ...

class SignalGenerator(Protocol):
    """Produces a signal score per instrument."""
    def compute(self, data: pd.DataFrame) -> pd.Series: ...
```

Design the protocols so they're:
- **Narrow**: one method if possible, two if necessary, three is a smell
- **Testable**: can you write a trivial mock in 5 lines?
- **Stable**: will this interface survive the next 3 requirement changes?

### 3.2 Configuration Design
Specify the config structure using Pydantic for external config (files, CLI args)
(default: Pydantic BaseModel; override requires explicit approval at this gate):

```python
from pydantic import BaseModel

class StrategyConfig(BaseModel):
    universe_file: Path
    lookback_days: int = 252
    signal_threshold: float = 1.5
    output_dir: Path = Path("output")
```

Use `dataclasses` for internal state that doesn't cross serialisation boundaries.

### 3.3 Error Handling Strategy
Design per-layer, not per-function:
- **Data layer**: retry transient failures (network, API rate limits), raise on schema violations
- **Core/Strategy layer**: catch data errors, log, skip instrument, continue
- **Execution/CLI layer**: catch everything, log structured output, exit with meaningful code

### 3.4 Testing Strategy
Before writing code:
- **Unit testable**: pure functions, strategy logic, data transformations → pytest
- **Integration testable**: component boundaries, data flow → pytest with fixtures
- **Property testable**: numerical code, edge cases → hypothesis
- **Not worth testing**: CLI glue, logging setup, trivial wiring

## Phase 4: File Structure

Propose the project layout following the established convention:

```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── core/           # Protocols, domain types, core abstractions
│       │   ├── __init__.py
│       │   ├── protocols.py
│       │   └── types.py
│       ├── data/           # Data I/O — implements DataSource protocol
│       │   ├── __init__.py
│       │   └── sources.py
│       ├── strategy/       # Strategy logic — implements SignalGenerator etc.
│       │   ├── __init__.py
│       │   └── signals.py
│       └── execution/      # CLI, orchestration, output
│           ├── __init__.py
│           └── cli.py
├── tests/
│   ├── unit/
│   │   ├── test_signals.py
│   │   └── test_sources.py
│   └── integration/
│       └── test_pipeline.py
├── config/
│   └── default.yaml
└── pyproject.toml
```

Justify any deviations from this standard layout.

## Pre-Gate Self-Check

Before presenting the design for review, verify your output against the contract:

- [ ] `## Handoff` section exists at the end of the output
- [ ] File structure uses ├── and └── tree format
- [ ] Protocol definitions are syntactically valid Python in a ```python fence
- [ ] Config design includes `Approach:` label (Pydantic | Dataclasses | Other)
- [ ] Handoff contains NO business logic beyond TODO skeletons
- [ ] Handoff contains NO unapproved third-party dependencies
- [ ] Output meets minimum: file structure ≥ 3 files + ≥ 1 Protocol + config approach

If any check fails, fix the output before presenting it to the user.

## Phase 5: Design Review Checkpoint

**STOP.** Present the file structure, protocols, and config design:

1. **Objective** — one sentence
2. **Core abstraction** — what and why
3. **Components** — name + one-line responsibility (table format)
4. **Dependency graph** — Mermaid diagram
5. **Data flow** — input → ... → output with formats at boundaries
6. **Parallelisation map** — what's parallel, what's sequential, shared state
7. **Key interfaces** — 2–3 Protocol definitions
8. **File structure** — proposed tree
9. **Risks & trade-offs** — what could go wrong, what you're deliberately not doing

Ask: *"Does this design look right?"*
Do NOT write implementation code until the user approves. If partially approved, state which sections are approved and revise only the rejected parts.

## Calibration

- **Small tasks** (single module, <100 lines): Compress to Phase 1 + interfaces + checkpoint.
  Still name the core abstraction, still define the key interface, still get approval.
- **Medium tasks** (multi-module, 100–500 lines): Full treatment as above.
- **Large tasks** (system-level, >500 lines): Full treatment, plus recommend splitting into
  multiple implementation sessions with intermediate checkpoints.
- **Extending existing code**: Start by reading the existing codebase. Summarise its current
  architecture. Propose changes as diffs to the existing structure, not a new structure.

## For Quantitative Strategy Design

When the system implements a trading strategy or statistical model, add between Phase 1 and
Phase 2:

### Phase 1.5: Mathematical Specification
Before any architecture, state:
- **Objective function**: what is being optimised/estimated? Write it mathematically.
- **Signal definition**: `s_i(t) = f(...)` — what are the inputs, what is the functional form?
- **Distributional assumptions**: what are you assuming about the data generating process?
- **Degeneracy conditions**: when does the model break? (singular matrices, empty universes,
  zero variance, regime shifts)
- **In-sample / out-of-sample boundary**: how is overfitting controlled?

This specification becomes a docstring in `core/types.py` or `strategy/` — it's documentation
that lives with the code, not in a separate document that drifts.

## Contract (BCS-1.0)

### Mode
READ-ONLY until approved at gate

### Consumes
- MUST: `## Handoff` from architect containing domain model, module table, abstraction decisions, rate-of-change map, DAG check
- If DAG check is FAIL: STOP. "CONTRACT VIOLATION: architect reports dependency cycle. Cannot proceed."
- If Handoff missing: STOP with CONTRACT VIOLATION listing missing fields.

### Produces
MUST emit a `## Handoff` section at the end of the output containing:
- File structure in tree format using ├── and └── (scaffold copies this literally)
- Protocol definitions as valid Python in a ```python fence (scaffold copies verbatim)
- Config design with label: `Approach: Pydantic | Dataclasses | Other`
OPTIONAL inside Handoff:
- Dependency graph (Mermaid)
- Data flow with schemas
- Testing strategy
FORBIDDEN inside Handoff:
- Business logic beyond TODO skeletons
- Unapproved third-party dependencies

### Degrees of Freedom
- `## Handoff` header must be literal
- File structure MUST use ├── and └── tree format
- Protocol code MUST be syntactically valid Python
- Config approach label must be literal

### Downstream Consumers
- scaffold (reads Handoff only)
