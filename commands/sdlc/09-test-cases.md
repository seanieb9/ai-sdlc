---
name: sdlc:09-test-cases
description: Create and maintain MECE Given/When/Then test cases. Reads requirements, journeys, code, and API specs. Updates docs/qa/TEST_CASES.md. Never creates duplicates.
argument-hint: "<feature/area> [--layer <unit|integration|contract|e2e>] [--coverage-check] [--mece-check]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Design comprehensive, MECE test cases that provide complete traceability from every source artifact to test.

Reads (all required before writing any test cases):
  - docs/product/PRODUCT_SPEC.md — requirements (REQ-IDs), business rules (BR-IDs), NFRs (NFR-IDs)
  - docs/product/CUSTOMER_JOURNEY.md — user flows, failure journeys
  - docs/architecture/API_SPEC.md — API contracts for contract testing
  - docs/data/DATA_MODEL.md — data constraints, invariants
  - docs/architecture/TECH_ARCHITECTURE.md — ADRs (tech commitments to test), dependency classification
  - docs/architecture/SOLUTION_DESIGN.md — design decisions, pattern choices
  - docs/sre/OBSERVABILITY.md — observability commitments (OBS-IDs: logging, metrics, tracing)
  - Relevant source code — detect untested implementation paths

Outputs (update existing, never duplicate):
  - docs/qa/TEST_CASES.md — all test cases in structured format

Test case structure per case:
  - TC-XXX: Unique ID (never reuse, only deprecate)
  - Title: Concise description
  - Layer: Unit | Integration | Contract | E2E | Performance | Resilience | Observability | Security
  - Priority: P0 (critical) | P1 (high) | P2 (medium) | P3 (low)
  - Source: REQ-ID | BR-ID | NFR-ID | ADR-ID | API endpoint | OBS-ID (never "general" — always a specific source)
  - Given: Pre-conditions (system state, data setup)
  - When: The action(s) taken
  - Then: Expected outcomes (specific, measurable, all side effects)
  - Negative cases: What should NOT happen
  - Notes: Edge cases, known limitations

Test layers:
  - Unit: Domain entities, business rules, domain services
  - Integration: Repository methods, external adapters, DB queries
  - Contract: Every API endpoint (all status codes, all field validations)
  - E2E: Every happy path journey + top failure journeys
  - Performance: Every NFR with a numeric threshold (p95 latency, RPS, error rate)
  - Resilience: Every CRITICAL and DEGRADABLE dependency failure mode
  - Observability: Every OBS-ID commitment (log fields, metrics, trace propagation)
  - Security: Auth, authz, IDOR, input validation, sensitive data exposure

Coverage matrix requirements:
  Every REQ-ID → at least one P0/P1 test case
  Every BR-ID → unit test
  Every NFR-ID with numeric threshold → performance test
  Every API endpoint → contract test covering all status codes
  Every happy path → E2E test
  Every error code → negative test
  Every data invariant → unit test
  Every CRITICAL/DEGRADABLE dependency → resilience tests per failure mode
  Every OBS-ID → observability test
  Every API endpoint → security tests (auth + authz + input validation)

Spec divergence check before writing:
  If any source artifact contradicts another, flag divergence and ask user to resolve
  Do NOT write tests against a spec you suspect is stale

MECE check before finalizing:
  - No two test cases test the exact same thing (no overlaps)
  - Every source ID has test coverage (no gaps)
  - Every boundary condition is tested
  - TC-IDs are immutable — only deprecated, never deleted or renumbered

Continuous update rules:
  When PRODUCT_SPEC.md changes → update REQ/BR tests, add tests for new rules, deprecate tests for removed rules
  When API_SPEC.md changes → update contract tests for changed endpoints
  When TECH_ARCHITECTURE.md adds ADR → add resilience or integration test for the commitment
  When OBSERVABILITY.md adds OBS-ID → add observability test
  When source code adds untested path → add unit/integration test
</objective>

<context>
Feature/area: $ARGUMENTS

Flags:
  --layer <l>      Create test cases for specific layer only
  --coverage-check Audit existing test cases against requirements (no new cases)
  --mece-check     Analyze existing cases for gaps and overlaps
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/test-cases.md
@/Users/seanlew/.claude/sdlc/references/testing-standards.md
@/Users/seanlew/.claude/sdlc/references/resilience-patterns.md
@/Users/seanlew/.claude/sdlc/templates/test-cases.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>

