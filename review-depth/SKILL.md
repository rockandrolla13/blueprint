---
name: review-depth
description: >
  Review Python code for deep module design and progressive disclosure. Scores modules
  on interface-to-implementation ratio, cognitive load at each navigation level, and
  information hiding. Use this skill whenever the user says "simplify", "too complex",
  "hard to navigate", "cognitive load", "clean up interfaces", "deep modules",
  "progressive disclosure", "make it easier to understand", "reduce complexity",
  "hard to find things", or wants to enforce Ousterhout-style deep module principles.
  Do NOT trigger for general code review (use code-review), architecture scoring
  (use review-architecture), or refactoring execution (use refactor).
---

# Review: Deep Modules & Progressive Disclosure

## Purpose

Score a codebase on two related principles:

1. **Deep Modules** (Ousterhout): Each module should hide significant complexity
   behind a small interface. The ratio of implementation complexity to interface
   surface area should be high. Shallow modules — thin wrappers, pass-through
   functions, classes with more public methods than private ones — are the enemy.

2. **Progressive Disclosure**: A reader navigating the codebase should encounter
   information in layers. The top level shows *what* is available. One level down
   shows *how* to use it. Two levels down shows *how it works*. A new user should
   be productive after reading only level 1.

## When to Run

- Before extending a codebase (pre-W4) — ensures new modules follow the pattern
- After refactoring (post-W2) — verifies the refactor actually reduced complexity
- On any codebase the user describes as "hard to navigate" or "too complex"
- As a complement to review-architecture (which scores boundaries; this scores depth)

## Phase 1: Module Census

For every Python module (directory with `__init__.py`) and significant standalone file:

### 1.1 Measure Interface Surface Area

Count the **public interface** — everything a consumer sees:

- Public functions (no `_` prefix)
- Public classes
- Public methods per class (no `_` prefix)
- Public constants / module-level variables
- Re-exports in `__init__.py`
- Required parameters across all public functions

Record as: `interface_size = public_functions + public_classes + sum(public_methods) + public_constants`

### 1.2 Measure Implementation Depth

Count the **hidden complexity** — everything the module does internally:

- Private functions and methods (`_` prefix)
- Lines of actual logic (excluding imports, blank lines, docstrings)
- Internal data structures
- Error handling paths
- Conditional branches

Record as: `impl_depth = private_functions + logic_lines + internal_structures`

### 1.3 Compute Depth Ratio

`depth_ratio = impl_depth / interface_size`

| Depth Ratio | Rating | Meaning |
|---|---|---|
| > 10 | 🟢 Deep | Good — significant complexity hidden behind small interface |
| 5–10 | 🟡 Moderate | Acceptable — could be deeper |
| 2–5 | 🟠 Shallow | Problem — interface is almost as complex as implementation |
| < 2 | 🔴 Wrapper | Likely a pass-through that adds no value |

### 1.4 Flag Shallow Module Patterns

Look for these specific anti-patterns:

- **Pass-through functions**: Function that only calls one other function with the
  same or similar arguments
- **Wrapper classes**: Class whose methods each delegate to a single method of
  another class
- **Config-as-interface**: Module whose public API is mostly configuration dataclasses
  with no behaviour
- **Leaky abstractions**: Public function that returns internal types, requires
  knowledge of implementation details, or exposes implementation-specific parameters
- **`__init__.py` that re-exports everything**: Defeats progressive disclosure by
  flattening the module hierarchy

## Phase 2: Progressive Disclosure Audit

### 2.1 Navigation Levels

Map the codebase into disclosure layers:

**Level 0 — Package root** (`__init__.py` or top-level imports):
- What can a new user discover by reading ONLY the top-level `__init__.py`?
- Is there a clear "start here" path?
- Score: Can someone understand what this package does in < 30 seconds?

**Level 1 — Module interfaces** (public functions/classes of each submodule):
- Do function names and signatures tell you what they do without reading source?
- Are there docstrings on all public functions?
- Do type hints describe the contract?
- Score: Can someone USE this module by reading only signatures + docstrings?

**Level 2 — Implementation** (function bodies, private methods):
- Is this the first level where algorithmic detail appears?
- Or does implementation detail leak into Level 0/1?

### 2.2 Disclosure Violations

Flag these patterns:

- **Premature detail**: Implementation details visible at Level 0 or 1
  (e.g., algorithm parameters in function signatures that only make sense
  if you know the algorithm)
- **Missing signposts**: No docstrings, no `__all__`, no obvious entry point
- **Flat hierarchy**: Everything at one level — no nesting, user must read
  everything to find anything
- **Deep nesting without purpose**: 5+ levels of directories with only 1-2
  files each — creates navigation overhead without information hiding
- **Inconsistent depth**: Some modules deeply nested, others flat, with
  no discernible pattern

### 2.3 `__init__.py` Audit

For each package `__init__.py`:

| Pattern | Rating | Why |
|---|---|---|
| Curated `__all__` with 3-7 key exports | 🟢 | Clear entry point |
| Empty (relies on submodule imports) | 🟡 | Acceptable but no guidance |
| Re-exports everything from all submodules | 🔴 | Defeats progressive disclosure |
| Contains significant logic | 🔴 | Wrong place for implementation |
| Imports that trigger heavy side effects | 🔴 | Surprises at import time |

## Phase 3: Cognitive Load Scoring

### 3.1 Per-Module Cognitive Load

For each module, estimate cognitive load by counting:

- **Names to remember**: public symbols exported
- **Concepts to understand**: distinct abstractions (each class/protocol is one concept)
- **Decisions to make**: parameters with non-obvious defaults, mode flags,
  string-typed enums
- **Files to open**: how many files must you read to complete a typical task

`cognitive_load = names + concepts + (decisions * 2) + (files_to_open * 3)`

The multipliers reflect that decisions and file-hopping are disproportionately expensive.

| Score | Rating |
|---|---|
| < 10 | 🟢 Low — easy to work with |
| 10-20 | 🟡 Moderate — manageable |
| 20-30 | 🟠 High — needs simplification |
| > 30 | 🔴 Overwhelming — restructure |

### 3.2 Cross-Module Cognitive Load

For a typical user task (e.g., "add a new strategy", "run an analysis"):

- How many modules must the user touch?
- How many files must they read?
- How many interfaces must they understand?
- Are there implicit ordering dependencies? (must call A before B, not enforced by types)

## Phase 4: Findings

### 4.1 Finding ID Format

Every finding uses: `DM-<TYPE>-<NNN>`

TYPE is one of:
- `SHAL` — Shallow module (low depth ratio)
- `LEAK` — Leaky abstraction
- `FLAT` — Flat hierarchy / poor progressive disclosure
- `COGN` — High cognitive load
- `INIT` — `__init__.py` problem
- `PASS` — Pass-through / wrapper adding no value
- `SIGN` — Missing signposts (docstrings, `__all__`, type hints)

### 4.2 Output Format

For each finding:

```markdown
### DM-SHAL-001: fetchers module is shallow
**Rating:** 🔴 **Type:** Shallow Module **Location:** fetchers/
**Depth ratio:** 1.8 (interface: 12 symbols, implementation: 22 functions)
**Problem:** 8 of 12 public functions are one-line delegations to internal HTTP calls.
**Fix direction:** Collapse into 2-3 public functions that handle fetching by source type.
Hide the per-endpoint functions as private methods.
```

## Phase 5: Scorecard + Recommendations

### 5.1 Scorecard

| Dimension | Score | Key Finding |
|---|---|---|
| Module Depth | 🟢/🟡/🟠/🔴 | Shallowest module and its ratio |
| Progressive Disclosure | 🟢/🟡/🟠/🔴 | Can a new user navigate in < 30 seconds? |
| Cognitive Load | 🟢/🟡/🟠/🔴 | Highest-load module and its score |
| `__init__.py` Hygiene | 🟢/🟡/🟠/🔴 | Worst `__init__.py` pattern found |
| Signposting | 🟢/🟡/🟠/🔴 | % of public functions with docstrings + type hints |

### 5.2 Recommendations

For each 🔴 or 🟠 dimension, provide:

- **What to fix** (specific modules/files)
- **Fix direction** — one of:
  - "Merge shallow modules" — combine pass-throughs into their targets
  - "Deepen interface" — hide parameters behind sensible defaults
  - "Add disclosure layer" — create a curated `__init__.py` or facade
  - "Split god module" — extract coherent subsets behind narrower interfaces
  - "Add signposts" — docstrings, `__all__`, type hints
- **Do NOT provide code changes** — this is a diagnostic skill

## Pre-Gate Self-Check

Before presenting findings, verify:
1. [ ] Every module in the codebase has a depth ratio calculated
2. [ ] Every finding has a DM-*-NNN ID
3. [ ] Scorecard covers all 5 dimensions
4. [ ] No code changes proposed (diagnostic only)
5. [ ] `## Handoff` section exists with all MUST fields

## Contract (BCS-1.0)

### Mode
READ-ONLY

### Consumes
- Python project directory and source files
- No structured upstream Handoff required

### Produces
MUST emit a `## Handoff` section at the end of output containing:
- Scorecard table: Dimension | Score | Key Finding (5 rows)
- Module census table: Module | Interface Size | Impl Depth | Depth Ratio | Rating
- Findings with DM-*-NNN IDs, each with: Rating, Type, Location, Problem, Fix direction
OPTIONAL inside Handoff:
- Navigation map showing disclosure levels
FORBIDDEN inside Handoff:
- Code changes or patches
- Positive highlights (keep in report body only)

### Degrees of Freedom
- Scorecard uses 🟢🟡🟠🔴
- Finding types use exact vocabulary: SHAL, LEAK, FLAT, COGN, INIT, PASS, SIGN
- Location: path/to/module/ or path/to/file.py

### Downstream Consumers
- refactoring-plan (reads Handoff, merges with code-review and review-architecture findings)
- architect (reads Handoff in W3 Redesign to inform module restructuring)
