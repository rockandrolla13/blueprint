Reduce bloat in this codebase. $ARGUMENTS

Run code-review and review-depth with a specific focus:

1. **Dead code:** functions, classes, imports never called or imported
2. **Redundant wrappers:** pass-through functions with depth ratio < 2
3. **Bloated docstrings:** docstrings longer than the function body,
   restating type hints as prose, or documenting obvious parameters.
   Docstrings should be: one-line summary, then Args/Returns only if
   non-obvious from type hints
4. **Over-abstraction:** protocols/ABCs with only one implementation,
   config objects wrapping a single value, builder patterns for
   simple construction
5. **Copy-paste duplication:** near-identical blocks that should be
   one function with a parameter

For each finding, state the line count saved if fixed.
Present findings sorted by lines-saveable. Do not fix anything yet.
