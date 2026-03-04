---
name: scout
description: Review an external GitHub repo and identify skills, agents, or patterns to incorporate into our AgentDS framework.
---

Review the repository at $ARGUMENTS and produce a structured assessment.

## Step 1 — Clone and scan
```bash
cd /tmp
git clone --depth 1 $ARGUMENTS scout-repo 2>/dev/null
find scout-repo -name "*.md" -o -name "*.py" -o -name "*.json" | head -100
```

## Step 2 — Identify what they have

Read their CLAUDE.md, README.md, any files in .claude/skills/, .claude/agents/, .claude/commands/, and any src/ or scripts/ directory. Summarize:

1. **Skills they define** — list each with a one-line description
2. **Agents they define** — list each with role and responsibilities
3. **Slash commands they define** — list each with what it does
4. **Scripts/utilities** — list reusable functions, not project-specific glue code
5. **Patterns worth stealing** — workflow ideas, prompt techniques, structural decisions

## Step 3 — Gap analysis against our framework

Compare against what we already have. Read our skill index from CLAUDE.md §6.

For each item they have, classify as:
- **ALREADY COVERED** — we have an equivalent skill/script (name it)
- **UPGRADE** — we have something similar but theirs is better in a specific way (explain)
- **NEW SKILL** — we don't have this, and it's relevant to credit/quant/DS research
- **NEW AGENT** — a subagent role we don't have
- **IRRELEVANT** — not applicable to our domain (skip silently)

## Step 4 — Concrete recommendations

For each NEW SKILL or UPGRADE, write:
- Proposed filename: `.claude/skills/<category>/<Name>.md` and `scripts/<category>/<name>.py`
- What it does (2 sentences)
- Which existing skills it relates to
- Priority: HIGH (fills a real gap) / MEDIUM (nice to have) / LOW (edge case)

For each NEW AGENT, write:
- Proposed filename: `.claude/agents/<name>.md`
- Role description (1 sentence)
- Which skills it would use
- Priority

## Step 5 — Output

Write the full assessment to docs/plans/scout-<repo-name>.md and print a summary table:

| Item | Type | Priority | Proposed Path |
|------|------|----------|---------------|

Do NOT create any skill or agent files. Only produce the assessment. I decide what gets built.

## Cleanup
```bash
rm -rf /tmp/scout-repo
```
