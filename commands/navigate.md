Make this codebase easier to discover and navigate. $ARGUMENTS

Run review-depth. Then propose a concrete plan for:

1. **Entry points:** Curate every __init__.py with __all__ exposing
   only the 3-7 most important symbols per package
2. **Signposts:** Add one-line docstrings to every public function
   that lacks one. Type hints on all public signatures.
3. **Naming:** Flag functions with unclear names (abbreviations,
   single letters, generic names like process/handle/do)
4. **Directory structure:** If flat (10+ files at one level), propose
   grouping into subpackages by domain
5. **README or index:** If no README exists in the package root,
   draft one that explains: what this package does, the 3 main
   entry points, and a "start here" pointer

Present the plan. Do not make changes until I approve.
After approval, execute as a tracked plan via plan-tracker.
