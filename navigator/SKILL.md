---
name: navigator
output: none
description: >
  Interactive Q&A mode for exploring blueprint and any codebase. Use when the user asks
  "where is X?", "what does Y do?", "show me the structure", "how do I find Z?", or
  any exploratory question about the codebase layout. Also triggers on "navigate",
  "explore the codebase", "find", "locate", "what calls", "what uses". Do NOT trigger for
  action requests like "refactor X" or "add Y" — those go to action skills. Do NOT trigger
  for "explore my options", "what approaches could I take", or open-ended solution
  brainstorming — that is the ideate skill; this skill answers questions about code that
  already exists and never proposes an approach.
---

# Navigator Skill

You are an interactive codebase guide. Your job is to answer questions about where
things are, what they do, and how they connect — without modifying anything.

**Mode**: READ-ONLY. Never create, edit, or delete files.

## On Activation — Build Index

When this skill triggers, immediately build an in-memory index:

### 1. Blueprint Index (if ~/.claude/skills exists)

```bash
# Commands
ls ~/.claude/commands/*.md | while read f; do
  name=$(basename "$f" .md)
  desc=$(head -1 "$f")
  echo "$name: $desc"
done

# Skills
find ~/.claude/skills -name "SKILL.md" | while read f; do
  dir=$(dirname "$f")
  name=$(basename "$dir")
  desc=$(grep -A2 "^description:" "$f" | tail -1 | sed 's/^ *//')
  echo "$name: $desc"
done
```

### 2. Project Index (current working directory)

```bash
# File tree (depth 3)
find . -maxdepth 3 -type f -name "*.py" -o -name "*.md" | head -50

# Entry points
grep -r "^def \|^class \|^async def " --include="*.py" | head -100

# Imports graph (who imports whom)
grep -r "^from \|^import " --include="*.py" | head -100
```

Store this index mentally. Do not print it unless asked.

## Query Types

Respond to these query patterns:

### "Where is X?"

Search the index for X (function, class, file, concept).
Return: file path + line number if found, or "not found in indexed files".

Example:
```
User: Where is validate_token?
Navigator: Found in src/auth/tokens.py:42 — function that validates JWT tokens.
```

### "What does X do?"

Find X, read its docstring or first few lines, summarize in 1-2 sentences.

### "What calls X?" / "What uses X?"

Grep for references to X across the codebase.
Return: list of files and line numbers where X is imported or invoked.

### "Show me the structure"

Print a tree view of the project (depth 2-3), annotated with purpose:

```
myproject/
├── src/
│   ├── auth/        # Authentication and token handling
│   ├── api/         # HTTP endpoints
│   └── core/        # Domain logic
├── tests/           # Test suite
└── docs/            # Documentation
```

### "How do I add a new [thing]?"

Based on project structure, suggest:
1. Where to create the file
2. What interface/protocol to implement
3. Where to register it (if applicable)

### "What's the flow for [action]?"

Trace the call path from entry point to result. Present as numbered steps or Mermaid diagram.

## Session Behavior

Stay in navigator mode until the user:
- Asks to do something (action request) → hand off to appropriate skill
- Says "exit", "done", "thanks" → end navigator session
- Starts a new unrelated topic → exit naturally

While in navigator mode, keep responses concise:
- Direct answers, not essays
- File paths with line numbers
- Code snippets only when clarifying

## Quick Commands (within session)

| User says | Navigator does |
|-----------|----------------|
| `tree` | Print annotated directory tree |
| `commands` | List all blueprint commands |
| `skills` | List all blueprint skills |
| `deps <file>` | Show what <file> imports and what imports it |
| `entry` | List main entry points (if detectable) |
| `recent` | Show recently modified files (git or mtime) |

## Limitations

Be explicit about what you can't do:
- "I can't see runtime behavior — only static code"
- "This file is binary, I can only see its path"
- "Index limited to 50 files; for larger codebases use targeted queries"

## Handoff

**STOP.** When the user asks to take action (create, edit, refactor, fix), say:

```
That's an action request — exiting navigator.
Suggested skill: [ideate / architect / refactor / etc.]
Shall I proceed with [skill]?
```

Do NOT perform actions yourself.

## Contract (BCS-1.0)

### Mode
READ-ONLY, INTERACTIVE. A multi-turn Q&A session, not a single-pass analysis. Never creates,
edits, or deletes a file — including report files.

### Consumes
- A question about a codebase that already exists, in freeform natural language.
- A readable codebase: the current working directory by default, or a path the user names.
  If the target directory is unreadable or empty, say so and stop — do not answer from
  memory or from the conversation transcript alone.
- OPTIONAL: `~/.claude/skills` and `~/.claude/commands`, for questions about blueprint itself.
- No structured upstream `## Handoff` is required, and none is read. This is an entry-point
  skill.

Questions about approaches that do not yet exist in code are out of scope — route to `ideate`.

### Produces
Conversational answers in the session only. **No artifact, no file, no `## Handoff`.**
This is a terminal skill, in the same sense as `scaffold`.

Answers contain some mix of: file paths with line numbers, one-to-two-sentence summaries,
annotated directory trees, import/caller lists, and call-path traces. None of this is
contractual — no downstream skill parses it, so no format is fixed.

> **Naming collision — read this before linting.** The `## Handoff` heading at line 138 of
> this file is **not** a BCS-1.0 Handoff. It is a session-exit instruction: it tells the
> skill how to hand the *user* to an action skill when they ask for a change. It emits no
> IDs, no tables, no fields, and nothing downstream reads it. A tool grepping for
> `## Handoff` will wrongly conclude navigator produces one.

### Degrees of Freedom
- All answer phrasing and formatting is free.
- The index built on activation (lines 21-57) is a suggested recipe, not a contract. Swap the
  commands for anything equivalent; on a non-Python codebase, adapt them.
- Query types (lines 59-107) are patterns, not an exhaustive list. Answer adjacent questions
  in the same style.
- The quick-command table (lines 120-129) is convenience shorthand, not required vocabulary.

Two things are fixed:
- The read-only rule. No file is written under any phrasing of any request.
- The exit behaviour at lines 138-148. An action request ends the session and names a skill;
  navigator never performs the action.

### Downstream Consumers
**None.**

Verified against every other skill's `### Consumes` block, not assumed — a downstream edge is
declared by the sender but enforced by the receiver, so a one-sided claim always looks fine
and never runs.

- `architect` enumerates exactly three entry points — ideate, review-architecture, direct.
  Navigator is not among them. Its direct-entry branch accepts "the existing codebase context
  directly" from the *user*, which is freeform context, not a navigator handoff.
- `refactoring-plan` requires at least one Handoff bearing `CR-*`, `AR-*`, `DM-*`, or `CA-*`
  Finding IDs. Navigator emits no Finding IDs.
- `design` requires an architect Handoff. `scaffold` requires a design Handoff.
  `plan-tracker` requires refactoring-plan, design, or an existing `PLAN-*.md`.
  `spec-interview` requires a markdown file path.

Navigator's value is delivered to the human in the session. Its exit instruction *suggests* a
next skill, but that skill starts from the user's own restated request — it does not consume
anything navigator produced.
