# Document Management Reference

## The Canonical Document Registry

These are the ONLY documents that exist in an SDLC-managed project. Creating documents outside this registry requires explicit justification.

```
docs/
  research/
    RESEARCH.md              ← Market, competitive, technical landscape
    GAP_ANALYSIS.md          ← Customer pain points, unmet needs, opportunities
    SYNTHESIS.md             ← Research + codebase combined analysis

  product/
    PRODUCT_SPEC.md          ← Requirements, BRs, NFRs, BDD, exceptions
    PRODUCT_SPEC_[DOMAIN].md ← Shard (only when domain section > 400 lines)
    CUSTOMER_JOURNEY.md      ← Personas, journey maps, screen flows
    BUSINESS_PROCESS.md      ← Back-office and operational processes

  data/
    DATA_MODEL.md            ← Canonical data model, ERDs, aggregates
    DATA_MODEL_[CONTEXT].md  ← Shard (only when context section > 300 lines)
    DATA_DICTIONARY.md       ← Every field: type, constraint, business meaning

  architecture/
    TECH_ARCHITECTURE.md     ← C4 diagrams, container design, patterns
    API_SPEC.md              ← Full OpenAPI 3.x specification
    SOLUTION_DESIGN.md       ← ADRs, design decisions

  qa/
    TEST_CASES.md            ← MECE GWT test cases with coverage matrix
    TEST_CASES_[LAYER].md    ← Shard (only when layer section > 500 lines)
    TEST_AUTOMATION.md       ← Automation index, framework guide, coverage report

  sre/
    OBSERVABILITY.md         ← Logging, tracing, metrics, config, health endpoints
    RUNBOOKS.md              ← Operational procedures
    RUNBOOK_[NAME].md        ← Shard (only when individual runbook > 100 lines)
    SLO.md                   ← Service Level Objectives, error budgets
    INCIDENT_RESPONSE.md     ← Severity classification, response process, post-mortem template

  review/
    REVIEW_REPORT.md         ← Cross-cutting quality review findings

.sdlc/
  STATE.md                   ← Project state, phase progress, document index
  TODO.md                    ← Active task list with statuses
  PLAN.md                    ← Execution plan with phases and dependencies
  DECISIONS.md               ← Architecture decision records (overflow from STATE.md)
```

---

## The Golden Rules

### 1. Update, Never Recreate
Before writing to any document:
- Read the ENTIRE existing document
- Identify which sections to update vs which to add
- Update existing sections in-place
- Add new sections with clear headers
- NEVER create PRODUCT_SPEC_v2.md or TECH_ARCHITECTURE_NEW.md

### 2. IDs Are Immutable
- REQ-IDs: numbered sequentially, never renumbered, only deprecated
- BR-IDs: same
- TC-IDs: same
- NFR-IDs: same
- ADR-IDs: same

Deprecation format (keep in document, never delete):
```
~~REQ-012~~: *Deprecated 2024-03-15 — replaced by REQ-023 (scope changed)*
```

### 3. Every Document Has Metadata
Required at the top of every document:
```
# Document Title
*Last Updated: [ISO date] | Version: [semver if applicable]*
```

### 4. Cross-References Over Duplication
If information belongs in Document A, reference it from Document B rather than copying:
```
*See docs/data/DATA_MODEL.md for entity definitions.*
```

### 5. Sharding Rules
Shard a document ONLY when:
- A single domain/layer section exceeds the threshold (see registry above)
- The shard is a standalone, coherent section (not arbitrary splitting)
- The parent document is updated to reference the shard

Shard headers:
```
# Test Cases — Integration Layer
*Shard of: docs/qa/TEST_CASES.md*
*Last Updated: [date]*
```

---

## Document Health Indicators

### Healthy Document
- Has "Last Updated" within 30 days (for active features)
- All sections complete (no `{{TODO}}` placeholders)
- All IDs sequential with no gaps
- Cross-references resolve to existing documents

### Stale Document
- Last updated > 30 days AND the feature is actively being developed
- Contains placeholder text like `{{TODO}}` or `[TBD]`
- References documents that no longer exist

### Orphaned Document
- Not in the canonical registry
- Not referenced from STATE.md document index
- No clear purpose distinct from a canonical document

---

## STATE.md Document Index

The document index in STATE.md is the source of truth for what documents exist:

```markdown
## Document Index
- [x] docs/research/RESEARCH.md         ← checked = exists
- [x] docs/data/DATA_MODEL.md           ← checked = exists
- [ ] docs/architecture/API_SPEC.md     ← unchecked = not yet created
```

Run `/sdlc:docs --index` to rebuild this index from actual filesystem state.

---

## Audit Frequency

Run `/sdlc:docs --audit` at the start of every new phase to ensure:
- No documents created outside the registry
- No orphaned or duplicate documents
- All active documents have recent "Last Updated" timestamps
- STATE.md document index is accurate
