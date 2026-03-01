# Golden Example: ideate — pricefeed

Demonstrates a complete ideate output for the pricefeed project (W1 Build).
Exercises all MUST fields in the BCS-1.0 contract.

---

## Scenario

**User prompt:** "I need a system that fetches bond prices from multiple sources
(Bloomberg API, CSV files, maybe an internal REST API), validates them, caches
the latest values, and serves them to downstream consumers via a CLI and
eventually an API. Help me ideate — what are my options?"

---

## Example Output

### Mode Detection: Mode A (Open Exploration)

The user hasn't committed to an approach.

### Problem Frame

**Goal:** A single system that ingests bond prices from heterogeneous sources,
validates data quality, maintains a current cache, and serves consumers.

**Approach space:** How to structure the multi-source ingestion, validation,
caching, and serving layers.

### Candidate Approaches

**Approach 1: Plugin-based fetcher architecture**
- One-sentence: Each data source is an independent plugin conforming to a common
  protocol; an orchestrator polls them, validates, and updates a shared cache.
- Key architectural implication: The system is as extensible as adding a new
  `.py` file that implements the fetcher protocol.
- Primary risk: Plugin discovery and registration adds complexity.
- Extensibility outlook: Adding a new source is one file, zero changes to
  existing code. Excellent.

**Approach 2: ETL pipeline with stage-based processing**
- One-sentence: A linear pipeline (Extract → Transform → Load) where each stage
  is a function; sources are configuration, not code.
- Key architectural implication: Adding a source means adding config, not code —
  good for similar sources, bad if sources have fundamentally different APIs.
- Primary risk: If sources differ enough (streaming vs batch, push vs pull),
  forcing them into the same ETL shape creates leaky abstractions.
- Extensibility outlook: Easy for similar sources; painful for structurally
  different ones.

**Approach 3: Event-driven with message bus**
- One-sentence: Each source publishes price events to an internal bus;
  validators subscribe to raw events, cache subscribes to validated events.
- Key architectural implication: Decoupled and scalable, but introduces
  infrastructure complexity (message bus, event schemas, ordering guarantees).
- Primary risk: Over-engineering for a system that starts with 2-3 sources and
  a CLI consumer.
- Extensibility outlook: Handles heterogeneous sources well but at the cost of
  operational complexity.

### Comparison Matrix

| Dimension | Plugin-based | ETL pipeline | Event-driven |
|---|---|---|---|
| Complexity | Low-moderate | Low | High |
| Extensibility | Excellent | Good for similar sources | Excellent |
| Testability | High (mock protocol) | Moderate | Moderate |
| Time-to-first-result | Fast | Fastest | Slow |
| Alignment with existing patterns | Good (Protocol-based) | Fair | Poor |

### Recommendation

Plugin-based fetcher architecture. It matches the heterogeneous source
requirement without over-engineering. Protocol-based design fits your
conventions. You can always layer event-driven on top later if scale demands it.

### Stress-Test (Mode B elements applied to recommended approach)

**Assumption audit:**
- Data sources return data in compatible schemas → **load-bearing** (if
  Bloomberg returns different fields than CSV, the protocol must be flexible
  enough)
- Cache fits in memory → cosmetic for now (can swap to Redis later behind a
  protocol)
- Validation rules are consistent across sources → **load-bearing** (if
  Bloomberg prices need different validation than CSV historical prices, a
  single validator protocol may not suffice)

**Inversion — how could this fail?**
- Source-specific validation logic bleeds into the validator, coupling it to
  each source → defence: validator takes validated/enriched data, not raw
  source-specific formats. Fetchers normalise before handoff.
- Cache coherence across sources — two sources disagree on the same bond's
  price → no defence currently. Need a conflict resolution policy.

**Second-order consequences:**
- Choosing Protocol-based fetchers means downstream consumers never know *which*
  source provided a price. If attribution matters, the data model needs a
  `source` field from day one.

### Decision Summary

- **Chosen approach**: Plugin-based fetcher architecture with a common
  PriceFetcher protocol
- **Key trade-off accepted**: Plugin discovery adds minor complexity vs
  monolithic simplicity
- **Load-bearing assumptions**: All sources can normalise to a common price
  schema; validation rules are source-agnostic
- **First thing to build**: The PriceFetcher protocol and one concrete
  implementation (CSV) to validate the interface design
- **Extensibility vector**: Adding a new data source (most likely change) is one
  file implementing the protocol, zero changes to existing code

## Handoff

Chosen approach: Plugin-based fetcher architecture where each data source
implements a PriceFetcher protocol; an orchestrator polls registered fetchers,
validates results against quality rules, updates an in-memory cache, and serves
current prices via CLI.

Load-bearing assumptions:
- All data sources can normalise their output to a common PriceRecord schema
  (ticker, price, timestamp, source)
- Validation rules are source-agnostic (apply uniformly regardless of origin)
- Cache fits in memory for the current scale (~10K instruments)
- Downstream consumers don't need to know which source provided a given price

Key trade-off accepted: Plugin registration adds minor complexity compared to
hardcoded source list, but enables adding sources without modifying existing
code.

First thing to build: The PriceFetcher protocol and a CsvFetcher implementation
to validate the interface design before adding more sources.
