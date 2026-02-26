# Shared Engineering Principles

These principles are referenced by all skills in the family. They represent the structural
discipline that every piece of code — whether ideated, designed, refactored, or scaffolded —
must respect.

## Clean Code Principles

### Single Responsibility (SRP)
Every module, class, and function should have exactly one reason to change. The litmus test:
can you describe what it does in one sentence without using "and"? If not, split it.

### Open/Closed
Design for extension without modification. Prefer composition and protocols over inheritance
hierarchies. When you find yourself adding `if isinstance(...)` branches, you probably need
a protocol or strategy pattern instead.

### Dependency Inversion
High-level modules (strategy logic, orchestration) must not depend on low-level modules
(file I/O, API calls). Both should depend on abstractions (protocols/interfaces). This is
the single most important principle for maintainability — it's what allows you to swap data
sources, execution backends, or output formats without rewriting business logic.

### Interface Segregation
Don't force consumers to depend on methods they don't use. Prefer narrow, focused protocols
over fat interfaces. A `SignalGenerator` protocol with one method is better than a `Strategy`
protocol with ten.

## DRY — But With Nuance

DRY ("Don't Repeat Yourself") is often misapplied. The principle is about **knowledge
duplication**, not code duplication. Two pieces of code that look identical but represent
different domain concepts should NOT be merged — they'll diverge as requirements evolve,
and the premature abstraction becomes a coupling point.

### When to DRY
- Same business rule expressed in multiple places → extract
- Same data transformation applied identically in 3+ locations → extract
- Same config/constants duplicated → centralise

### When NOT to DRY
- Two similar-looking functions that serve different domain purposes → leave separate
- Boilerplate that is *structurally* similar but *semantically* distinct → use templates/scaffolding, not shared base classes
- "Just in case" abstractions for code that's only used once → wait until the third use

### The Rule of Three
Don't abstract on the second occurrence. Abstract on the third. By then you have enough
examples to know what the *actual* common pattern is, rather than guessing from two data points.

## Fail Fast

Throw errors when preconditions aren't met — don't silently continue with bad state. A loud
failure at the point of origin is infinitely easier to debug than a quiet corruption that
surfaces three layers later.

- Validate inputs at function boundaries, not deep inside implementation
- Use assertions for invariants that should never be violated
- Prefer explicit exceptions over returning sentinel values (`None`, `-1`, empty DataFrame)
- Let errors propagate to the appropriate handler — don't catch and swallow

```python
# Good: fail immediately with a clear message
def compute_spread(price: float, par: float) -> float:
    if price <= 0:
        raise ValueError(f"Price must be positive, got {price}")
    ...

# Bad: silently returns garbage
def compute_spread(price: float, par: float) -> float:
    if price <= 0:
        return 0.0  # caller has no idea this is invalid
    ...
```

## Fix Root Causes

Address the underlying issue, not the symptom. If a function produces wrong output for
certain inputs, the fix is in the function's logic — not a filter on its output. If a module
is hard to test, the problem is the module's dependencies — not a more elaborate test harness.

Signs you're treating a symptom:
- Adding a special case (`if x == weird_value: ...`) instead of fixing why `x` is weird
- Wrapping a function in try/except to hide its failures
- Adding a "cleanup" step after a process that shouldn't produce mess in the first place
- Patching output instead of correcting the transformation

## Extensibility Checklist

Before considering any piece of work "done", verify:

1. **Can a new variant be added without modifying existing code?** (e.g., new strategy type, new data source, new output format)
2. **Are configuration and behaviour separated?** (config in YAML/JSON, behaviour in code)
3. **Are the module boundaries tested?** (integration tests at interfaces, unit tests for logic)
4. **Is the dependency graph a DAG?** (no circular imports, clear layering)
5. **Could someone unfamiliar with the codebase understand the structure from the directory layout alone?**

## Python Conventions

These are the user's established patterns — respect them in all generated code:

- **Type hints**: Always. Use `typing.Protocol` for interfaces.
- **Data models**: `dataclasses` for internal structures, `Pydantic` for external boundaries (config, API contracts, serialisation).
- **CLI**: `click` or `typer` for command-line interfaces.
- **Data formats**: Parquet for intermediate/analytical data, JSON for configuration.
- **Project layout**:
  ```
  project/
  ├── src/
  │   └── package_name/
  │       ├── __init__.py
  │       ├── core/        # Domain logic, protocols, core abstractions
  │       ├── data/         # Data ingestion, transformation, I/O
  │       ├── strategy/     # Strategy-specific logic (if applicable)
  │       └── execution/    # Orchestration, CLI entry points, output
  ├── tests/
  │   ├── unit/
  │   └── integration/
  ├── config/
  │   └── default.yaml
  └── pyproject.toml
  ```
- **Testing**: `pytest`, with fixtures for shared setup. Property-based testing (`hypothesis`) for numerical code where edge cases matter.
- **Logging**: `logging` module with structured output. No print statements in library code.
