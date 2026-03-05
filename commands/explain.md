Explain this codebase for someone new. $ARGUMENTS

Read the entire codebase, then produce a walkthrough document:

1. **One-paragraph summary:** What does this package do? What problem
   does it solve? Who uses it?

2. **Architecture map:** Mermaid diagram showing the main modules and
   how data flows between them. Keep it to 5-8 boxes maximum.

3. **Entry points:** The 3-5 most important functions or classes.
   For each: what it does, when to use it, one example call.

4. **Key concepts:** Domain-specific terms used in the code that a
   new reader needs to understand. Define each in one sentence.

5. **Common tasks:** How to do the 3 most frequent things:
   - "I want to run an analysis" → start here, call this, get that
   - "I want to add a new [strategy/model/report]" → create this file,
     implement this interface, register here
   - "I want to understand the results" → look here, format is this

6. **Gotchas:** Anything surprising, non-obvious, or easy to get wrong.

Write the output as a Markdown file at docs/WALKTHROUGH.md (or
the path specified in arguments). Keep it under 200 lines — if a new
reader can't finish it in 15 minutes, it's too long.

Do not modify any source code. Only create the walkthrough.
