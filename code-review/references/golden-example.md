# Golden Example: code-review — pricefeed

Demonstrates a complete code-review output for a messy existing pricefeed
codebase (W2 Refactor, review phase). Exercises all MUST fields in the
BCS-1.0 contract.

---

## Scenario

**User prompt:** "Review the code in src/pricefeed/"

The existing pricefeed codebase has grown organically: circular imports between
fetchers and cache, a god module (`pipeline.py`), no type hints, duplicated
validation logic, and inconsistent error handling.

---

## Example Output

# Code Review Report

**Files reviewed:** `pipeline.py`, `fetchers.py`, `cache.py`, `validators.py`,
`config.py`
**Date:** 2025-03-15
**Overall health:** 🔴 Needs significant work

## Executive Summary

The pricefeed codebase has a working pipeline but suffers from tight coupling,
missing type annotations, and duplicated validation logic. The most critical
issue is the god function `pipeline.py:run_all()` at 380 lines, which handles
fetching, validation, caching, and CLI output in a single function. The
codebase also lacks protocols, making testing and source-swapping impossible
without modifying internals.

## Findings

### CR-BUG-001: Cache returns stale data when source fails silently
- **Severity:** 🔴 Critical
- **Pillar:** Correctness
- **Location:** `cache.py:L67-L72`

BEFORE:
```python
def get_price(ticker):
    if ticker in _cache:
        return _cache[ticker]
    return fetch_and_cache(ticker)  # silently returns None on failure
```

AFTER:
```python
def get_price(ticker: str) -> PriceRecord | None:
    cached = _cache.get(ticker)
    if cached is not None:
        return cached
    # Explicit: return None if not cached; fetching is caller's concern
    return None
```

WHY:
`fetch_and_cache` swallows `requests.ConnectionError` and returns `None`,
which the caller cannot distinguish from "ticker not cached." Violates
fail-fast principle.

---

### CR-SOLID-001: God function pipeline.py:run_all() (380 lines)
- **Severity:** 🟠 Major
- **Pillar:** SOLID (Single Responsibility)
- **Location:** `pipeline.py:L15-L395`

BEFORE:
```python
def run_all(config_path):
    # 380 lines: read config, fetch from CSV, fetch from API,
    # validate prices, update cache, print results, write log
    ...
```

AFTER:
```python
# Decompose into: fetch_prices(), validate_prices(), update_cache(),
# report_results() — each ≤30 lines, each independently testable
```

WHY:
Single function with 6+ responsibilities. Cannot test fetching without running
validation. Cannot add a new source without modifying this function.

---

### CR-TYPE-001: No type annotations on any public function
- **Severity:** 🟠 Major
- **Pillar:** Types
- **Location:** `pipeline.py:L15`, `fetchers.py:L8`, `cache.py:L12`,
  `validators.py:L5`

BEFORE:
```python
def fetch_prices(source, tickers):
    ...
def validate(records):
    ...
```

AFTER:
```python
def fetch_prices(source: str, tickers: list[str]) -> list[PriceRecord]:
    ...
def validate(records: list[PriceRecord]) -> list[PriceRecord]:
    ...
```

WHY:
Type annotations are required on all public functions (shared-principles.md).
Missing types make protocol extraction impossible and hide interface contracts.

---

### CR-DRY-001: Price range validation duplicated in two locations
- **Severity:** 🟡 Minor
- **Pillar:** DRY
- **Location:** `validators.py:L22-L30`, `pipeline.py:L180-L188`

BEFORE:
```python
# validators.py:L22
if record["price"] < 0 or record["price"] > 1000000:
    continue

# pipeline.py:L180
if p < 0 or p > 1_000_000:
    log.warning(f"Skipping {ticker}: price out of range")
```

AFTER:
```python
# Single validation function with configurable thresholds
```

WHY:
Same business rule (price range check) expressed in two places with slightly
different thresholds and error handling. If the range changes, both must be
updated — divergence risk.

## Summary Table

| Finding ID | Severity | Pillar | Location | Finding |
|---|---|---|---|---|
| CR-BUG-001 | 🔴 Critical | Correctness | `cache.py:L67-L72` | Cache returns stale data on silent fetch failure |
| CR-SOLID-001 | 🟠 Major | SOLID | `pipeline.py:L15-L395` | God function run_all() (380 lines, 6+ responsibilities) |
| CR-TYPE-001 | 🟠 Major | Types | Multiple files | No type annotations on any public function |
| CR-DRY-001 | 🟡 Minor | DRY | `validators.py:L22`, `pipeline.py:L180` | Price range validation duplicated |

## Positive Highlights

1. **Consistent naming**: Functions use clear verb phrases (`fetch_prices`,
   `validate`, `update_cache`) that describe their purpose.
2. **Logging present**: Every module uses `logging.getLogger(__name__)` — the
   infrastructure for structured logging is already in place.
3. **Config externalized**: Configuration is loaded from YAML, not hardcoded.

## Handoff

| Severity | Pillar | Location | Finding | Finding ID |
|---|---|---|---|---|
| 🔴 Critical | Correctness | `cache.py:L67-L72` | Cache returns stale data on silent fetch failure | CR-BUG-001 |
| 🟠 Major | SOLID | `pipeline.py:L15-L395` | God function run_all() (380 lines, 6+ responsibilities) | CR-SOLID-001 |
| 🟠 Major | Types | Multiple files | No type annotations on any public function | CR-TYPE-001 |
| 🟡 Minor | DRY | `validators.py:L22`, `pipeline.py:L180` | Price range validation duplicated | CR-DRY-001 |
