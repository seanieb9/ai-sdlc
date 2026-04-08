# Document Writing Standards

The goal: every document must be readable by a human in under 5 minutes AND answerable by AI using the minimum possible tokens. These two goals are the same — dense, well-structured, scannable content serves both.

---

## The 50-Line Rule

**Structure every document so that Claude can orient itself in the first 50 lines.**

The first 50 lines of any document must contain:
1. Title and last-updated date
2. A TL;DR summary (3–5 bullet points — what this document contains, what decisions it records, what is in scope)
3. A section index (what headings exist and what line/anchor they're at)
4. Any critical constraints or gates that apply

If Claude can read the first 50 lines and know exactly which section to jump to next, the whole document does not need to be loaded. This is the single most effective token-cost control.

**Template — every document top:**
```markdown
# [Document Title]
*Last Updated: [ISO date] | Phase: [N] | Status: [DRAFT | ACTIVE | SUPERSEDED]*

## TL;DR
- [What this document defines]
- [Key decisions recorded here]
- [What is explicitly out of scope]
- [What changed since last update — one line]

## Contents
- [Section 1](#section-1) — [one-line description]
- [Section 2](#section-2) — [one-line description]
- [Section 3](#section-3) — [one-line description]
```

---

## Tables Over Prose

Structured data in prose form forces full reading. Tables allow scanning.

**Reject this:**
```
The order entity has an id field which is a UUID, a status field which is an
enum that can be PENDING, CONFIRMED, SHIPPED, or CANCELLED, a created_at
timestamp that is always UTC, and a customer_id foreign key.
```

**Require this:**
```markdown
| Field        | Type      | Constraint        | Notes                    |
|-------------|-----------|-------------------|--------------------------|
| id           | UUID v4   | PK, immutable     | System-generated         |
| status       | ENUM      | NOT NULL          | PENDING→CONFIRMED→SHIPPED→CANCELLED |
| created_at   | TIMESTAMP | UTC, immutable    | Set on create            |
| customer_id  | UUID FK   | NOT NULL          | → customers.id           |
```

The table version conveys identical information in ~40% of the tokens and is scannable in 3 seconds by a human.

**Use tables for:**
- Entity fields
- Requirements lists
- Test case matrices
- Decision records
- Error code tables
- Dependency classifications
- Coverage gates

---

## IDs at the Front

IDs are how Claude and humans navigate between documents. They must be findable by a single grep.

**Reject this:**
```
The system should allow users to create an order after they have authenticated.
This is a functional requirement with high priority. [REQ-001]
```

**Require this:**
```
REQ-001 [MUST] Users can create an order after authenticating.
```

**Format rules:**
- ID always first on the line
- Priority/classification in brackets immediately after
- Statement in plain imperative language
- No prose wrapping

This makes every requirement grep-able:
```bash
grep "REQ-" docs/product/PRODUCT_SPEC.md   # find all requirements
grep "BR-0" docs/product/PRODUCT_SPEC.md   # find a specific rule
grep "TC-042" docs/qa/TEST_CASES.md        # jump to a specific test
```

---

## Section Granularity

Sections should be sized so that Claude can load one section to answer one question.

**Too coarse (forces full read):**
```
## Requirements
[200 lines of mixed functional, non-functional, business rules]
```

**Correct granularity:**
```
## Functional Requirements
## Non-Functional Requirements
## Business Rules
## Exception Handling
```

Each section should be independently loadable and independently answerable. A section answers one question: "what are the functional requirements?" — not "what is everything about this spec?"

**Section size targets:**
| Document type | Ideal section size | Max before split |
|--------------|-------------------|-----------------|
| Product spec | 30–80 lines | 120 lines |
| Data model | 20–60 lines per entity | 100 lines |
| Test cases | 15–40 lines per scenario group | 80 lines |
| Architecture | 40–100 lines per concern | 150 lines |
| Runbooks | 20–50 lines per procedure | 80 lines |

---

## No Padding

Every line must carry information. Remove:

| Pattern | Example | Replace with |
|---------|---------|-------------|
| Throat-clearing | "This section describes the requirements for..." | Delete — the heading already says that |
| Restatement | "As mentioned above, the order entity has an id field" | Delete — reference the section |
| Hedging | "It may be worth considering whether..." | State the decision or don't include it |
| Obvious notes | "Note: this field is required" | Put it in the constraint column |
| Future vagueness | "TBD", "to be determined", "will be defined later" | Leave the section out until it's known |

**Target token density:** every paragraph should be removable only by losing information. If you can delete a sentence and lose nothing — delete it.

---

## Sharding for Partial Loading

Sharding is not just about line count — it's about creating independently loadable units.

**A shard must be:**
- Self-contained (readable without the parent document)
- Named to be discoverable by grep (`TEST_CASES_INTEGRATION.md` not `TEST_CASES_PART2.md`)
- Referenced from the parent with an explicit pointer

**Parent document shard pointer:**
```markdown
## Integration Tests
*Full content in: docs/qa/TEST_CASES_INTEGRATION.md*
*Summary: 23 test cases covering repository methods and external adapters.*
*Last synced: [date]*
```

The parent keeps a one-line summary of each shard. Claude reads the parent's summary to decide whether to load the shard — not the shard itself.

**Shard header (required):**
```markdown
# [Title] — [Layer/Domain]
*Shard of: [parent document path]*
*Contains: [one-line description of what's in this shard]*
*Last Updated: [date]*
```

---

## Cross-Reference Syntax

Cross-references must be machine-readable as well as human-readable.

**Standard format:**
```
→ docs/data/DATA_MODEL.md#order-entity
→ REQ-012
→ BR-004
→ TC-031
→ ADR-007
```

Always use `→` as the reference marker — it's grep-able and visually distinct.

```bash
grep "→ REQ-" docs/qa/TEST_CASES.md     # find all requirement references in tests
grep "→ ADR-" docs/architecture/        # find all ADR references
```

---

## Change History

Every document that can change (requirements, data model, architecture decisions) must maintain a change log at the bottom.

**Format:**
```markdown
## Change History
| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2024-03-15 | REQ-012 deprecated | Scope cut for v1 | TC-031, TC-032 marked skip |
| 2024-03-10 | NFR-003 threshold updated 200ms→150ms | Load test results | Perf tests need rerun |
```

Rules:
- Newest entry at the top
- Every change that affects a downstream document is noted in Impact
- Never delete history — it explains why the document is in its current state

---

## Document Complexity Budget

Every document has a complexity budget. When it exceeds budget, shard or cut.

| Document | Complexity budget |
|----------|------------------|
| PRODUCT_SPEC.md | Max 5 domain sections. Shard at 400 lines. |
| DATA_MODEL.md | Max 8 bounded contexts. Shard each context > 300 lines. |
| TEST_CASES.md | Max 4 layers per file. Shard each layer > 500 lines. |
| TECH_ARCHITECTURE.md | Max 6 architectural concerns. |
| API_SPEC.md | Max 20 endpoints per file. Shard by domain > 20 endpoints. |
| RUNBOOKS.md | Max 10 runbooks per file. Shard each runbook > 100 lines. |
| OBSERVABILITY.md | Single file. No sharding — must be read whole for audit. |

When a document approaches its budget: stop, shard, update the parent index, update state.json artifacts list.

---

## AI Readability Checklist

Before marking any document as complete, verify:

- [ ] First 50 lines contain TL;DR + Contents index
- [ ] All structured data is in tables, not prose
- [ ] All IDs are at the start of their line (grep-able)
- [ ] Each section answers exactly one question
- [ ] No padding — every sentence carries information
- [ ] All shards have self-contained headers and are referenced from parent
- [ ] All cross-references use `→` marker
- [ ] Change history updated if anything changed
- [ ] Complexity budget not exceeded
