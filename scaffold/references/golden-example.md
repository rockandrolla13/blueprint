# Golden Example: scaffold — pricefeed

Demonstrates a complete scaffold output for the pricefeed project (W1 Build).
Terminal skill — no Handoff section. Shows generated files with TODO markers.

---

## Scenario

**Upstream:** design Handoff specifying file structure, protocols, and config.

---

## Example Output

### Step 1: Pattern Identified

Project Template — new project from scratch.

### Step 2: Parameters

- **Name:** pricefeed
- **Purpose:** Fetch bond prices from multiple sources, validate, cache, serve
  via CLI
- **Dependencies:** click, pydantic, pyyaml
- **Parallelism:** Not initially — sources are few, sequential is fine

### Step 3: Generated Files

#### `src/pricefeed/__init__.py`

```python
"""Pricefeed: multi-source bond price aggregation and serving."""
```

#### `src/pricefeed/core/__init__.py`

```python
"""Core domain types and protocols."""
```

#### `src/pricefeed/core/types.py`

```python
"""Domain types, protocols, and configuration for pricefeed."""
from typing import Protocol
from datetime import datetime
from dataclasses import dataclass
from pathlib import Path

from pydantic import BaseModel


# --- Domain Types ---

@dataclass(frozen=True)
class PriceRecord:
    """A single validated price observation."""
    ticker: str
    price: float
    timestamp: datetime
    source: str


# --- Protocols ---

class PriceFetcher(Protocol):
    """Contract for any price data source."""
    def fetch(self, tickers: list[str]) -> list[PriceRecord]: ...


class Validator(Protocol):
    """Contract for price quality validation."""
    def validate(self, records: list[PriceRecord]) -> list[PriceRecord]: ...


# --- Configuration ---

class SourceConfig(BaseModel):
    """Configuration for a single data source."""
    name: str
    type: str
    path_or_url: str
    enabled: bool = True


class ValidationConfig(BaseModel):
    """Validation thresholds."""
    min_price: float = 0.0
    max_price: float = 1_000_000.0
    max_age_seconds: int = 3600


class AppConfig(BaseModel):
    """Top-level application configuration."""
    sources: list[SourceConfig]
    validation: ValidationConfig = ValidationConfig()
    cache_size: int = 50_000
    log_level: str = "INFO"
```

#### `src/pricefeed/fetchers/__init__.py`

```python
"""Price fetcher implementations."""
```

#### `src/pricefeed/fetchers/csv_fetcher.py`

```python
"""Fetch prices from CSV files."""
import logging
from datetime import datetime
from pathlib import Path

from pricefeed.core.types import PriceFetcher, PriceRecord

logger = logging.getLogger(__name__)


class CsvFetcher:
    """Fetches price records from a CSV file.

    Implements PriceFetcher protocol.
    """

    def __init__(self, file_path: Path) -> None:
        self.file_path = file_path

    def fetch(self, tickers: list[str]) -> list[PriceRecord]:
        """Read prices from CSV, filtering to requested tickers.

        Expected CSV columns: ticker, price, timestamp
        """
        # TODO: implement CSV reading and PriceRecord construction
        # Parse CSV rows, filter to requested tickers, return PriceRecord list
        raise NotImplementedError
```

#### `src/pricefeed/fetchers/api_fetcher.py`

```python
"""Fetch prices from an external API."""
import logging
from pricefeed.core.types import PriceFetcher, PriceRecord

logger = logging.getLogger(__name__)


class ApiFetcher:
    """Fetches price records from an external REST API.

    Implements PriceFetcher protocol.
    """

    def __init__(self, base_url: str, api_key: str | None = None) -> None:
        self.base_url = base_url
        self.api_key = api_key

    def fetch(self, tickers: list[str]) -> list[PriceRecord]:
        """Call API endpoint and return price records.

        Raises FetchError on network or schema failures.
        """
        # TODO: implement API call, response parsing, PriceRecord construction
        # Handle authentication, rate limiting, and response validation
        raise NotImplementedError
```

#### `src/pricefeed/validators/__init__.py`

```python
"""Price validation implementations."""
```

#### `src/pricefeed/validators/range.py`

```python
"""Range-based price validation."""
import logging
from pricefeed.core.types import Validator, PriceRecord, ValidationConfig

logger = logging.getLogger(__name__)


class RangeValidator:
    """Validates prices fall within configured min/max range.

    Implements Validator protocol.
    """

    def __init__(self, config: ValidationConfig) -> None:
        self.config = config

    def validate(self, records: list[PriceRecord]) -> list[PriceRecord]:
        """Filter records to those within valid price range.

        Logs discarded records at DEBUG level.
        """
        # TODO: implement range validation logic
        # Check each record's price against config.min_price and config.max_price
        # Check timestamp age against config.max_age_seconds
        # Return only valid records, log discards
        raise NotImplementedError
```

#### `src/pricefeed/cache/__init__.py`

```python
"""Price caching layer."""
```

#### `src/pricefeed/cache/store.py`

```python
"""In-memory price cache."""
import logging
from pricefeed.core.types import PriceRecord

logger = logging.getLogger(__name__)


class PriceCache:
    """In-memory cache holding latest validated price per ticker."""

    def __init__(self, max_size: int = 50_000) -> None:
        self._prices: dict[str, PriceRecord] = {}
        self._max_size = max_size

    def update(self, records: list[PriceRecord]) -> int:
        """Update cache with new records. Returns count of updates."""
        # TODO: implement cache update logic
        # For each record, store if newer than existing entry for that ticker
        # Respect max_size (eviction policy: oldest timestamp)
        raise NotImplementedError

    def get(self, ticker: str) -> PriceRecord | None:
        """Get latest price for a ticker, or None if not cached."""
        return self._prices.get(ticker)

    def all_tickers(self) -> list[str]:
        """Return all cached ticker symbols."""
        return list(self._prices.keys())
```

#### `src/pricefeed/cli/__init__.py`

```python
"""CLI entry points."""
```

#### `src/pricefeed/cli/main.py`

```python
"""CLI entry point for pricefeed."""
import logging
import click
import yaml
from pathlib import Path

from pricefeed.core.types import AppConfig

logger = logging.getLogger(__name__)


@click.group()
@click.option("--config", type=click.Path(exists=True), default="config/default.yaml")
@click.pass_context
def cli(ctx: click.Context, config: str) -> None:
    """Pricefeed: multi-source bond price aggregation."""
    with open(config) as f:
        raw = yaml.safe_load(f)
    ctx.ensure_object(dict)
    ctx.obj["config"] = AppConfig(**raw)
    logging.basicConfig(level=ctx.obj["config"].log_level)


@cli.command()
@click.pass_context
def fetch(ctx: click.Context) -> None:
    """Fetch prices from all configured sources."""
    # TODO: wire fetchers → validator → cache using ctx.obj["config"]
    # Instantiate fetchers based on config.sources
    # Run orchestration: fetch → validate → cache.update
    click.echo("Fetching prices...")


@cli.command()
@click.argument("ticker")
@click.pass_context
def price(ctx: click.Context, ticker: str) -> None:
    """Get latest price for a ticker."""
    # TODO: look up ticker in cache, display result
    click.echo(f"Looking up {ticker}...")


if __name__ == "__main__":
    cli()
```

#### `tests/conftest.py`

```python
"""Shared test fixtures for pricefeed."""
import pytest
from datetime import datetime
from pricefeed.core.types import PriceRecord, ValidationConfig


@pytest.fixture
def sample_records() -> list[PriceRecord]:
    """A small set of valid price records for testing."""
    now = datetime.now()
    return [
        PriceRecord(ticker="AAPL", price=150.0, timestamp=now, source="test"),
        PriceRecord(ticker="MSFT", price=380.0, timestamp=now, source="test"),
        PriceRecord(ticker="GOOG", price=140.0, timestamp=now, source="test"),
    ]


@pytest.fixture
def default_validation_config() -> ValidationConfig:
    return ValidationConfig()
```

#### `tests/unit/test_types.py`

```python
"""Smoke tests for core types."""
from datetime import datetime
from pricefeed.core.types import PriceRecord, AppConfig, SourceConfig


def test_price_record_construction():
    record = PriceRecord(
        ticker="AAPL",
        price=150.0,
        timestamp=datetime(2025, 1, 1),
        source="csv",
    )
    assert record.ticker == "AAPL"
    assert record.price == 150.0


def test_app_config_defaults():
    config = AppConfig(sources=[
        SourceConfig(name="test", type="csv", path_or_url="/tmp/test.csv"),
    ])
    assert config.cache_size == 50_000
    assert config.validation.min_price == 0.0
```

#### `tests/unit/test_range_validator.py`

```python
"""Tests for RangeValidator."""
from pricefeed.validators.range import RangeValidator
from pricefeed.core.types import ValidationConfig


def test_range_validator_import():
    """Smoke test: module imports and class instantiates."""
    config = ValidationConfig(min_price=0.0, max_price=1000.0)
    validator = RangeValidator(config)
    assert validator.config.max_price == 1000.0
```

#### `tests/unit/test_cache.py`

```python
"""Tests for PriceCache."""
from pricefeed.cache.store import PriceCache


def test_cache_import():
    """Smoke test: module imports and class instantiates."""
    cache = PriceCache(max_size=100)
    assert cache.get("NONEXISTENT") is None
    assert cache.all_tickers() == []
```

#### `tests/integration/test_orchestrator.py`

```python
"""Integration test: orchestrator wires fetcher → validator → cache."""
from pricefeed.core.types import PriceRecord, ValidationConfig
from pricefeed.cache.store import PriceCache
from pricefeed.validators.range import RangeValidator


def test_smoke_import_all_modules():
    """Verify all modules import without error."""
    import pricefeed.core.types
    import pricefeed.fetchers.csv_fetcher
    import pricefeed.fetchers.api_fetcher
    import pricefeed.validators.range
    import pricefeed.cache.store
    import pricefeed.cli.main
```

#### `config/default.yaml`

```yaml
sources:
  - name: local-csv
    type: csv
    path_or_url: data/prices.csv
    enabled: true

validation:
  min_price: 0.0
  max_price: 1000000.0
  max_age_seconds: 3600

cache_size: 50000
log_level: INFO
```

#### `pyproject.toml`

```toml
[project]
name = "pricefeed"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["click", "pydantic", "pyyaml"]

[project.optional-dependencies]
dev = ["pytest", "hypothesis", "ruff"]

[project.scripts]
pricefeed = "pricefeed.cli.main:cli"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### Step 4: Verification

All files created. Structure matches design Handoff exactly:
- Protocols copied verbatim from design
- Config models copied verbatim from design
- Every non-trivial function body has a TODO comment
- Smoke tests import all modules without error
- Integration test verifies all modules importable

No `## Handoff` — scaffold is a terminal skill.
