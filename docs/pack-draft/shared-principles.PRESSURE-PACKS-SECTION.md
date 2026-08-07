# D2 — Drop-in section for `shared-principles.md`

## Where it goes

**Insert point:** `shared-principles.md`, between the end of `## Gate Behaviour`
(currently line 135, the sentence "Skills must not invent additional refusal
branches.") and the start of `## Minimum Viable Output` (currently line 137).

The new section becomes lines 137–180; `## Minimum Viable Output` shifts to 182.

**Why here and not inside `Gate Behaviour`.** Gate semantics are near-frozen —
three outcomes, three refusal branches, referenced by every gated skill. The pack
rule will churn as packs are added and cut. Bundling a fast-changing rule inside a
slow-changing section is the rate-of-change smell `architect/SKILL.md:92-104` exists
to catch. Adjacent, not nested.

## One cross-reference to add in `Gate Behaviour`

Append as a fourth bullet under `### Rules`, after line 123 ("If the user approves
with caveats…"):

```markdown
- Before presenting at a gate, check `## Pressure Packs` below. If a pack applies, its
  Final checklist is part of what you verify — and any conflict it declares is reported
  at the gate, never resolved silently.
```

That is the only edit outside the new section. **No `SKILL.md` is modified.**

---

## The section itself — copy from here down

```markdown
## Pressure Packs

A pressure pack is a checklist distilled from one engineering book, held in
`principles/<book-slug>.md`. Packs carry pressure, not policy: they add checks a
skill must satisfy before it presents at its gate. They never add a gate, never
remove one, and never overrule anything above.

### How a pack declares itself

Every pack's YAML frontmatter carries:

| Field | Meaning |
|---|---|
| `pack` | Slug; must equal the filename stem |
| `book` | Title and author |
| `source`, `upstream_rev`, `license` | Provenance. For diagnosis only — nothing syncs |
| `applies_to` | Skill directory names. Each must be a directory containing a `SKILL.md` |
| `when` | The codebase-observable condition that makes the pack apply |
| `conflicts_with` | The section of this file the pack argues with, or `none` |

`applies_to` resolves against the filesystem: `<blueprint-root>/<name>/SKILL.md`
must exist. Not against `README.md`, not against any table.

`when` must be checkable by looking at the code or the design under discussion —
"the module under change has no test file" is a condition; "refactoring" is not,
because it is always true wherever the pack could load.

### When a pack loads

At your gate — the `## Pre-Gate Self-Check` where a skill has one, otherwise the
`**STOP.**` at which the skill presents its output for approval. Read the packs
whose `applies_to` names your skill and whose `when` is true of the work in front
of you. Treat each pack's `## Final checklist` as additional Pre-Gate items.

**At most two packs load per gate.** On three or more matches, report which packs
matched and load the two with the fewest `applies_to` entries; break a tie
alphabetically. The cap is per gate, not per session — a later gate re-evaluates.

### Conflicts are surfaced, never resolved

A pack that declares `conflicts_with` argues with a section of this file. When such
a pack loads, name the conflict at the gate:

> Pack `<slug>` conflicts with `<section>`. `shared-principles.md` governs; the pack
> asks for `<what>`. Proceeding under the shared principle unless you say otherwise.

**This file wins.** Packs are subordinate. The requirement is that the
disagreement is said out loud where the user can overrule it, not that it is
decided in the pack's favour.

### Adding and removing

A pack is admitted only if at least one of its items changes a gate outcome that
the existing skills miss, and the pack cites the upstream line that justifies it.
Anything the skills already enforce is cut and recorded in the pack's
`## Excluded — already covered` block with a `file:line` citation.

Packs go stale. That is accepted: `upstream_rev` records what they were derived
from and nothing reconciles them afterwards. To roll back a pack, delete the file.
```

---

## Notes for the reviewer, not part of the section

**Length.** 47 lines inside the fence — roughly one screen, as asked. It carries the
whole mechanism: schema, resolution, load point, cap, conflict protocol, admission,
rollback.

**One deviation from the brief.** The brief specified the load point as "the
Pre-Gate Self-Check". Only 8 of the 12 skills have one — `refactor`, `scaffold`,
`plan-tracker`, and `navigator` do not, and `refactor` and `scaffold` are both
`WRITES CODE` skills, the two where pack pressure matters most. The section above
says "at your gate" and names both forms. This costs nothing and preserves the
zero-`SKILL.md`-edits property. See `CONSOLIDATED-DESIGN.md` § Pushback.

**What the section deliberately does not say.** Nothing about a router file, nothing
about generation-time loading, and no `Packs applied:` output field. All three are
deferred; the last one is refused outright because it would require editing every
skill's Handoff contract.
