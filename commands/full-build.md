Full architecture-first build with iteration loops. $ARGUMENTS

Run the complete W1 build chain with validation at each phase and
targeted backtrack when gaps are found.

## PHASE 1 — IDEATE

Explore 2-3 structural approaches. For each approach:
- Core abstraction / mental model
- Stress-test: what breaks under load, edge cases, scale?
- Trade-offs: what do you gain, what do you give up?

Produce:
- **Decision Summary**: which approach and why
- **Constraints Identified**: hard requirements that constrain architect

Gate: I approve the chosen approach before proceeding.

## PHASE 2 — ARCHITECT

Decompose into modules using rate-of-change heuristics:
- Things that change together → same module
- Things that change at different rates → separate modules
- External dependencies → boundary modules

Produce:
- **Domain Model**: core entities and relationships
- **Decomposition Table**: module | responsibility | rate-of-change | dependencies
- **DAG Check**: verify no circular dependencies

Validation:
- IF circular dependency detected → STOP
  → Identify the cycle
  → Propose boundary adjustment
  → Return to IDEATE with specific constraint, OR
  → Resolve here with architect decision + justification

Gate: I approve the decomposition before proceeding.

## PHASE 3 — DESIGN

Wire components together:
- Define protocols/interfaces between modules
- Specify data flow direction
- Propose file structure

Produce:
- **Protocol Definitions**: interface signatures
- **File Structure**: directory tree with purpose annotations
- **Wiring Diagram**: which module calls which (Mermaid DAG)

Validation:
- IF a protocol cannot be satisfied by proposed modules → STOP
  → Identify the unsatisfiable requirement
  → Return to ARCHITECT with specific boundary question

Gate: I approve the design before proceeding.

## PHASE 4 — SCAFFOLD

Generate all files:
- Stub implementations with TODO bodies
- Type hints on all signatures
- Smoke test that imports succeed

Validation:
- Run: `python -c "import <package>"`
- IF import fails or type error → STOP
  → Identify the gap (missing module, circular import, type mismatch)
  → Return to ARCHITECT for boundary fix
  → Then DESIGN for rewiring
  → Then SCAFFOLD again

Gate: I confirm scaffold is complete and imports cleanly.

## ITERATION PROTOCOL

When backtracking:
1. State the SPECIFIC issue that triggered backtrack
2. State which phase you're returning to
3. State what question needs answering
4. Do NOT restart the phase from scratch — address only the gap
5. Carry forward all prior decisions that aren't affected

Example:
```
BACKTRACK: scaffold → architect
ISSUE: circular import between auth and users modules
QUESTION: should User own auth state, or should Auth own user reference?
PRIOR DECISIONS PRESERVED: domain model entities, all other module boundaries
```

## OUTPUT ARTIFACTS

By end of successful run:
- `docs/plans/<date>-<name>-ideate.md` — decision summary
- `docs/plans/<date>-<name>-architect.md` — domain model + decomposition table
- `docs/plans/<date>-<name>-design.md` — protocols + file structure
- Generated source files with TODO stubs
