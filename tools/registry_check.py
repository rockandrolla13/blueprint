#!/usr/bin/env python3
"""Generate SKILL-INDEX.md from skill frontmatter; --check fails on drift.

Blueprint is 0-for-5 at keeping hand-synced registries in sync. This tool makes
the index a derived artifact instead of a sixth hand-maintained list.

Discovery is filesystem-only: `*/SKILL.md` under the repo root, `commands/*.md`.
There is deliberately no hardcoded skill list anywhere in this file.

It also checks negative-trigger RECIPROCITY: if A disclaims B by name, B should
name A back. Negative triggers get written looking backward — the new skill
disclaims the old, the old never learns about the new — so this defect recurs
every time a skill is added. It is mechanically checkable, so CI checks it.
"""
import argparse
import difflib
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
INDEX = REPO / "SKILL-INDEX.md"
REGEN_CMD = "python3 tools/registry_check.py --write"

MAX_SKILL_LINES = 500
NEG_TRIGGER_RE = re.compile(r"[Dd]o NOT trigger|[Dd]o not trigger")

# Directories that are not skills even if they somehow contain a SKILL.md.
NON_SKILL_DIRS = {"docs", "examples", "reviews", "tools", "commands", ".git", ".claude"}


# --------------------------------------------------------------------------
# Frontmatter parser
#
# Deliberately dumb. Supports ONLY the subset blueprint actually uses:
#   key: bare value
#   key: "quoted value"
#   key: >           (folded block; continuation lines are more-indented)
#     line one
#     line two
# NOT supported, on purpose: nested maps, lists, anchors, multi-doc, |literal
# blocks, comments, escapes inside quotes. Anything unrecognised is ignored
# rather than guessed at.
# --------------------------------------------------------------------------
def parse_frontmatter(text: str) -> dict[str, str]:
    """Return top-level scalar keys from a leading --- fenced YAML block."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        return {}  # unterminated frontmatter (file mid-write?)

    out: dict[str, str] = {}
    i = 1
    while i < end:
        raw = lines[i]
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", raw)
        if not m:
            i += 1
            continue
        key, val = m.group(1), m.group(2).strip()
        if val in (">", ">-", "|", "|-"):
            # Folded/literal block: consume more-indented following lines.
            body: list[str] = []
            i += 1
            while i < end and (lines[i].strip() == "" or lines[i].startswith((" ", "\t"))):
                body.append(lines[i].strip())
                i += 1
            out[key] = " ".join(b for b in body if b)
            continue
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        out[key] = val
        i += 1
    return out


# --------------------------------------------------------------------------
# Records
# --------------------------------------------------------------------------
@dataclass
class Skill:
    dirname: str
    path: Path
    name: str = ""
    description: str = ""
    mode: str = ""
    kind: str = ""
    declared_output: str = ""
    consumes: list[str] = field(default_factory=list)
    feeds: list[str] = field(default_factory=list)
    negatives: list[str] = field(default_factory=list)
    lines: int = 0
    has_frontmatter: bool = False
    has_contract: bool = False
    has_stop: bool = False
    has_pregate: bool = False
    parse_error: str = ""


@dataclass
class Command:
    name: str
    path: Path
    description: str
    from_frontmatter: bool


def _section(text: str, heading: str) -> str:
    """Body of a `### <heading>` block, up to the next ## or ### heading."""
    m = re.search(
        rf"^###\s+{re.escape(heading)}\s*$\n(.*?)(?=^###?\s|\Z)",
        text, re.MULTILINE | re.DOTALL,
    )
    return m.group(1).strip() if m else ""


def _first_line(block: str) -> str:
    for ln in block.splitlines():
        ln = ln.strip().lstrip("-* ").strip()
        if ln:
            return ln
    return ""


def _sentences(text: str) -> list[str]:
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if s.strip()]


def _purpose(description: str) -> str:
    """First non-trigger sentence of the description, minus "Use when" boilerplate."""
    for s in _sentences(description):
        if re.match(r"^(Trigger|Also trigger|Do NOT|Use this skill when the user says)", s):
            continue
        s = re.sub(r"^Use (this skill )?(when|to|for)\s+", "", s)
        return s[:1].upper() + s[1:]
    return ""


def load_skill(d: Path, known: set[str]) -> Skill:
    """Read one skill dir. Never raises on malformed content — records it."""
    sk = Skill(dirname=d.name, path=d / "SKILL.md")
    try:
        text = sk.path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        sk.parse_error = f"unreadable: {e}"
        return sk

    sk.lines = len(text.splitlines())
    fm = parse_frontmatter(text)
    sk.has_frontmatter = bool(fm)
    sk.name = fm.get("name", "")
    sk.description = re.sub(r"\s+", " ", fm.get("description", "")).strip()
    if not sk.has_frontmatter:
        sk.parse_error = "no parseable YAML frontmatter"

    sk.negatives = [s for s in _sentences(sk.description) if NEG_TRIGGER_RE.search(s)]
    sk.has_contract = bool(re.search(r"^##\s+Contract \(BCS-1\.0\)", text, re.MULTILINE))
    sk.has_stop = "**STOP.**" in text
    sk.has_pregate = bool(re.search(r"^##\s+Pre-Gate Self-Check", text, re.MULTILINE))

    sk.mode = _first_line(_section(text, "Mode"))
    sk.declared_output = fm.get("output", "").strip()
    sk.kind = output_kind(sk.declared_output)
    # Upstream/downstream: only names that resolve to real skill dirs on disk.
    consumes_blk = _section(text, "Consumes")
    sk.consumes = sorted(n for n in known if n != sk.dirname and re.search(rf"\b{re.escape(n)}\b", consumes_blk))
    feeds_blk = _section(text, "Downstream Consumers")
    sk.feeds = sorted(n for n in known if n != sk.dirname and re.search(rf"\b{re.escape(n)}\b", feeds_blk))
    return sk


def discover_skills(root: Path) -> list[Skill]:
    """Scan the filesystem for */SKILL.md. Never a hardcoded list."""
    dirs = sorted(
        p.parent for p in root.glob("*/SKILL.md")
        if p.parent.name not in NON_SKILL_DIRS
    )
    known = {d.name for d in dirs}
    return [load_skill(d, known) for d in dirs]


def discover_commands(root: Path) -> list[Command]:
    """Scan commands/*.md. Most have no frontmatter — fall back to line 1."""
    out: list[Command] = []
    for p in sorted((root / "commands").glob("*.md")):
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        if fm.get("description"):
            desc, tagged = re.sub(r"\s+", " ", fm["description"]).strip(), True
        else:
            first = next((ln.strip() for ln in text.splitlines() if ln.strip() and ln.strip() != "---"), "")
            desc, tagged = first.replace("$ARGUMENTS", "").strip().rstrip(":"), False
        out.append(Command(name=p.stem, path=p, description=desc, from_frontmatter=tagged))
    return out


# --------------------------------------------------------------------------
# Invariant checks (only the mechanically checkable ones from CLAUDE.md)
# --------------------------------------------------------------------------
def check_invariants(skills: list[Skill]) -> list[tuple[str, str]]:
    """Return (skill, violation) pairs."""
    v: list[tuple[str, str]] = []
    for s in skills:
        if s.parse_error:
            v.append((s.dirname, s.parse_error))
        if s.has_frontmatter and not s.name:
            v.append((s.dirname, "frontmatter has no `name:`"))
        elif s.name and s.name != s.dirname:
            v.append((s.dirname, f"`name: {s.name}` does not match directory"))
        if not s.description:
            v.append((s.dirname, "frontmatter has no `description:`"))
        elif not s.negatives:
            v.append((s.dirname, "description declares no negative trigger (`Do NOT trigger ...`)"))
        if not s.has_stop:
            extra = " (has Pre-Gate Self-Check but no explicit stop)" if s.has_pregate else ""
            v.append((s.dirname, f"no checkpoint gate — literal `**STOP.**` absent{extra}"))
        if not s.has_contract:
            v.append((s.dirname, "no `## Contract (BCS-1.0)` block"))
        if s.lines > MAX_SKILL_LINES:
            v.append((s.dirname, f"{s.lines} lines exceeds {MAX_SKILL_LINES}"))
        if not s.declared_output:
            v.append((s.dirname, "frontmatter has no `output:` — cannot be reciprocity-checked. "
                                 f"Declare one of: {', '.join(sorted(OUTPUT_KINDS))}"))
        elif not s.kind:
            v.append((s.dirname, f"`output: {s.declared_output}` is not a known kind. "
                                 f"Use one of: {', '.join(sorted(OUTPUT_KINDS))}"))
    return v


# --------------------------------------------------------------------------
# Negative-trigger reciprocity
#
#   A disclaims B  ==  a sentence of A's `description:` contains a negative
#                      marker (`do not trigger`, `do not use`, `never trigger`)
#                      AND names B.
#   B reciprocates ==  B's `description:` names A ANYWHERE, any polarity.
#   Reported       ==  A disclaims B, B never names A, AND the two are PEERS
#                      (see below).
#
# The peer test is what stops this from being noise. Two different things wear
# identical grammar inside a `Do NOT trigger` sentence:
#
#   DISCLAIMER  A and B contest the same request; A pushes back.
#               review-depth: "architecture scoring (use review-architecture)"
#   ROUTING     A points at a DIFFERENT job it does not do and does not want.
#               scaffold:     "refactoring existing code (use the refactor skill)"
#
# There is no textual difference between those two — same construction, same
# punctuation. So no amount of phrasing analysis separates them, and demanding
# reciprocity for routing would make every description disclaim skills it never
# collides with. What separates them is WHAT THE TWO SKILLS PRODUCE: users
# confuse skills that hand back the same kind of artifact. So reciprocity is
# demanded only between skills of the same declared output kind — two scored
# diagnostics, two code writers — never across kinds.
#
# Narrowings, all biased toward under-reporting; a noisy lint is an ignored one:
#
# 1. Double-quoted spans are stripped before matching. Descriptions quote
#    example USER utterances, and those collide with skill names: navigator
#    says `Do NOT trigger for action requests like "refactor X"`, which is not
#    a reference to the refactor skill. Single-quoted spans are NOT stripped —
#    apostrophes ("that's", "user's") make `'...'` pairing unsafe. Costs
#    nothing today: no single-quoted span in the repo contains a skill name.
# 2. Names match on word boundaries, longest name first, so `refactoring-plan`
#    is not read as a mention of `refactor`. The flip side: `refactoring` is
#    then not a mention of `refactor` either. That is the intended reading —
#    reciprocity is about naming the sibling skill, not the activity.
# 3. Only sentences carrying a negative marker count, so a positive pointer
#    ("it feeds into the refactor skill") is never read as a disclaimer.
#
# Known misses, in rough order of how much they should worry you:
# - A skill whose output kind cannot be classified is exempt from the check
#   entirely, in BOTH directions. That is a real hole — a new skill can dodge
#   the check by describing its deliverable in words nothing here matches — so
#   `--check` prints the exempt list every run instead of hiding it.
# - Two skills that produce different artifacts but genuinely do contest a
#   phrasing. Nothing here can see that; a human has to.
# - A disclaimer split across sentences ("Do NOT trigger for X. Use Y
#   instead."), bare "use X instead" with no explicit negation, and any
#   mention that only ever appears inside quotes.
# --------------------------------------------------------------------------
QUOTED_RE = re.compile(r'"[^"]*"|“[^”]*”')
NEG_MARKER_RE = re.compile(r"do\s+not\s+trigger|don't\s+trigger|do\s+not\s+use|never\s+trigger", re.I)

# What a skill hands back, in the skill's own words. Ordered; first match wins.
# `code` is read off `### Mode`, the rest off `description:`. These are patterns
# over DELIVERABLES, never over skill names — no skill is named here, so the
# check cannot be tuned to make a particular pair pass or fail.
# Output kind is DECLARED in each skill's frontmatter (`output:`), never inferred.
#
# It was previously guessed by matching words like "scores" or "roadmap" in the
# description. That silently self-disabled: reword a description, drop the keyword,
# and the skill fell out of the reciprocity check while this tool still printed PASS.
# Coverage shrank exactly when descriptions were being edited — the moment collisions
# get introduced. A missing or unknown `output:` is now a violation, not an exemption:
# the tool fails loudly rather than quietly checking less.
OUTPUT_KINDS: frozenset[str] = frozenset({
    "code",            # writes source files            — scaffold, refactor
    "scored-report",   # findings with IDs and a score  — the review skills
    "ordered-plan",    # sequenced steps                — refactoring-plan, plan-tracker
    "structure-spec",  # modules, interfaces, layout    — architect, design
    "decision",        # a closed choice, no artifact   — ideate, orch
    "document",        # one markdown file              — spec-interview
    "none",            # conversational only            — navigator
})


def output_kind(declared: str) -> str:
    """Return the declared output kind, or '' if absent/unknown (which is a violation)."""
    d = declared.strip().lower()
    return d if d in OUTPUT_KINDS else ""


@dataclass(frozen=True)
class OneSided:
    source: str      # skill whose description disclaims `target`
    target: str      # skill named in the disclaimer
    kind: str        # output kind both share — why they are treated as peers
    evidence: str    # the sentence that triggered it, verbatim


def _mention_re(names: list[str]) -> re.Pattern[str]:
    """Word-boundary alternation over skill names, longest first."""
    ordered = sorted(names, key=len, reverse=True)
    return re.compile(r"\b(" + "|".join(re.escape(n) for n in ordered) + r")\b")


def check_reciprocity(skills: list[Skill]) -> list[OneSided]:
    """Return one-sided disclaimers between same-output-kind peers."""
    named = [s.dirname for s in skills if s.description]
    if len(named) < 2:
        return []
    mention = _mention_re(named)
    desc = {s.dirname: s.description for s in skills if s.description}
    kind = {s.dirname: s.kind for s in skills if s.description}
    mentions = {n: {m for m in mention.findall(QUOTED_RE.sub(" ", desc[n])) if m != n} for n in named}

    out: list[OneSided] = []
    for src in named:
        seen: set[str] = set()
        # Split the original text, match on the de-quoted copy of each sentence,
        # but report the original — evidence with the quotes cut out is unreadable.
        for sent in _sentences(desc[src]):
            if not NEG_MARKER_RE.search(sent):
                continue
            for tgt in sorted(set(mention.findall(QUOTED_RE.sub(" ", sent)))):
                if tgt == src or tgt in seen or src in mentions[tgt]:
                    continue
                if not kind[src] or kind[src] != kind[tgt]:
                    continue  # routing across output kinds, or an exempt skill
                seen.add(tgt)
                out.append(OneSided(src, tgt, kind[src], sent))
    return sorted(out, key=lambda o: (o.source, o.target))


def check_other_registries(root: Path, skills: list[Skill]) -> list[str]:
    """Report-only drift against the hand-maintained registries. Never edits."""
    out: list[str] = []
    names = [s.dirname for s in skills]

    readme = root / "README.md"
    if readme.exists():
        txt = readme.read_text(encoding="utf-8", errors="replace")
        rows = set(re.findall(r"^\|\s*\*\*([a-z0-9-]+)\*\*", txt, re.MULTILINE))
        for n in names:
            if n not in rows:
                out.append(f"README.md skill map: missing row for `{n}`")
        for n in sorted(rows - set(names)):
            out.append(f"README.md skill map: row `{n}` has no directory on disk")

    sp = root / "shared-principles.md"
    if sp.exists():
        txt = sp.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^## Minimum Viable Output\s*$(.*?)(?=^## )", txt, re.MULTILINE | re.DOTALL)
        blk = m.group(1) if m else ""
        # `[a-z0-9-]+` also matches the `|---|` separator row; drop all-dash cells.
        rows = {r for r in re.findall(r"^\|\s*([a-z0-9-]+)\s*\|", blk, re.MULTILINE)
                if r.strip("-")}
        for n in names:
            if n not in rows:
                out.append(f"shared-principles.md Minimum Viable Output: missing row for `{n}`")
        for n in sorted(rows - set(names)):
            out.append(f"shared-principles.md Minimum Viable Output: row `{n}` has no directory on disk")
    return out


# --------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------
NOT_DECLARED = "[not declared]"

# Workflow groupings are structural facts about blueprint, not per-skill facts;
# membership is intersected with what is actually on disk.
CHAINS = [
    ("Build chain", "ideate → architect → design → scaffold",
     ["ideate", "architect", "design", "scaffold"]),
    ("Review chain", "code-review + review-architecture + review-depth → refactoring-plan → refactor",
     ["code-review", "review-architecture", "review-depth", "refactoring-plan", "refactor"]),
    ("Meta / cross-cutting", "active in any workflow",
     ["plan-tracker", "navigator", "orch"]),
]


def _cell(text: str, limit: int) -> str:
    text = text.replace("|", "\\|").replace("\n", " ").strip()
    if not text:
        return NOT_DECLARED
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def render(skills: list[Skill], commands: list[Command], violations: list[tuple[str, str]],
           registry_drift: list[str], one_sided: list[OneSided]) -> str:
    L: list[str] = []
    L.append("<!-- GENERATED FILE — DO NOT EDIT BY HAND -->")
    L.append(f"<!-- Regenerate: {REGEN_CMD}   Verify: python3 tools/registry_check.py --check -->")
    L.append("")
    L.append("# Skill Index")
    L.append("")
    L.append(f"Generated from `*/SKILL.md` frontmatter and `## Contract (BCS-1.0)` blocks by "
             f"`tools/registry_check.py`. Every cell is derived from file content; "
             f"`{NOT_DECLARED}` means the skill does not state it. Do not edit this file — "
             f"edit the skill, then run `{REGEN_CMD}`.")
    L.append("")
    L.append("**This is not a loader.** Claude Code builds its available-skills list from a "
             "plugin/registry cache, not by reading this file. This index is repo documentation "
             "and a drift detector for humans and agents reading the repo. "
             "`--check` exits non-zero when it goes stale, so it is CI-able.")
    L.append("")
    L.append(f"{len(skills)} skills, {len(commands)} commands on disk.")
    L.append("")

    L.append("## When to use what")
    L.append("")
    L.append("| Skill | Mode | Purpose | Consumes | Feeds | Do NOT use when |")
    L.append("|---|---|---|---|---|---|")
    for s in skills:
        neg = _cell(s.negatives[0] if s.negatives else "", 150)
        L.append(
            f"| **{s.dirname}** | {_cell(s.mode, 60)} | {_cell(_purpose(s.description), 110)} "
            f"| {', '.join(f'`{c}`' for c in s.consumes) or '—'} "
            f"| {', '.join(f'`{c}`' for c in s.feeds) or '—'} | {neg} |"
        )
    L.append("")
    L.append("`Consumes` / `Feeds` list only sibling skills named in that skill's own "
             "`### Consumes` / `### Downstream Consumers` contract sections. `—` means none named.")
    L.append("")

    L.append("## Full negative triggers")
    L.append("")
    L.append("Verbatim from each `description:`. This is what stops two skills firing on the same prompt.")
    L.append("")
    for s in skills:
        L.append(f"**{s.dirname}**")
        if s.negatives:
            for n in s.negatives:
                L.append(f"- {n}")
        else:
            L.append(f"- {NOT_DECLARED} — no negative trigger in frontmatter")
        L.append("")

    L.append("## Workflow grouping")
    L.append("")
    placed: set[str] = set()
    on_disk = {s.dirname for s in skills}
    for title, chain, members in CHAINS:
        present = [m for m in members if m in on_disk]
        missing = [m for m in members if m not in on_disk]
        placed.update(present)
        L.append(f"**{title}** — `{chain}`")
        L.append("")
        L.append(f"- on disk: {', '.join(f'`{m}`' for m in present) or 'none'}")
        if missing:
            L.append(f"- named in chain but absent from disk: {', '.join(f'`{m}`' for m in missing)}")
        L.append("")
    unplaced = sorted(on_disk - placed)
    L.append(f"**Ungrouped** — skills on disk not in any chain above: "
             f"{', '.join(f'`{u}`' for u in unplaced) if unplaced else 'none'}")
    L.append("")

    L.append("## Commands")
    L.append("")
    tagged = sum(1 for c in commands if c.from_frontmatter)
    L.append(f"`commands/*.md` are slash-command prompts, not skills. "
             f"{tagged} of {len(commands)} declare YAML frontmatter; for the rest the purpose "
             f"below is the file's first line, which is all that can be derived mechanically.")
    L.append("")
    L.append("| Command | Frontmatter | Purpose (first line) |")
    L.append("|---|---|---|")
    for c in commands:
        L.append(f"| `/{c.name}` | {'yes' if c.from_frontmatter else 'no'} | {_cell(c.description, 120)} |")
    L.append("")

    L.append("## Health")
    L.append("")
    L.append("Mechanically checkable invariants from `CLAUDE.md`. Judgement-based invariants "
             "(diagnostic-vs-action separation, no duplicated principles) are not checked here.")
    L.append("")
    if violations:
        L.append(f"{len(violations)} violations across "
                 f"{len({v[0] for v in violations})} skills.")
        L.append("")
        L.append("| Skill | Violation |")
        L.append("|---|---|")
        for name, msg in violations:
            L.append(f"| `{name}` | {msg} |")
    else:
        L.append("No violations.")
    L.append("")
    L.append("### One-sided negative triggers")
    L.append("")
    L.append("`A` disclaims `B` by name in a `Do NOT trigger` sentence, but `B`'s description "
             "never names `A` at all. Negative triggers are written looking backward — the new "
             "skill disclaims the old, the old never learns about the new — so the collision is "
             "only blocked from one side. Fix by adding the reciprocal negative trigger to `B`.")
    L.append("")
    L.append("Only checked between skills that produce the SAME output kind. Pointing at a skill "
             "that does a different job is routing, not a turf dispute, and demanding reciprocity "
             "for it would bloat every description with disclaimers of skills it never collides with.")
    L.append("")
    if one_sided:
        L.append(f"{len(one_sided)} one-sided pairs.")
        L.append("")
        L.append("| Disclaims | …but is never named by | Shared output kind | Evidence from the disclaimer |")
        L.append("|---|---|---|---|")
        for o in one_sided:
            L.append(f"| `{o.source}` | `{o.target}` | {o.kind} | {_cell(o.evidence, 160)} |")
    else:
        L.append("None — every negative trigger between same-kind peers is reciprocated.")
    L.append("")
    exempt = sorted(s.dirname for s in skills if s.description and not s.kind)
    if exempt:
        L.append(f"**Not checked** — no valid `output:` in frontmatter, so invisible to the "
                 f"reciprocity check in either direction. This is a violation, not an exemption: "
                 f"{', '.join(f'`{e}`' for e in exempt)}.")
    else:
        L.append("**Coverage** — every skill declares an `output:` kind; none is skipped.")
    L.append("")
    L.append("### Drift in hand-maintained registries")
    L.append("")
    L.append("Reported only — this tool never edits `README.md` or `shared-principles.md`.")
    L.append("")
    if registry_drift:
        for d in registry_drift:
            L.append(f"- {d}")
    else:
        L.append("- none")
    L.append("")
    return "\n".join(L)


# --------------------------------------------------------------------------
@dataclass
class Report:
    text: str
    violations: list[tuple[str, str]]
    drift: list[str]
    one_sided: list[OneSided]
    exempt: list[str]


def build(root: Path) -> Report:
    skills = discover_skills(root)
    commands = discover_commands(root)
    violations = check_invariants(skills)
    drift = check_other_registries(root, skills)
    one_sided = check_reciprocity(skills)
    exempt = sorted(s.dirname for s in skills if s.description and not s.kind)
    return Report(render(skills, commands, violations, drift, one_sided),
                  violations, drift, one_sided, exempt)


def main() -> int:
    ap = argparse.ArgumentParser(
        prog="registry_check.py",
        description="Generate SKILL-INDEX.md from skill frontmatter, or verify it is current.",
        epilog="Exit 0 = clean, or --warn-only. Exit 1 = --check found index drift, "
               "other-registry drift, invariant violations, or one-sided negative triggers. "
               "Exit 2 = bad usage.",
    )
    ap.add_argument("--check", action="store_true",
                    help="do not write; report everything and exit non-zero if anything failed")
    ap.add_argument("--write", action="store_true", help="regenerate SKILL-INDEX.md (default)")
    ap.add_argument("--warn-only", action="store_true",
                    help="with --check: print the same report but always exit 0 (gate disabled)")
    ap.add_argument("--root", default=str(REPO), help="repo root to scan (default: this repo)")
    args = ap.parse_args()
    if args.warn_only and not args.check:
        ap.error("--warn-only only means something with --check")

    root = Path(args.root).resolve()
    index = root / "SKILL-INDEX.md"
    r = build(root)

    if not args.check:
        index.write_text(r.text + "\n", encoding="utf-8")
        print(f"wrote {index} ({len(r.text.splitlines()) + 1} lines)")
        print(f"  invariant violations:      {len(r.violations)}")
        print(f"  other-registry drift:      {len(r.drift)}")
        print(f"  one-sided negative triggers: {len(r.one_sided)}")
        return 0

    current = index.read_text(encoding="utf-8") if index.exists() else ""
    stale = current != r.text + "\n"
    if not stale:
        print("SKILL-INDEX.md: current")
    else:
        print("SKILL-INDEX.md: STALE — regenerate with `%s`" % REGEN_CMD)
        print("")
        sys.stdout.writelines(difflib.unified_diff(
            current.splitlines(keepends=True), (r.text + "\n").splitlines(keepends=True),
            fromfile="SKILL-INDEX.md (on disk)", tofile="SKILL-INDEX.md (generated)",
        ))

    print("")
    print(f"Invariant violations ({len(r.violations)}):")
    for name, msg in r.violations:
        print(f"  {name}: {msg}")

    print("")
    print(f"One-sided negative triggers ({len(r.one_sided)}) — A disclaims a same-output-kind "
          f"peer B, B never names A:")
    # Grouped by the sentence that produced them: one disclaimer usually names
    # several siblings at once, and printing it once per pair is unreadable.
    for (src, ev), group in _group_one_sided(r.one_sided):
        print(f"  {src} → {', '.join(g.target for g in group)}  [both: {group[0].kind}]")
        print(f"      \"{ev}\"")
    if r.exempt:
        print(f"  NOT CHECKED — no valid `output:` declared: {', '.join(r.exempt)}")
    else:
        print("  every skill declares an output kind; none skipped")

    print("")
    print(f"Other-registry drift ({len(r.drift)}) — report only, nothing edited:")
    for d in r.drift:
        print(f"  {d}")

    failures: list[str] = []
    if stale:
        failures.append("SKILL-INDEX.md stale")
    if r.violations:
        failures.append(f"{len(r.violations)} invariant violations")
    if r.one_sided:
        failures.append(f"{len(r.one_sided)} one-sided negative triggers")
    if r.drift:
        failures.append(f"{len(r.drift)} other-registry drift items")

    print("")
    if not failures:
        print("PASS — index current, invariants clean, registries in sync, "
              "every negative trigger reciprocated. (exit 0)")
        return 0
    if args.warn_only:
        print(f"WARN-ONLY — would have failed on: {'; '.join(failures)}. (exit 0, gate off)")
        return 0
    print(f"FAIL — {'; '.join(failures)}. (exit 1)")
    return 1


def _group_one_sided(items: list[OneSided]) -> list[tuple[tuple[str, str], list[OneSided]]]:
    """Collapse pairs sharing one disclaimer sentence into a single entry."""
    grouped: dict[tuple[str, str], list[OneSided]] = {}
    for o in items:
        grouped.setdefault((o.source, o.evidence), []).append(o)
    return list(grouped.items())


if __name__ == "__main__":
    sys.exit(main())
