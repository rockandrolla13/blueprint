# Deep Modules & Progressive Disclosure — Reference

## Table of Contents
1. Core Theory: Deep vs Shallow Modules
2. Progressive Disclosure Layers
3. Measuring Depth Ratio
4. `__init__.py` Patterns
5. Anti-Pattern Catalogue
6. Fix Patterns
7. Golden Example

---

## 1. Core Theory: Deep vs Shallow Modules

Source: John Ousterhout, *A Philosophy of Software Design* (2018), Chapters 4–5.

A **deep module** provides a simple interface that hides significant implementation
complexity. The classic example is the Unix file system: 5 system calls
(`open`, `read`, `write`, `lseek`, `close`) hide enormous complexity — block
allocation, caching, journaling, permissions, device drivers.

A **shallow module** has an interface that is nearly as complex as its implementation.
It doesn't simplify — it just adds a layer of indirection. The caller must understand
almost as much as if they'd written the implementation themselves.

```
Deep module:                    Shallow module:

┌──────────────────────┐        ┌──────────────────────┐
│   Small interface    │        │   Large interface     │
│   (3-5 functions)    │        │   (15+ functions)     │
├──────────────────────┤        ├──────────────────────┤
│                      │        │                      │
│                      │        │  Small implementation│
│  Large, complex      │        │  (mostly delegation) │
│  implementation      │        └──────────────────────┘
│  (hidden from user)  │
│                      │
│                      │
└──────────────────────┘
```

### Why depth matters for research code

Research codebases have a specific failure mode: the author understands everything,
so shallow modules don't feel painful. But when revisiting code 3 months later, or
when a collaborator tries to use it, shallow modules force the reader to understand
the entire implementation before they can do anything. Deep modules let a reader
be productive after understanding only the interface.

### The depth test

For any module, ask: "Can someone use this module correctly by reading ONLY the
public function signatures and docstrings?" If yes, it's deep enough. If they need
to read the source code to understand how to call it, the interface is leaking.

---

## 2. Progressive Disclosure Layers

Progressive disclosure means organizing information so that readers encounter it
in order of importance, not in order of implementation.

### Three layers

**Layer 0 — What exists** (package `__init__.py`, README, top-level imports)

A new reader should be able to answer: "What does this package do? What are the
main entry points?" within 30 seconds. This layer contains:
- Curated exports in `__init__.py` (3-7 key symbols)
- Module-level docstring explaining the package purpose
- `__all__` defining the public API

**Layer 1 — How to use it** (public function signatures, docstrings, type hints)

A reader who wants to USE the package should find everything they need at this layer:
- Clear function names that describe behaviour
- Type hints that describe the contract
- Docstrings with parameters, returns, and one example
- Sensible defaults so common cases need minimal arguments

**Layer 2 — How it works** (function bodies, private methods, algorithms)

Only readers who need to modify or debug the code should need this layer:
- Algorithm implementation
- Internal data structures
- Error handling paths
- Performance optimizations

### The disclosure violation test

Pick any public function. Can you call it correctly after reading only its signature
and docstring (Layer 1)? If you need to read the function body (Layer 2) to figure
out valid inputs, the interface is leaking implementation details upward.

### Research-specific guidance

Research code often has a fourth layer:

**Layer 3 — Why this approach** (paper references, mathematical derivations)

This belongs in docstrings or separate documentation, NOT in variable names or
code structure. Don't name a variable `eq_14_from_smith_2023` — name it
`posterior_variance` and put the reference in the docstring.

---

## 3. Measuring Depth Ratio

### Formula

```
depth_ratio = impl_depth / interface_size
```

Where:

```
interface_size = (
    public_functions
    + public_classes
    + sum(public_methods_per_class)
    + public_constants
    + required_parameters_across_all_public_functions
)

impl_depth = (
    private_functions
    + private_methods
    + logic_lines  # excluding imports, blanks, docstrings
    + internal_data_structures
    + error_handling_branches
)
```

### Interpretation

| Depth Ratio | Rating | Interpretation |
|---|---|---|
| > 10 | 🟢 Deep | Significant complexity hidden. Reader only needs interface. |
| 5–10 | 🟡 Moderate | Some hiding. Could be deeper — check for leaked parameters. |
| 2–5 | 🟠 Shallow | Interface nearly as complex as implementation. Restructure. |
| < 2 | 🔴 Wrapper | Pass-through layer. Merge into caller or callee. |

### Calibration examples

**Deep (ratio ~15):** `pandas.read_csv(filepath)` — one function, dozens of
parameters with sensible defaults, hides CSV parsing, encoding detection, type
inference, chunked reading, memory mapping.

**Moderate (ratio ~7):** A `DataLoader` class with `load()`, `validate()`,
`transform()` — three public methods hiding file I/O, schema checking, and
normalization logic.

**Shallow (ratio ~2):** A `CSVReader` class that wraps `pandas.read_csv` with
methods `read()`, `set_encoding()`, `set_delimiter()`, `set_header()`,
`set_dtypes()`, `set_na_values()` — the interface is almost as complex as just
calling pandas directly.

**Wrapper (ratio ~1):** `def load_data(path): return pd.read_csv(path)` —
adds nothing.

---

## 4. `__init__.py` Patterns

### Good: Curated exports

```python
# mypackage/__init__.py
"""Market data analysis toolkit."""

from .loader import DataLoader
from .analysis import run_analysis
from .report import generate_report

__all__ = ["DataLoader", "run_analysis", "generate_report"]
```

Reader sees 3 entry points. They know what the package does. Rating: 🟢

### Acceptable: Empty with clear submodules

```python
# mypackage/__init__.py
"""Market data analysis toolkit.

Submodules:
    loader: Data loading and validation
    analysis: Statistical analysis functions
    report: Report generation
"""
```

Reader knows where to go next. Rating: 🟡

### Bad: Re-export everything

```python
# mypackage/__init__.py
from .loader import *
from .analysis import *
from .report import *
from .utils import *
from .config import *
```

Reader sees 40+ symbols with no guidance. Progressive disclosure destroyed. Rating: 🔴

### Bad: Logic in `__init__.py`

```python
# mypackage/__init__.py
import os
import json

_config = json.load(open(os.environ.get("CONFIG_PATH", "config.json")))
DATABASE_URL = _config["database_url"]

def setup():
    # 50 lines of initialization logic
    ...
```

Side effects on import. Logic hidden in unexpected place. Rating: 🔴

---

## 5. Anti-Pattern Catalogue

### PASS — Pass-Through Function

```python
# Bad: adds nothing
def fetch_prices(ticker, start_date, end_date):
    return api_client.get_prices(ticker, start_date, end_date)
```

Fix: Remove the wrapper. Let callers use `api_client.get_prices` directly. Or make
the wrapper earn its existence by adding retry logic, caching, or validation.

### SHAL — Shallow Class

```python
# Bad: public interface as complex as implementation
class DataProcessor:
    def set_input(self, data): self._data = data
    def set_config(self, config): self._config = config
    def validate(self): return len(self._data) > 0
    def process(self): return self._data * self._config["factor"]
    def get_result(self): return self._result
```

Fix: One deep function: `def process(data, factor=1.0) -> Result`

### LEAK — Leaky Abstraction

```python
# Bad: caller must know implementation uses numpy internally
def compute_returns(prices, axis=0, keepdims=False, dtype=np.float64):
    ...
```

Fix: Hide numpy-specific parameters. `def compute_returns(prices) -> pd.Series`

### FLAT — Flat Hierarchy

```
mypackage/
├── analysis.py          # 800 lines
├── backtest.py          # 600 lines
├── config.py            # 200 lines
├── data.py              # 500 lines
├── metrics.py           # 300 lines
├── optimize.py          # 400 lines
├── plot.py              # 350 lines
├── report.py            # 250 lines
├── signals.py           # 450 lines
├── strategies.py        # 700 lines
└── utils.py             # 500 lines
```

11 files at one level, 5000+ lines. No way to know where to start. Fix: Group
into subpackages by domain (data/, strategies/, reporting/).

### COGN — High Cognitive Load

```python
# Bad: 8 required parameters, all strings, order matters
def run_backtest(strategy, universe, start, end, benchmark,
                 rebalance, slippage_model, risk_model):
    ...
```

Fix: Config object with defaults. `def run_backtest(config: BacktestConfig)`
where BacktestConfig has sensible defaults for everything except strategy.

### INIT — Re-export Pollution

See `__init__.py` patterns above.

### SIGN — Missing Signposts

```python
# Bad: no docstring, no type hints, unclear name
def proc(d, n=5, m="ew"):
    x = d.rolling(n).mean() if m == "ew" else d.ewm(n).mean()
    return x / x.shift(1) - 1
```

Fix: Name it, type it, document it:
```python
def compute_rolling_returns(
    prices: pd.DataFrame,
    window: int = 5,
    method: Literal["simple", "exponential"] = "simple",
) -> pd.DataFrame:
    """Compute rolling returns using simple or exponential moving average.

    Args:
        prices: DataFrame with datetime index and asset columns.
        window: Lookback period in trading days.
        method: "simple" for SMA, "exponential" for EWM.

    Returns:
        DataFrame of period-over-period returns.
    """
```

---

## 6. Fix Patterns

When the review-depth skill identifies problems, these are the standard fix
directions. Each maps to specific refactoring actions.

### "Merge shallow modules"

When: Multiple modules with depth ratio < 2 that serve the same consumer.
Action: Combine into one module with a smaller public interface. The individual
modules become private functions within the merged module.

### "Deepen interface"

When: Module has high interface_size but moderate impl_depth.
Action: Add sensible defaults, combine related parameters into config objects,
hide implementation-specific parameters, use `**kwargs` for rare options.

### "Add disclosure layer"

When: Package has no curated `__init__.py` or flat structure.
Action: Create `__init__.py` with curated `__all__`. Group files into subpackages.
Add module-level docstrings.

### "Split god module"

When: Single module with both high interface_size AND high impl_depth (ratio
may look fine but absolute numbers are too large).
Action: Extract coherent subsets into separate modules. Each new module should
have a SMALLER interface than the original. If splitting doesn't reduce interface
size, don't split.

### "Add signposts"

When: Low signposting score (< 50% of public functions have docstrings + types).
Action: Add docstrings and type hints to all public functions. Start with the
most-imported functions (highest impact). Do NOT add signposts to private functions
first — that's Layer 2 work.

---

## 7. Golden Example

### Input

```
Review this codebase for deep module design and progressive disclosure.
```

Codebase: pricefeed (market data fetcher with fetchers/, validators/, cache/, cli/)

### Output (abbreviated)

## Module Census

| Module | Interface Size | Impl Depth | Depth Ratio | Rating |
|---|---|---|---|---|
| fetchers/ | 14 | 89 | 6.4 | 🟡 Moderate |
| validators/ | 9 | 62 | 6.9 | 🟡 Moderate |
| cache/ | 11 | 31 | 2.8 | 🟠 Shallow |
| cli/ | 4 | 47 | 11.8 | 🟢 Deep |

## Disclosure Audit

**Level 0 (package root):** `__init__.py` re-exports all 38 symbols from all
submodules. No guidance on where to start. Rating: 🔴

**Level 1 (interfaces):** fetchers/ has clear signatures. validators/ has no
docstrings on 6 of 9 public functions. cache/ leaks Redis-specific parameters
in public interface. Rating: 🟠

**Level 2 (implementation):** Appropriately hidden in fetchers/ and cli/.
Leaked in cache/ (caller must understand TTL eviction to set parameters). Rating: 🟡

## Findings

### DM-INIT-001: Root __init__.py re-exports everything
**Rating:** 🔴 **Type:** Init Problem **Location:** pricefeed/__init__.py
**Problem:** 38 symbols exported. New reader has no idea where to start.
**Fix direction:** Add disclosure layer — curate to 4-5 key exports.

### DM-SHAL-001: cache module is shallow
**Rating:** 🟠 **Type:** Shallow Module **Location:** cache/
**Depth ratio:** 2.8 (interface: 11, impl: 31)
**Problem:** 7 of 11 public functions expose Redis internals (TTL, key prefix,
serialization format).
**Fix direction:** Deepen interface — hide Redis behind 3 functions:
`get()`, `set()`, `invalidate()`.

### DM-SIGN-001: validators missing signposts
**Rating:** 🟠 **Type:** Missing Signposts **Location:** validators/
**Problem:** 6 of 9 public functions have no docstrings. Type hints on 3 of 9.
**Fix direction:** Add signposts — docstrings and type hints on all public functions.

### DM-LEAK-001: cache leaks Redis parameters
**Rating:** 🟠 **Type:** Leaky Abstraction **Location:** cache/store.py
**Problem:** `cache_result(key, value, ttl=300, prefix="pf:", serializer="json")`
exposes Redis implementation. Caller must know Redis to set these.
**Fix direction:** Deepen interface — defaults for all, hide serializer entirely.

## Scorecard

| Dimension | Score | Key Finding |
|---|---|---|
| Module Depth | 🟡 | cache/ is shallow (2.8), others moderate-to-deep |
| Progressive Disclosure | 🔴 | Root __init__.py exports all 38 symbols |
| Cognitive Load | 🟡 | cache/ requires understanding Redis internals |
| `__init__.py` Hygiene | 🔴 | Re-exports everything |
| Signposting | 🟠 | validators/ missing docstrings on 67% of public functions |

## Handoff

**Scorecard:**

| Dimension | Score | Key Finding |
|---|---|---|
| Module Depth | 🟡 | cache/ ratio 2.8 |
| Progressive Disclosure | 🔴 | 38 symbols at root |
| Cognitive Load | 🟡 | Redis knowledge required |
| `__init__.py` Hygiene | 🔴 | Re-exports all |
| Signposting | 🟠 | 67% undocumented in validators/ |

**Module Census:**

| Module | Interface Size | Impl Depth | Depth Ratio | Rating |
|---|---|---|---|---|
| fetchers/ | 14 | 89 | 6.4 | 🟡 |
| validators/ | 9 | 62 | 6.9 | 🟡 |
| cache/ | 11 | 31 | 2.8 | 🟠 |
| cli/ | 4 | 47 | 11.8 | 🟢 |

**Findings:**

- DM-INIT-001: Root re-exports all 38 symbols (🔴 Init) → Add disclosure layer
- DM-SHAL-001: cache/ depth ratio 2.8 (🟠 Shallow) → Deepen interface
- DM-SIGN-001: validators/ 67% undocumented (🟠 Signposts) → Add signposts
- DM-LEAK-001: cache/ leaks Redis params (🟠 Leak) → Deepen interface

**Contract Check:**
- All MUST fields present: YES
- No FORBIDDEN content in Handoff: YES
- Finding IDs follow DM-*-NNN format: YES
- Self-check result: PASS
