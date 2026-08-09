Open the blueprint explainer page in a browser.

Run this, from the blueprint repo root:

```bash
xdg-open how-it-works.html 2>/dev/null || open how-it-works.html
```

If neither opener exists, print the absolute path so the user can click it.

The page explains, in plain language: the checkpoint gate and why it is the
whole point, the build and review chains, why three review skills that sound
alike measure three different costs, all 14 skills in one table, and the
pressure-pack layer.

It is a single self-contained HTML file — no network, no dependencies. Colour
carries meaning: teal means the skill cannot touch your files, rust means it
writes code, amber marks a gate.

Hosted copy, same content:
https://claude.ai/code/artifact/1c4e0f6c-f6e1-4612-b670-28cad62b219b

If the repo has changed materially since the page was written, say so rather
than letting it mislead — regenerate it instead of patching it by hand.
