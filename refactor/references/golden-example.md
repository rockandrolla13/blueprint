# Golden Example: refactor — pricefeed

Demonstrates a complete refactor output for one step of the pricefeed
refactoring plan (W2 Refactor, execution phase). Terminal skill — no
Handoff section.

---

## Scenario

**Upstream:** refactoring-plan Handoff, Step 1.1 (Break circular dependency).
PLAN-refactor-pricefeed.md exists with all steps PENDING.

---

## Example Output

### Phase 1: Understand Before Touching

**What does it do?** Pricefeed fetches bond prices from CSV and API sources,
validates them, caches in memory, and serves via CLI.

**Entry points:** `python -m pricefeed.pipeline` (runs `run_all()`)

**Data flow:** Config → fetch from sources → validate → update cache → print
results

**Existing tests:** None.

### Phase 2: Executing Step 1.1

**Plan status update:** Step 1.1 → `IN PROGRESS`

#### Step 1.1: Break circular dependency between fetchers.py and cache.py

**Finding:** AR-DEP-001

**Before state:**
```
fetchers.py:L3  →  from pricefeed.cache import update_cache
cache.py:L5     →  from pricefeed.fetchers import fetch_prices
```

**Changes made:**

1. Created `core/__init__.py` and `core/types.py`:

```python
"""Domain types for pricefeed."""
from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class PriceRecord:
    """A single price observation."""
    ticker: str
    price: float
    timestamp: datetime
    source: str
```

2. Updated `fetchers.py`:
   - Removed `from pricefeed.cache import update_cache`
   - Added `from pricefeed.core.types import PriceRecord`
   - `fetch_prices()` now returns `list[PriceRecord]` instead of calling
     `update_cache()` directly

3. Updated `cache.py`:
   - Removed `from pricefeed.fetchers import fetch_prices`
   - Added `from pricefeed.core.types import PriceRecord`
   - `get_price()` now returns `None` on cache miss (no fetch fallback)
   - `update_cache()` accepts `list[PriceRecord]`

4. Updated `pipeline.py`:
   - Added explicit wiring: `records = fetch_prices(...)` then
     `update_cache(records)` — orchestrator owns the flow

**Verification:**
- [x] Pipeline runs without error (same output as before)
- [x] `python -c "import pricefeed.fetchers"` succeeds without importing cache
- [x] `python -c "import pricefeed.cache"` succeeds without importing fetchers
- [x] No circular import warnings

**Plan status update:** Step 1.1 → `DONE`

**Execution Log entry:**
```
2025-03-15T10:30:00 | Step 1.1 | DONE | Created core/types.py with PriceRecord.
  Removed circular imports between fetchers.py and cache.py. Pipeline
  orchestrator now owns fetch→cache wiring.
```

### Refactoring Summary (Step 1.1 only)

- **Changes made**: Created `core/types.py`, removed circular imports between
  `fetchers.py` and `cache.py`, moved orchestration responsibility to
  `pipeline.py`
- **Behaviour preserved**: Pipeline produces identical output
- **New tests added**: None (Step 3.1 covers this)
- **Extensibility improved**: Fetchers and cache can now be tested and replaced
  independently
- **Remaining debt**: God function (Step 2.1), no protocols (Step 2.2), no
  tests (Step 3.1) — all tracked in PLAN-refactor-pricefeed.md

No `## Handoff` — refactor is a terminal skill.
