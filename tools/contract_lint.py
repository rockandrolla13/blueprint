#!/usr/bin/env python3
"""Validate Blueprint skill outputs against BCS-1.0 contracts."""
import argparse
import re
import sys
from typing import Optional

CONTRACTS = {
    "ideate": {
        "must_labels": ["Chosen approach:", "Load-bearing assumptions:"],
        "forbidden_patterns": ["Comparison matrix"],
        "finding_id_pattern": None,
    },
    "architect": {
        "must_labels": ["```mermaid", "Module |", "Responsibility |", "DAG check:", "Entry point:"],
        "forbidden_patterns": ["Boundary conflict resolution"],
        "finding_id_pattern": None,
    },
    "design": {
        "must_labels": ["├──", "```python", "Approach:"],
        "forbidden_patterns": [],
        "finding_id_pattern": None,
    },
    "code-review": {
        "must_labels": ["Severity |", "Pillar |", "Location |", "Finding ID"],
        "forbidden_patterns": ["BEFORE:", "AFTER:"],
        "finding_id_pattern": r"CR-[A-Z]+-\d{3}",
    },
    "review-architecture": {
        "must_labels": ["Dimension |", "Score |", "Key Finding"],
        "forbidden_patterns": [],
        "finding_id_pattern": r"AR-[A-Z]+-\d{3}",
    },
    "refactoring-plan": {
        "must_labels": [
            "Finding IDs:", "Scope:", "Risk:",
            "What changes:", "What doesn't change:",
            "Verification:", "Depends on:", "Blocks:",
        ],
        "forbidden_patterns": [],
        "finding_id_pattern": None,
    },
}

SKILL_SIGNATURES = {
    "ideate": "Chosen approach:",
    "architect": "DAG check:",
    "design": "Approach:",
    "code-review": "CR-",
    "review-architecture": "AR-",
    "refactoring-plan": "Finding IDs:",
}

STATUS_VOCAB = {"PENDING", "IN PROGRESS", "DONE", "FAILED", "SKIPPED", "BLOCKED"}


def extract_handoff(text: str) -> Optional[str]:
    """Extract ## Handoff section from markdown text."""
    match = re.search(r"^## Handoff\b.*?\n(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL)
    return match.group(0) if match else None


def infer_skill(text: str) -> Optional[str]:
    """Guess skill from content signatures."""
    for skill, sig in SKILL_SIGNATURES.items():
        if sig in text:
            return skill
    return None


def lint(text: str, skill: str) -> list[tuple]:
    """Run all checks. Returns list of (check_name, passed, detail)."""
    contract = CONTRACTS[skill]
    results = []

    # Check 1: Handoff exists
    handoff = extract_handoff(text)
    results.append(("Handoff section exists", handoff is not None, "" if handoff else "No ## Handoff found"))
    if handoff is None:
        return results

    # Check 2: MUST labels
    missing = [label for label in contract["must_labels"] if label not in handoff]
    results.append(("MUST labels present", not missing, f"Missing: {missing}" if missing else ""))

    # Check 3: FORBIDDEN patterns
    found = [p for p in contract["forbidden_patterns"] if p in handoff]
    results.append(("No FORBIDDEN patterns", not found, f"Found: {found}" if found else ""))

    # Check 4: Finding IDs
    pattern = contract["finding_id_pattern"]
    if pattern:
        ids = re.findall(pattern, handoff)
        results.append(("Finding IDs match format", bool(ids), f"No {pattern} IDs found" if not ids else f"{len(ids)} found"))
    else:
        results.append(("Finding IDs (n/a)", True, "No ID pattern required"))

    # Check 5: Status vocabulary
    status_re = re.findall(r"\b(PENDING|IN PROGRESS|DONE|FAILED|SKIPPED|BLOCKED)\b", handoff)
    bad_status = [
        m.group(1)
        for m in re.finditer(r"\bStatus\b.*?(\b[A-Z]{4,}\b)", handoff)
        if m.group(1) not in STATUS_VOCAB and m.group(1) not in {"MUST", "OPTIONAL", "FORBIDDEN", "NONE"}
    ]
    if status_re or bad_status:
        results.append(("Status vocabulary", not bad_status, f"Invalid: {bad_status}" if bad_status else ""))
    else:
        results.append(("Status vocabulary (n/a)", True, "No status labels present"))

    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Lint Blueprint skill output against BCS-1.0 contract")
    parser.add_argument("file", help="Markdown file to validate")
    parser.add_argument("--skill", choices=list(CONTRACTS.keys()), help="Skill name (inferred if omitted)")
    args = parser.parse_args()

    text = open(args.file).read()

    skill = args.skill or infer_skill(text)
    if not skill:
        print("FAIL: Cannot infer skill. Use --skill to specify.")
        sys.exit(1)
    if skill not in CONTRACTS:
        print(f"FAIL: Unknown skill '{skill}'. Known: {', '.join(CONTRACTS)}")
        sys.exit(1)

    results = lint(text, skill)
    all_pass = all(passed for _, passed, _ in results)

    print(f"Contract lint: {skill}")
    print("-" * 50)
    for name, passed, detail in results:
        status = "PASS" if passed else "FAIL"
        line = f"  [{status}] {name}"
        if detail:
            line += f" — {detail}"
        print(line)
    print("-" * 50)
    print(f"Verdict: {'PASS' if all_pass else 'FAIL'}")
    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
