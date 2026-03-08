Print a quick map of this blueprint installation. $ARGUMENTS

This is a READ-ONLY command. It discovers and displays — never modifies.

## Step 1 — Discover Commands

```bash
ls ~/.claude/commands/*.md 2>/dev/null | xargs -I {} basename {} .md
```

For each command, extract the first line (description) from the file.

## Step 2 — Discover Skills

```bash
find ~/.claude/skills -name "SKILL.md" 2>/dev/null
```

For each skill, parse the YAML frontmatter `name` and `description` fields.

## Step 3 — Print Inventory

Format as two tables:

```
## Commands (N total)

| Command | Description |
|---------|-------------|
| /build  | New Python package from scratch with interview |
| /map    | Print a quick map of this blueprint installation |
| ...     | ... |

## Skills (N total)

| Skill | Description |
|-------|-------------|
| ideate | Explore solution space, stress-test thinking |
| architect | Domain decomposition, abstraction mapping |
| ...   | ... |
```

## Step 4 — Show Structure (if in blueprint repo)

If current directory is ~/blueprint or a subdirectory:

```
## Repo Structure

blueprint/
├── commands/       (N files)
├── ideate/         SKILL.md
├── architect/      SKILL.md
├── ...
└── CLAUDE.md
```

## Step 5 — Quick Reference

Print a one-liner cheat sheet:

```
## Quick Reference

Build:    /build → /full-build
Review:   /triage → /review-cycle → /deep-clean
Fix:      /fix-pr
Generate: /test, /explain, /scaffold
Navigate: /map, /navigator
```

## No File Output

This command prints to conversation only. It does NOT create any files.
If the user wants a persistent map, suggest running `/explain` instead.
