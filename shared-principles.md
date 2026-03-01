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

## Opinionated Defaults

Blueprint prescribes a small Python stack as sensible defaults. These are conventions that reduce decision fatigue at the scaffold stage, not frameworks.

| Convention | Default | Override at gate? |
|------------|---------|-------------------|
| Config modelling | Pydantic BaseModel | Yes — dataclasses acceptable if approved at design gate |
| Interfaces | typing.Protocol | Yes — ABC acceptable if approved at design gate |
| Testing | pytest | No — fixed |
| CLI entry points | click or typer | Yes — argparse acceptable |
| Type hints | Required on all public functions | No — fixed |

Blueprint does NOT prescribe:
- Web frameworks (FastAPI, Django, Flask)
- Infrastructure (Docker, K8s, Terraform)
- Databases or ORMs
- CI/CD tooling
- Package managers beyond "use pyproject.toml"

If a user's project already uses different conventions, the design gate is where this is surfaced and resolved. Scaffold follows whatever the approved design specifies.

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

## Gate Behaviour

Every skill with a checkpoint gate follows this protocol:

### Three Outcomes

1. **Approved** — user says "looks good", "approved", "yes", or equivalent. Proceed to the next phase or hand off to the downstream skill.
2. **Revision requested** — user asks for changes. Revise the output, re-run the Pre-Gate Self-Check, and present again. Do not proceed until approved.
3. **Contract violation** — the Pre-Gate Self-Check fails and cannot be fixed. Stop and report which contract requirement is unmet.

### Rules

- Gates are mandatory. Never skip a gate, even if the user says "just do it" — the gate exists to catch structural errors before they propagate.
- A gate approval covers only the output presented. If you materially change the output after approval, re-present at the gate.
- If the user approves with caveats ("looks good but change X"), apply the change and confirm before proceeding. Do not silently proceed with the caveat unaddressed.

### Refusal Protocol

When the user does not approve at a gate, respond based on what they say:

| User says | Skill should |
|---|---|
| "No, X is wrong" or "Fix X" | Revise the specific section. Re-present ONLY the changed parts, prefixed with: "Revised [section]. Other sections unchanged." |
| "I'm not sure, what about Y?" | Present Y as an alternative. Compare trade-offs with the current approach. Ask the gate question again. |
| "Back up" or "Let me rethink" | Acknowledge. Suggest re-running the upstream skill. Do not attempt to patch the current output. |

This protocol applies to all gated skills. Skills must not invent additional refusal branches.

## Validation

After producing a skill output, optionally run:

    python tools/contract_lint.py <output-file> --skill <skill-name>

This checks contract compliance. Recommended before committing review artifacts
to the reviews/ directory.
