#!/bin/bash
# blueprint - create repo structure
# Run from the directory where you want the repo created

set -e

REPO="blueprint"

mkdir -p "$REPO"/{ideate,architect,design,scaffold,refactor,review-architecture,refactoring-plan,plan-tracker}

echo "Created directory structure:"
echo ""
echo "blueprint/"
echo "├── README.md"
echo "├── CLAUDE.md"
echo "├── WORKFLOWS.md"
echo "├── shared-principles.md"
echo "├── ideate/"
echo "│   └── SKILL.md"
echo "├── architect/"
echo "│   └── SKILL.md"
echo "├── design/"
echo "│   └── SKILL.md"
echo "├── scaffold/"
echo "│   └── SKILL.md"
echo "├── refactor/"
echo "│   └── SKILL.md"
echo "├── review-architecture/"
echo "│   └── SKILL.md"
echo "├── refactoring-plan/"
echo "│   └── SKILL.md"
echo "└── plan-tracker/"
echo "    └── SKILL.md"
echo ""
echo "Now populate with SKILL.md files from the downloaded outputs."

cd "$REPO"
git init
git add -A
git commit -m "Initial commit: blueprint skill family

8 composable Claude skills for architecture-first engineering:

Build workflow:  ideate → architect → design → scaffold
Review workflow: code-review + review-architecture → refactoring-plan → refactor
Plan tracking:   plan-tracker creates, updates, and verifies execution plans

Skills:
- ideate: explore solution space, stress-test thinking
- architect: domain decomposition, abstraction mapping, boundary drawing
- design: dependency graph, data flow, interfaces, review checkpoint
- scaffold: generate boilerplate from reusable patterns
- refactor: restructure existing code to Clean Code / DRY / extensibility
- review-architecture: system-level scored diagnostic (7 dimensions)
- refactoring-plan: prioritised roadmap from review findings to execution
- plan-tracker: tracked execution plans with status, verification, and diff"

echo ""
echo "Repo initialised. To push:"
echo "  gh repo create rockandrolla13/blueprint --public --source=. --push"
echo "  # or"
echo "  git remote add origin git@github.com:rockandrolla13/blueprint.git"
echo "  git push -u origin main"
