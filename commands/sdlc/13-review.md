---
name: sdlc:13-review
description: Cross-cutting quality review — checks requirements traceability, data model integrity, architecture compliance, test coverage, observability completeness, and code quality.
argument-hint: "[feature/area] [--full] [--arch] [--data] [--test] [--obs] [--code]"
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
  - WebSearch
  - WebFetch
---

<objective>
Run a holistic quality review across all SDLC artifacts for a feature or the full system.

Review dimensions:

1. REQUIREMENTS TRACEABILITY
   - Every business rule has at least one test case
   - Every test case traces to a requirement
   - No orphaned requirements or tests

2. DATA MODEL INTEGRITY
   - No unapproved changes to canonical data model
   - All entities have complete DATA_DICTIONARY entries
   - Relationships are consistent with business rules
   - No data duplication across bounded contexts

3. ARCHITECTURE COMPLIANCE
   - Clean architecture dependency rule not violated
   - No domain code importing infrastructure
   - All external calls go through port interfaces
   - Design patterns correctly applied

4. TEST COVERAGE
   - MECE check on test cases (no gaps, no overlaps)
   - Coverage gates met (90% critical paths)
   - All API endpoints have contract tests
   - All error paths have negative tests

5. OBSERVABILITY COMPLETENESS
   - Structured logging present at all service boundaries
   - Trace IDs propagated correctly
   - All use cases emit metrics
   - No PII in logs

6. RESILIENCE COMPLETENESS
   - All external dependencies classified (CRITICAL/DEGRADABLE/OPTIONAL)
   - Explicit timeouts on every outbound call (connect + read)
   - Circuit breaker on every CRITICAL and DEGRADABLE dependency
   - Retry with backoff — only on retryable errors, not non-idempotent ops
   - Bulkhead on DB pool and concurrent external calls
   - Graceful degradation fallback on every DEGRADABLE dependency
   - Load shedding middleware present
   - SIGTERM handler drains in-flight requests correctly
   - Resilience checklist from resilience-patterns.md verified

7. DEPLOYMENT READINESS
   - /health/live, /health/ready, /health/startup endpoints implemented and correct
   - Dockerfile uses multi-stage build and non-root user
   - K8s manifests have resource requests AND limits on every container
   - HPA minReplicas >= 2 (single replica = SPOF)
   - PDB minAvailable >= 1
   - No secrets in ConfigMaps, Dockerfiles, or committed .env files
   - Graceful shutdown terminationGracePeriodSeconds matches SIGTERM handler timeout

8. CODE QUALITY
   - /simplify run on all changes
   - No code smells (God classes, long methods, magic numbers)
   - Error handling complete (no swallowed exceptions)
   - No hardcoded config values

Output: docs/review/REVIEW_REPORT.md with findings, severity, and remediation tasks added to TODO.md
</objective>

<context>
Feature/area to review: $ARGUMENTS (full system if omitted)

Flags:
  --full  Run all review dimensions
  --arch  Architecture compliance only
  --data  Data model integrity only
  --test  Test coverage only
  --obs   Observability completeness only
  --code  Code quality only
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/review.md
@/Users/seanlew/.claude/sdlc/references/clean-architecture.md
@/Users/seanlew/.claude/sdlc/references/testing-standards.md
@/Users/seanlew/.claude/sdlc/references/observability-standards.md
@/Users/seanlew/.claude/sdlc/references/data-standards.md
@/Users/seanlew/.claude/sdlc/references/resilience-patterns.md
@/Users/seanlew/.claude/sdlc/references/microservices.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>

