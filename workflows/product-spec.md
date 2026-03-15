# Product Spec Workflow

Create or update the product specification — the authoritative source of truth for what the system must do.

## Step 1: Pre-Flight

Read in parallel:
- `docs/product/PRODUCT_SPEC.md` — existing spec (critical: read ALL before changing ANYTHING)
- `docs/research/RESEARCH.md` — market context
- `docs/research/GAP_ANALYSIS.md` — customer needs
- `docs/research/SYNTHESIS.md` — synthesis insights (if exists)
- `docs/product/CUSTOMER_JOURNEY.md` — journeys (if exists)
- `.sdlc/STATE.md` — project context and constraints

If PRODUCT_SPEC.md exists: identify which sections need updating vs which are new. Never overwrite a section without reading it first.

If neither research doc exists: warn the user. The spec will be weaker without research grounding. Offer to proceed anyway or run research first.

## Step 2: Clarify Requirements

Ask the user (via AskUserQuestion) if key information is missing:
1. "Who are the primary users of this feature/system?"
2. "What is the core business problem being solved?"
3. "What are the must-have requirements vs nice-to-have?"
4. "Are there any regulatory, compliance, or security requirements?"
5. "What does success look like? How will we measure it?"

Only ask questions that can't be derived from existing documents.

## Step 3: Define Requirements

**Structure requirements using MoSCoW:**
- MUST: Non-negotiable. System fails without this.
- SHOULD: High value, include if feasible.
- COULD: Nice to have, deprioritized.
- WON'T: Explicitly out of scope.

**Requirement format:**
```
REQ-[NNN]: [Clear, testable statement of requirement]
  Priority: MUST | SHOULD | COULD
  Rationale: [Why this requirement exists — business driver]
  Source: [GAP_ANALYSIS.md | business | compliance | technical]
  Acceptance: [How we verify this is met — specific and measurable]
```

Requirements are NUMBERED and PERMANENT. Once assigned, a REQ-ID is never reused or renumbered. Only DEPRECATED (with reason and date).

## Step 4: Define Business Rules

Business rules are the invariants of the domain — things that are always true:

```
BR-[NNN]: [Declarative statement of the rule]
  Example: "An order total must be greater than zero"
  Example: "A user cannot place more than 10 orders per hour"
  Rationale: [Why this rule exists]
  Exception handling: [What happens when this rule is violated]
  Related requirements: REQ-[NNN]
```

Rules:
- State rules positively where possible
- Include EVERY exception case — what happens when the rule is violated
- Business rules directly generate unit test cases

## Step 5: Define Exception Handling

For every flow, define what happens when things go wrong:

```
EH-[NNN]: [Scenario/trigger]
  Trigger: [What causes this exception state]
  Expected behavior: [What the system should do]
  User message: [What the user should see — clear, not technical]
  Error code: [Machine-readable code for API consumers]
  Recovery path: [Can the user recover? How?]
  Logging level: ERROR | WARN
  Alert: [Should this trigger an alert?]
```

Cover:
- Validation failures (bad input)
- Authorization failures
- Not found cases
- Conflict cases (duplicate, concurrent modification)
- External service failures
- Timeout scenarios
- Rate limit exceeded

## Step 6: Write BDD Scenarios

For every significant flow (happy path + key failure paths):

```
SCENARIO: [Descriptive title]
  Priority: P0 | P1 | P2
  Requirement: REQ-[NNN]

  Given [system state / precondition]
    And [additional precondition]
  When [action taken by user or system]
    And [additional action]
  Then [expected observable outcome]
    And [secondary outcome]
    And [state that should persist]

  Business Rule: BR-[NNN]
```

These scenarios:
- Drive E2E test cases directly
- Are written from the user/business perspective (not technical)
- Include the failure path scenarios for error handling

## Step 7: API Contracts (High Level)

Before tech arch, document high-level API intent:

For each functional area, describe (non-technical):
- What operations are needed (create, read, update, delete, search, etc.)
- Who calls them (which personas, which systems)
- What data goes in and comes out (in business terms, not technical)
- What constraints apply (rate limiting, authorization)

These are refined into full OpenAPI spec by /sdlc:06-tech-arch.

## Step 8: Non-Functional Requirements

Document all NFRs:
```
NFR-[NNN]: [Category]: [Requirement]
  Category: Performance | Security | Availability | Scalability | Usability | Compliance
  Measurement: [How to measure — specific metric and threshold]
  Example: "NFR-001: Performance: API p99 response time < 500ms under 1000 concurrent users"
  Example: "NFR-002: Security: All PII encrypted at rest using AES-256"
  Example: "NFR-003: Availability: 99.9% uptime per month"
```

## Step 9: Write Output Document

**Update docs/product/PRODUCT_SPEC.md:**

```markdown
# Product Specification: [Name]
*Last Updated: [date] | Version: [semver]*

## 1. Overview
### Purpose
### Scope
### Out of Scope
### Success Metrics

## 2. Personas and Roles
[From CUSTOMER_JOURNEY.md — reference or inline]

## 3. Business Rules
[BR-001 through BR-NNN]

## 4. Functional Requirements
### MUST
### SHOULD
### COULD
### WON'T (explicitly out of scope)

## 5. Non-Functional Requirements
[NFR-001 through NFR-NNN]

## 6. Exception Handling
[EH-001 through EH-NNN]

## 7. BDD Scenarios
### [Feature Area]
[Scenarios]

## 8. API Intent (High Level)
[Pre-architecture API needs]

## 9. Acceptance Criteria
[Linked to requirements — overall done criteria]

## 10. Open Questions
[Questions still needing answers — remove when resolved]

## Deprecated Requirements
[REQ-IDs deprecated with reason — never delete]
```

Sharding: if a domain section exceeds 400 lines, create `PRODUCT_SPEC_[DOMAIN].md` and reference it from the main doc.

## Step 10: Update State

Mark Phase 3 (Product Spec) complete.

Output:
```
✅ Product Spec Complete

Requirements: [N] (MUST: [N], SHOULD: [N], COULD: [N])
Business Rules: [N]
BDD Scenarios: [N]
Exception Cases: [N]
NFRs: [N]

File: docs/product/PRODUCT_SPEC.md

Recommended Next: /sdlc:04-customer-journey
```
