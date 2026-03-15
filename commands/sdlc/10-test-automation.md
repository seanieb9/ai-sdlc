---
name: sdlc:10-test-automation
description: Generate and maintain automated test scripts based strictly on TEST_CASES.md. Updates existing scripts, never creates duplicates. Follows contract testing for APIs.
argument-hint: "<feature/area> [--framework <name>] [--layer <unit|integration|contract|e2e>] [--update-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - WebFetch
---

<objective>
Implement automated test scripts derived directly from TEST_CASES.md. Test cases drive scripts — not the other way around.

Gate: docs/qa/TEST_CASES.md must exist and be current before running this command.

Process:
  1. Read TEST_CASES.md in full — build TC-ID to layer mapping
  2. Read existing test files to update, not recreate
  3. Read source code being tested to understand actual behavior
  4. Read API_SPEC.md for contract tests
  5. Build TC-ID to automation file map before writing any scripts
  6. Generate/update test scripts maintaining 1:1 TC-ID mapping per test
  7. Run automation completeness audit: every TC-ID → automation; every automation → TC-ID
  8. Run drift detection: verify no contract schema drift, method signature drift, or deprecated requirements
  9. Update docs/qa/TEST_AUTOMATION.md index with gaps table

Test layers covered:
  - Unit: Jest/pytest/JUnit — domain entities, business rules
  - Integration: Test containers — repositories, adapters, DB queries
  - Contract: Supertest/Pact — all API endpoints against API_SPEC.md
  - E2E: Playwright/Cypress — full user journeys
  - Performance: k6 — NFR thresholds (p95 latency, RPS, error rate)
  - Resilience: Integration tests with Toxiproxy/mock servers — circuit breaker, fallback, timeout behavior
  - Observability: Log capture assertions, metric scrape assertions, trace propagation checks
  - Security: Auth/authz, IDOR, injection, rate limiting

Standards:
  - Each automated test MUST reference its TC-ID in a comment/annotation: `// TC-XXX`
  - Arrange-Act-Assert pattern within each test
  - No test depends on another test's side effects (full isolation)
  - Test data via factories, never hardcoded literals
  - Contract tests use API_SPEC.md as source of truth
  - Performance tests use k6 with thresholds in options block matching NFR values exactly
  - Resilience tests use chaos tooling (Toxiproxy) or mock servers for failure injection
  - Observability tests capture log output and assert on field presence and PII absence

Coverage gates enforced in CI:
  - Domain/Application unit: 90% line, 85% branch
  - Infrastructure integration: 100% of all public methods
  - API contract: 100% of all endpoints and status codes
  - E2E: 100% of P0 happy paths
  - Performance: 100% of NFRs with numeric thresholds
  - Resilience: 100% of CRITICAL/DEGRADABLE dependencies per failure mode
  - Observability: 100% of OBS-ID commitments
  - Security: 100% of endpoints (auth + authz + input)

Drift detection (run after every update):
  - Contract drift: API_SPEC.md changed since last test run → flag affected contract tests
  - Signature drift: source method signature changed → flag unit tests testing that method
  - Requirement drift: REQ/BR deprecated in PRODUCT_SPEC.md → flag linked test cases for deprecation review
  - Observability drift: OBS-ID removed from OBSERVABILITY.md → flag linked observability tests

When updating existing tests:
  - Never delete test cases, only deprecate (comment with date and reason)
  - If behavior changes, update the test AND the TC reference comment
  - Add new TC-IDs for new tests — never reuse old IDs
</objective>

<context>
Feature/area: $ARGUMENTS

Flags:
  --framework <name>  Target specific test framework (jest, pytest, junit, etc.)
  --layer <layer>     Generate for specific test layer only
  --update-only       Only update existing tests, don't create new files
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/test-automation.md
@/Users/seanlew/.claude/sdlc/references/testing-standards.md
@/Users/seanlew/.claude/sdlc/references/resilience-patterns.md
</execution_context>

