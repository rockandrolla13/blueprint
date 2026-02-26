---
name: scaffold
description: >
  Generate boilerplate code from reusable patterns and templates for common project structures.
  Use this skill when the user says "scaffold", "bootstrap", "create a new module", "set up a
  new project", "new strategy", "new pipeline", "add a new [data source / signal / component]",
  "stub out", "template", or wants to stamp out a structural pattern they've used before. Also
  trigger when the user says "add another X like Y" — this implies a repeatable pattern. Trigger
  for both new project creation and adding new modules to existing projects. The skill ensures all
  generated boilerplate follows Clean Code, DRY, and the user's established conventions. Do NOT
  trigger for refactoring existing code (use the refactor skill) or for open-ended design
  (use the design skill).
---

# Scaffold Skill

You are operating as a Code Generator that stamps out well-structured boilerplate. The key
insight: if the user is creating something "like" something they've built before, the structure
should be consistent, the conventions should match, and the wiring should be automatic. The user
should only need to fill in the domain-specific logic, not reinvent the structural scaffolding.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)
→ **Read**: `templates/` directory in this skill folder for available templates

## How Scaffolding Works

### Step 1: Identify the Pattern
When the user requests a new component, determine which template applies:
- New project from scratch → **Project Template**
- New strategy/signal module in existing project → **Strategy Module Template**
- New data source/pipeline stage → **Data Pipeline Template**
- New CLI command or entry point → **CLI Template**
- Something else → derive a template from the user's existing code, then apply it

If no template matches and there's existing similar code in the project, **read that code first**
and extract the pattern before generating. Consistency with the existing codebase beats a
"better" but inconsistent structure.

### Step 2: Gather Parameters
Each template requires specific inputs. Ask for them upfront — don't generate half a scaffold
and then ask questions. Typical parameters:

- **Name**: module/project/strategy name
- **Purpose**: one-sentence description (becomes the module docstring)
- **Dependencies**: what existing components does this consume?
- **Parallelism**: will this process items independently? (determines whether to include
  concurrent.futures boilerplate)

### Step 3: Generate and Review
Generate the complete scaffold, then present it for review before writing files. Show:
- File tree of what will be created
- Key code for each file (full content, not summaries)
- How it wires into the existing project (imports, config changes, test registration)

### Step 4: Write Files
After approval, write all files and verify the project still works (imports resolve, existing
tests pass).

## Templates

### Project Template
A complete new project following the user's standard layout.

Generates:
```
{project_name}/
├── src/
│   └── {package_name}/
│       ├── __init__.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── protocols.py      # Protocol definitions for all interfaces
│       │   └── types.py          # Domain dataclasses and type aliases
│       ├── data/
│       │   ├── __init__.py
│       │   └── sources.py        # DataSource implementations
│       ├── strategy/
│       │   ├── __init__.py
│       │   └── signals.py        # Strategy / signal implementations
│       └── execution/
│           ├── __init__.py
│           └── cli.py            # Click/Typer CLI entry points
├── tests/
│   ├── conftest.py               # Shared fixtures
│   ├── unit/
│   │   └── __init__.py
│   └── integration/
│       └── __init__.py
├── config/
│   └── default.yaml
├── pyproject.toml
└── README.md
```

Key contents generated:

**`core/protocols.py`** — starter protocols:
```python
from typing import Protocol
from datetime import date
import pandas as pd

class DataSource(Protocol):
    """Contract for any data provider."""
    def fetch(self, identifiers: list[str], start: date, end: date) -> pd.DataFrame: ...

class SignalGenerator(Protocol):
    """Contract for any signal computation."""
    def compute(self, data: pd.DataFrame) -> pd.Series: ...
```

**`core/types.py`** — Pydantic config + domain dataclasses:
```python
from dataclasses import dataclass
from pathlib import Path
from pydantic import BaseModel

class AppConfig(BaseModel):
    """External configuration — loaded from YAML/CLI."""
    data_dir: Path
    output_dir: Path = Path("output")

@dataclass(frozen=True)
class Instrument:
    """Internal domain type."""
    identifier: str
    name: str
```

**`execution/cli.py`** — Click entry point:
```python
import click
from pathlib import Path

@click.group()
def cli():
    """[Project description]."""
    pass

@cli.command()
@click.option("--config", type=click.Path(exists=True), default="config/default.yaml")
def run(config: str):
    """Run the main pipeline."""
    # Load config, wire components, execute
    pass

if __name__ == "__main__":
    cli()
```

**`pyproject.toml`** — standard project metadata with pytest config:
```toml
[project]
name = "{package_name}"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["click", "pandas", "pydantic", "pyyaml"]

[project.optional-dependencies]
dev = ["pytest", "hypothesis", "ruff"]

[project.scripts]
{package_name} = "{package_name}.execution.cli:cli"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

**`tests/conftest.py`** — shared fixtures:
```python
import pytest
from pathlib import Path

@pytest.fixture
def sample_config():
    """Reusable config fixture."""
    return {"data_dir": Path("tests/fixtures"), "output_dir": Path("/tmp/test_output")}
```

### Strategy Module Template
Adds a new strategy/signal to an existing project.

Generates:
```
src/{package}/strategy/{strategy_name}.py     # Implementation
tests/unit/test_{strategy_name}.py             # Unit tests
config/{strategy_name}.yaml                    # Strategy-specific config (if needed)
```

**`strategy/{strategy_name}.py`**:
```python
"""
{Strategy description}.

Mathematical specification:
    Signal: s_i(t) = [DEFINE]
    Assumptions: [STATE]
    Degeneracy: [EDGE CASES]
"""
from dataclasses import dataclass
import pandas as pd
from ..core.protocols import SignalGenerator

@dataclass
class {StrategyName}Config:
    """Parameters for {strategy_name}."""
    lookback: int = 252
    threshold: float = 1.5

class {StrategyName}(SignalGenerator):
    """Implements the {strategy_name} signal."""

    def __init__(self, config: {StrategyName}Config | None = None):
        self.config = config or {StrategyName}Config()

    def compute(self, data: pd.DataFrame) -> pd.Series:
        """Compute signal for each instrument."""
        raise NotImplementedError("Fill in the signal logic")
```

### Data Pipeline Template
Adds a new data source or pipeline stage.

Generates:
```
src/{package}/data/{source_name}.py           # Implementation
tests/unit/test_{source_name}.py              # Unit tests with mock data
tests/fixtures/{source_name}_sample.parquet   # Sample data fixture (if applicable)
```

### CLI Template
Adds a new CLI command to an existing project.

Generates:
```
src/{package}/execution/{command_name}.py     # Command implementation
```

Wires it into the existing `cli.py` group.

## Automation & Parallelisation Boilerplate

When the scaffold will process items independently (instruments, dates, files), include
parallel execution boilerplate:

```python
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import TypeVar, Callable

T = TypeVar("T")
R = TypeVar("R")

def parallel_map(
    fn: Callable[[T], R],
    items: list[T],
    max_workers: int | None = None,
    desc: str = "Processing",
) -> list[R]:
    """Map fn over items in parallel with progress tracking."""
    results = []
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(fn, item): item for item in items}
        for future in as_completed(futures):
            try:
                results.append(future.result())
            except Exception as e:
                item = futures[future]
                logging.error(f"{desc} failed for {item}: {e}")
    return results
```

Include this in `core/concurrency.py` when the project template is generated. Individual
modules then import and use it rather than each writing their own parallel execution logic.

## Consistency Rules

1. **Match existing conventions.** If the project uses `dataclasses`, scaffold with `dataclasses`.
   If it uses `Pydantic`, scaffold with `Pydantic`. Read before writing.
2. **Register new modules.** Update `__init__.py` exports, CLI groups, and any registry patterns
   the project uses.
3. **Include tests.** Every scaffolded module gets at minimum a test file with one smoke test
   that imports the module and instantiates the main class. The user fills in real tests.
4. **Include docstrings.** Every module, class, and public function gets a docstring. For
   strategy modules, the docstring includes the mathematical specification stub.
5. **Mark TODOs.** Use `# TODO:` comments for logic the user needs to fill in. Be specific:
   `# TODO: implement signal computation` not just `# TODO`.
