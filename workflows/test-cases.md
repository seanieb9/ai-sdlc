# Test Cases Workflow

Design comprehensive, MECE test cases with full requirement traceability. Test cases are the specification for automation — quality here directly determines quality of the system. Tests are derived from ALL source documents and the implementation itself.

## Step 0: Workspace Resolution
Run this bash to determine workspace paths:
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$WORKSPACE/artifacts"
```
Then use $WORKSPACE, $STATE, $ARTIFACTS throughout.

## Step 1: Pre-Flight Gate Check

Read ALL of the following in parallel — do not skip any source:

**Specification sources:**
- `$ARTIFACTS/idea/prd.md` — REQUIRED. Requirements, BDD scenarios, business rules, NFRs, acceptance criteria
- `$ARTIFACTS/journey/customer-journey.md` — user flows, personas, failure paths, emotional states
- `$ARTIFACTS/design/api-spec.md` — every endpoint, request/response shape, error codes, auth requirements
- `$ARTIFACTS/data-model/data-model.md` — entities, invariants, lifecycle states, relationships
- `$ARTIFACTS/data-model/data-dictionary.md` — field constraints, types, valid values

**Architecture and design sources (required — these generate tests too):**
- `$ARTIFACTS/design/tech-architecture.md` — service boundaries, patterns chosen (circuit breaker → test it trips), infrastructure contracts
- `$ARTIFACTS/design/solution-design.md` — ADRs: every architectural decision is an implementation commitment that needs a test

**Phase-dependent sources (read if available — skip the corresponding test layer if not yet created):**
- `$ARTIFACTS/observability/observability.md` — every structured log, metric, and span commitment needs a test asserting it's emitted. **Created in Phase 11, which runs after Phase 8.** If not yet created: skip the Observability test layer (mark as DEFERRED in coverage matrix), then re-run `/sdlc:test-cases` after Phase 11 completes.
- `$ARTIFACTS/sre/runbooks.md` — resilience behaviours documented here need corresponding tests. **Created in Phase 12, which runs after Phase 8.** If not yet created: skip the Resilience test layer detail (mark as DEFERRED), then re-run `/sdlc:test-cases` after Phase 12 completes.

> **Two-pass pattern:** It is normal and correct to run Phase 9 twice — once after Phase 8 (covering Unit, Integration, Contract, E2E, Performance, Security) and once after Phases 11 and 12 (adding Observability and Resilience layers). The Phase 9 completion gate requires all 8 layers; the first pass covers 6.

**Implementation source:**
- Relevant source code — read the actual implementation to find behaviour not in specs and verify spec alignment

**Existing test state:**
- `$ARTIFACTS/test-cases/test-cases.md` — read in full to avoid duplicates and find gaps

If prd.md missing: STOP. Cannot design tests without requirements.

---

## Step 2: Extract All Test Targets

Work through each source systematically. Build a raw list of "things that need testing" before writing any test cases.

### From PRODUCT_SPEC.md

For every item, note the REQ-ID, BR-ID, or NFR-ID:

- Every functional requirement → at least one P0/P1 test (happy path)
- Every business rule (BR-ID) → at least one unit test enforcing the rule
- Every exception/error case (EH-ID) → at least one negative test
- Every BDD scenario → maps to an E2E or contract test
- Every acceptance criterion → maps to one or more assertions in tests
- Every NFR (latency, throughput, availability) → maps to a performance test

### From API_SPEC.md

For every endpoint, extract:
- Happy path (correct request → correct response status and shape)
- Every required field missing → 422 with field-level error
- Every invalid field value → 422 with specific error code
- Unauthenticated request → 401
- Authenticated but wrong role → 403
- Resource not found → 404
- Conflict (duplicate create) → 409
- Server error shape validation → 500 matches error schema
- Rate limit exceeded → 429 with Retry-After header
- Idempotency key behaviour (if specified) → duplicate request returns same result, no side effects replayed

### From DATA_MODEL.md

- Every invariant → unit test in domain layer
- Every lifecycle state transition (PENDING → SUBMITTED → CONFIRMED → CANCELLED) → state machine test per valid transition AND invalid transition
- Every unique constraint → duplicate insert test
- Every required/NOT NULL field → null/missing value test
- Every foreign key relationship → referential integrity test (create/delete parent)
- Every aggregate boundary → test that child entities cannot be accessed directly

### From CUSTOMER_JOURNEY.md

- Every happy path journey per persona → P0 E2E test
- Every failure path documented → P1 E2E test
- Every emotional low point (frustration, confusion) in the journey → verify the UX/API handles it gracefully
- Every "system state after step N" → assert as E2E intermediate checkpoint

### From TECH_ARCHITECTURE.md and SOLUTION_DESIGN.md

For every architectural commitment:
- **Circuit breaker chosen** → test it trips at failure threshold, rejects during OPEN state, recovers after timeout
- **Retry with backoff chosen** → test it retries on transient errors, does NOT retry on 4xx, respects max attempts
- **Bulkhead pattern** → test that pool exhaustion returns 503, not hang
- **CQRS** → test that write model and read model stay consistent
- **Outbox pattern** → test that events are published after transaction commit, not before
- **Saga pattern** → test compensation actions are triggered on failure at each step
- **API versioning strategy** → test that v1 and v2 can coexist, breaking change is rejected on old version

### From observability.md

For every observability commitment:
- **Structured log fields** → test that use case entry/exit logs contain trace_id, action, outcome
- **Metric increments** → test that `orders_created_total` increments on order creation
- **Span creation** → test that a span is created and contains required attributes for each use case
- **No PII in logs** → negative test: log output does NOT contain email, password, card number
- **Health endpoints** → test /health/ready returns 503 when DB is down, 200 when up

### From SOLUTION_DESIGN.md (ADRs)

Each ADR is an implementation commitment. For every ADR:
- What was the decision? → test that it is correctly implemented
- What were the alternatives rejected? → test that the rejected approach is NOT present

### From source code (implementation analysis)

Read the actual implementation and find:
- **Branches with no spec coverage** — every `if/else`, `switch case`, `try/catch` that has no corresponding test target yet → add to test list
- **Error paths** — every exception thrown with no corresponding negative test → add to test list
- **Implicit behaviour** — behaviour in code not captured in specs (e.g., silently truncating a field, defaulting a value) → note as finding, add test
- **Divergence from spec** — implementation does something different from what API_SPEC or PRODUCT_SPEC says → flag as a FINDING in the review section, add test that documents the actual behaviour

---

## Step 3: Identify Spec Divergence (Before Writing Tests)

During the implementation analysis (Step 2 source code review), record any divergence:

```
DIVERGENCE-001:
  Source: API_SPEC.md — POST /orders — status field must be "PENDING"
  Implementation: order.ts line 45 — sets status to "CREATED"
  Finding: Implementation does not match spec — document and flag
  Action: Raise with team — fix spec OR fix implementation before writing test
```

Do NOT write tests that encode incorrect behaviour. Surface divergence first.

---

## Step 4: Build the Coverage Matrix

Before writing individual test cases, build the full traceability matrix:

```
Source ID     | Source Type | Description                   | Test Targets           | Status
REQ-001       | Requirement | User can create an order      | TC-001, TC-002, TC-003 | ✅ Covered
REQ-002       | Requirement | Order total must be positive  | TC-004                 | ✅ Covered
BR-001        | Biz Rule    | Items must have qty > 0       | TC-005                 | ✅ Covered
API POST /ord | API Spec    | Create order endpoint         | TC-006..TC-012         | ✅ Covered
NFR-001       | NFR         | p95 latency < 200ms           | TC-045                 | ✅ Covered
ADR-003       | ADR         | Circuit breaker on payment svc| TC-050, TC-051         | ✅ Covered
OBS-LOG-001   | Observab.   | trace_id in all use case logs | TC-060                 | ✅ Covered
[source]      | [type]      | [description]                 | —                      | ❌ GAP
```

Every row must have at least one TC-ID before the workflow is complete. Flag all gaps immediately — do not proceed to write test cases while gaps exist.

---

## Step 5: Design Test Cases by Layer

### Unit Tests — domain logic, isolated

Targets: entities, value objects, domain services, use cases (mocked dependencies)
Goal: verify every business rule, invariant, and branch of domain/application logic in isolation

```
TC-[NNN]: [Entity/Service/UseCase]: [rule or scenario being tested]
Layer:        Unit
Priority:     P0 (invariant) | P1 (business rule) | P2 (edge case)
Requirement:  REQ-[N] / BR-[N] / Source-[ID]

Given  [System state — entity in state X, with data Y]
When   [Method/operation called with Z]
Then   [Expected return value]
  And  [Expected state change on entity]
  And  [Expected domain events collected]
Does NOT: [What must NOT happen — e.g. does not persist, does not emit event]

Notes: [boundary values tested, related edge cases]
```

### Integration Tests — components with real infrastructure

Targets: repository implementations, external adapters, DB queries, message broker interactions
Goal: verify components work correctly with real infrastructure (test containers)

```
TC-[NNN]: [Repository/Adapter]: [scenario]
Layer:        Integration
Priority:     P1
Requirement:  [source]

Given  [Database state / external system state — use test container]
When   [Repository method / adapter call]
Then   [Correct data persisted or returned]
  And  [Transaction committed or rolled back correctly]
  And  [Constraints enforced — unique violation returns correct error]
  And  [Optimistic lock version incremented]
```

Must cover per repository:
- `save()` insert new record
- `save()` update existing record (version bump verified)
- `save()` concurrent modification — optimistic lock conflict
- `findById()` found case
- `findById()` not found case (returns null, not throws)
- `findBy*()` pagination — correct page, correct cursor
- `findBy*()` empty result
- DB constraint violations (duplicate unique key)
- Transaction rollback on domain exception

### Contract Tests — API surface

Targets: every HTTP endpoint
Goal: verify the API behaves exactly as documented in API_SPEC.md

```
TC-[NNN]: [METHOD] [path]: [scenario]
Layer:        Contract
Priority:     P0 — all contract tests are P0
Requirement:  API_SPEC.md: [METHOD] [path]

Given  [Auth state — authenticated as role X / unauthenticated]
  And  [Request headers — Idempotency-Key if applicable]
When   [METHOD] [path] called with [body/params]
Then   Response status is [code]
  And  Response body matches schema: [field: type, required/optional]
  And  Response headers: [Location on 201, Content-Type, etc.]
  And  Error body contains: { code: "MACHINE_CODE", trace_id: present }
```

Required contract tests per endpoint (minimum):
1. Happy path → 200/201/204
2. Missing required field → 422 with field-level error
3. Invalid field type/format → 422
4. Unauthenticated → 401
5. Wrong role → 403
6. Not found → 404 (where applicable)
7. Conflict → 409 (where applicable)
8. Rate limit exceeded → 429 with Retry-After
9. Idempotency: duplicate request with same key → same response, no side effects

### E2E Tests — full journeys

Targets: complete user journeys from API entry to DB persistence and event publishing
Goal: verify business scenarios work end-to-end

```
TC-[NNN]: Journey: [Persona] — [Journey Name]
Layer:        E2E
Priority:     P0 (happy path) | P1 (critical failure path)
Requirement:  CUSTOMER_JOURNEY.md + REQ-[N]

Given  [Full system state — seed data, test user, system configuration]
When   [Journey step 1 — API call or action]
  And  [Journey step 2]
  And  [Journey step N]
Then   [Final state — what the persona achieved]
  And  [DB state — persisted correctly, all fields correct]
  And  [Domain events published — correct event type, correct payload]
  And  [Side effects — notifications sent, audit log present]
  And  [No unintended side effects — does NOT charge twice, does NOT email twice]
```

### Performance / NFR Tests

Targets: SLO-critical endpoints and business operations
Goal: verify the system meets its NFR commitments under representative load

```
TC-[NNN]: Performance: [operation] meets [NFR-ID] target
Layer:        Performance
Priority:     P1
Requirement:  NFR-[N] from PRODUCT_SPEC.md

Scenario:
  Load profile: [N] concurrent users, [N] rps sustained for [duration]

Then   p50 latency < [X]ms
  And  p95 latency < [X]ms (from NFR-[N])
  And  p99 latency < [X]ms
  And  Error rate < [X]%
  And  Throughput >= [N] rps
  And  No memory leak (stable RSS over 5min sustained load)
```

### Resilience Tests

Targets: every CRITICAL and DEGRADABLE external dependency
Goal: verify resilience patterns from TECH_ARCHITECTURE.md actually work

```
TC-[NNN]: Resilience: [dependency] [failure scenario]
Layer:        Resilience
Priority:     P1
Requirement:  ADR-[N] / TECH_ARCHITECTURE.md

Given  [Service running with circuit breaker configured]
When   [Dependency returns 503 / connection timeout / DNS failure]
  And  [Failure rate exceeds circuit breaker threshold]
Then   [Circuit is OPEN — subsequent requests fast-fail within 50ms]
  And  [metric circuit_breaker.state = OPEN]
  And  [Degradation fallback returned (for DEGRADABLE dependency)]
  And  [No 500 errors propagated to caller]
  And  After [openTimeoutMs]: [probe request allowed — circuit enters HALF-OPEN]
  And  After [successThreshold] successes: [circuit CLOSED, normal operation resumed]
```

Also cover: timeout enforcement, retry with backoff, bulkhead exhaustion, graceful degradation fallback activation, rate limiting, SIGTERM drain.

### Observability Tests

Targets: logging, metrics, tracing commitments from OBSERVABILITY.md
Goal: verify the observability contract is met

```
TC-[NNN]: Observability: [use case] emits [log/metric/span]
Layer:        Observability (can be unit or integration depending on assertion)
Priority:     P1
Requirement:  OBSERVABILITY.md: [section]

Given  [Use case executes successfully / with error]
When   [create_order use case completes]
Then   Log at INFO level emitted with fields: trace_id, action="create_order", outcome="success", duration_ms
  And  Log does NOT contain: email, password, card_number
  And  Metric usecase_executions_total{action="create_order", outcome="success"} incremented by 1
  And  Span "order-service.usecase.create_order" created with attribute outcome="success"
```

### Frontend Tests (only when SCREEN_SPEC.md exists)

Skip this section entirely if the project has no front-end.

#### Component Tests (Jest + RNTL)

```
TC-[NNN]: Component: [ComponentName] [scenario]
Layer:        Frontend-Component
Priority:     P1
Requirement:  SCREEN_SPEC.md: [screen] → components

Given  [Component rendered with props X]
When   [User interaction / prop change]
Then   [Expected rendered output]
  And  [Accessibility tree correct — roles, labels, states]
  And  [testID present on interactive elements]
Does NOT: [fetch data, contain business logic]
```

Cover per shared component:
- Renders correctly with required props
- Renders all visual variants
- Handles missing/null optional props gracefully
- All interactive elements have correct accessibilityRole and accessibilityLabel
- Disabled state renders and blocks interaction

#### Accessibility Tests (jest-axe + manual)

```
TC-[NNN]: A11y: [screen] passes WCAG 2.1 AA
Layer:        Frontend-A11y
Priority:     P1
Requirement:  frontend-standards.md WCAG 2.1 AA baseline

Given  [Screen rendered in test environment]
When   [jest-axe runs axe analysis]
Then   No WCAG violations at AA level
  And  All touch targets ≥ 44×44pt
  And  All interactive elements have accessibilityLabel
  And  Color contrast ≥ 4.5:1 for normal text
```

#### E2E Tests (Maestro)

```
TC-[NNN]: E2E Flow: [Persona] — [Journey Name] on [platform]
Layer:        Frontend-E2E
Priority:     P0 (happy path) | P1 (failure path)
Requirement:  SCREEN_SPEC.md + CUSTOMER_JOURNEY.md

Given  [App launched, user in state X]
When   [Journey step 1 — tap / type / swipe]
  And  [Journey step N]
Then   [Final screen shown]
  And  [Expected API call made (verified via mock or real)]
  And  [Correct data displayed]
```

Cover per Maestro flow:
- Happy path for every P0 journey in SCREEN_SPEC.md
- Primary failure path (network error → error state shown → retry works)
- Loading state shown before data arrives
- Empty state shown when API returns empty list

---

### Security Tests

Targets: auth/authz rules, input validation, injection prevention
Goal: verify OWASP API Top 10 mitigations from tech-arch security design

```
TC-[NNN]: Security: [endpoint/operation] [attack scenario]
Layer:        Security (contract-level, no unit mocking)
Priority:     P0 for auth, P1 for injection
Requirement:  TECH_ARCHITECTURE.md Security Architecture

Examples:
- Unauthenticated request to protected endpoint → 401
- Valid token but insufficient role → 403
- Object belongs to different user → 403 (not 404 — no information leakage)
- SQL injection in query param → 422, no DB error leaked
- Oversized payload → 413 or 422, no crash
- Expired token → 401
- Token from wrong issuer → 401
```

---

## Step 6: MECE Analysis

Before finalising, perform the full MECE check:

**Exhaustive (no gaps):**
- [ ] Every REQ-ID → at least one test
- [ ] Every BR-ID → at least one unit test
- [ ] Every EH-ID (error case) → at least one negative test
- [ ] Every API endpoint → contract test suite (happy + all error codes)
- [ ] Every data invariant → unit test
- [ ] Every lifecycle state transition → test (valid AND invalid transitions)
- [ ] Every happy path journey → P0 E2E test
- [ ] Every P0 failure journey → P1 E2E test
- [ ] Every NFR → performance test
- [ ] Every ADR circuit breaker / retry / bulkhead / degradation → resilience test *(defer if RUNBOOKS.md not yet created)*
- [ ] Every observability commitment → observability test *(defer if OBSERVABILITY.md not yet created)*
- [ ] Every auth/authz rule → security test

**Mutually exclusive (no overlaps):**
- [ ] No two test cases have identical Given/When/Then
- [ ] Contract tests check API shape; E2E tests check flow — no duplication of assertions
- [ ] Unit tests test isolated logic; integration tests test real infrastructure — no overlap

For any gap: add new test case immediately.
For any overlap: merge or deprecate, document reason.

---

## Step 7: Continuous Update Rules

These rules enforce test case currency. Apply them on every change to source documents.

### When PRODUCT_SPEC.md changes

| Change type | Required test action |
|------------|---------------------|
| New REQ-ID added | Add test case(s) for new requirement |
| REQ-ID scope changed | Update existing test case(s) — update GWT, update assertions |
| REQ-ID deprecated | Deprecate corresponding test cases with reason and date |
| Business rule added/changed | Add/update unit test for that BR-ID |
| New error case | Add negative test |
| NFR tightened | Update performance test threshold |

### When API_SPEC.md changes

| Change type | Required test action |
|------------|---------------------|
| New endpoint added | Add full contract test suite for that endpoint |
| Field added to request | Add validation test for new field |
| Field removed | Update contract tests — remove assertion for removed field |
| Error code added | Add negative test for new error code |
| Auth requirement changed | Update auth/authz test cases |
| Breaking version change | Add contract tests for new API version; keep v1 tests |

### When DATA_MODEL.md changes

| Change type | Required test action |
|------------|---------------------|
| New entity added | Add unit tests for invariants; add integration tests for repository |
| Invariant added/changed | Update unit test — must enforce new invariant |
| State transition added | Add state machine test for new valid/invalid transition |
| Constraint changed | Update integration test (unique key, NOT NULL, etc.) |
| Entity deprecated | Deprecate related test cases |

### When implementation changes (code change)

When source code changes, run:
1. **Coverage diff check** — does coverage drop below gate? If so, new code paths are untested → add test cases
2. **Implementation drift check** — does changed code diverge from existing test assertions? If so, either: fix the code (if spec is correct) OR update test case + note the spec change needed
3. **New branch analysis** — any new `if/else`, `switch`, `try/catch` added → verify existing tests cover new branches

### When architecture decisions change (SOLUTION_DESIGN.md or TECH_ARCHITECTURE.md)

| Change type | Required test action |
|------------|---------------------|
| New pattern adopted (e.g. saga) | Add resilience tests for that pattern |
| Dependency classification changed | Review degradation test cases for that dependency |
| New service boundary | Add contract tests between services |
| ADR reversed | Remove or deprecate tests for the old decision |

---

## Step 8: Staleness Detection

Before finalising any test case update, run the staleness scan:

**Step 8a: Find tests with broken requirement links**
- List all REQ-IDs referenced in TEST_CASES.md
- Compare against all REQ-IDs in PRODUCT_SPEC.md
- Flag: any TC referencing a deprecated REQ-ID → needs deprecation or update

**Step 8b: Find tests with stale API references**
- List all endpoints referenced in contract test cases
- Compare against all endpoints in API_SPEC.md
- Flag: any TC referencing an endpoint not in current API_SPEC.md → stale

**Step 8c: Find requirements with no test**
- List all REQ-IDs, BR-IDs, NFR-IDs, EH-IDs from PRODUCT_SPEC.md
- Compare against coverage matrix
- Flag: any ID with no test case → gap

**Step 8d: Find test cases with no automation**
- List all TC-IDs in TEST_CASES.md
- Cross-reference with TC-ID comments in test files
- Flag: any TC-ID with no corresponding automated test → automation gap

Report all findings. Resolve all HIGH/CRITICAL gaps before marking complete.

---

## Step 9: Write Output Document

**Update $ARTIFACTS/test-cases/test-cases.md:**

```markdown
# Test Cases
*Last Updated: [date]*
*Total: [N] | P0: [N] | P1: [N] | P2: [N]*

---

## Coverage Matrix

| Source ID | Source Type | Description | TC-IDs | Status |
|-----------|-------------|-------------|--------|--------|
| REQ-001   | Requirement | [brief]     | TC-001, TC-002 | ✅ |
| BR-001    | Biz Rule    | [brief]     | TC-003 | ✅ |
| NFR-001   | NFR         | [brief]     | TC-045 | ✅ |
| ADR-003   | ADR         | [brief]     | TC-050 | ✅ |
| API POST /orders | API Spec | [brief] | TC-006..TC-012 | ✅ |

---

## Unit Tests
### [Domain/Entity/UseCase Name]
[Test cases]

## Integration Tests
### [Repository/Adapter Name]
[Test cases]

## Contract Tests
### [Endpoint Group]
[Test cases]

## E2E Tests
### [Journey Name]
[Test cases]

## Performance Tests
[Test cases]

## Resilience Tests
[Test cases]

## Observability Tests
[Test cases]

## Security Tests
[Test cases]

---

## Deprecated Test Cases
<!-- ~~TC-NNN~~: Deprecated [date] — [reason] — replaced by TC-MMM if applicable -->
```

Rules — always enforced:
- Append new TCs, never renumber existing ones
- Deprecated tests stay with `~~TC-XXX~~` notation — never deleted
- When a feature changes, UPDATE the existing test case + update GWT
- New functionality = new TC-IDs
- Every test case must reference a source ID (REQ, BR, NFR, ADR, API endpoint, etc.)

---

## Step 10: Update State

Mark Phase 9 (Test Cases) complete in $STATE.

Output:
```
✅ Test Cases Complete

Total: [N] test cases
  Unit: [N] | Integration: [N] | Contract: [N] | E2E: [N]
  Performance: [N] | Resilience: [N] | Observability: [N] | Security: [N]

Coverage:
  Requirements: [N]/[N] REQ-IDs covered (100%)
  Business Rules: [N]/[N] BR-IDs covered (100%)
  API Endpoints: [N]/[N] endpoints covered (100%)
  NFRs: [N]/[N] NFR-IDs covered (100%)
  ADRs: [N]/[N] architectural commitments covered (100%)

Spec divergence found: [N] (all flagged in review-report.md)
Staleness findings: [N] (all resolved)
MECE gaps: [N] (all addressed)
MECE overlaps: [N] (all resolved)

File: $ARTIFACTS/test-cases/test-cases.md

Recommended Next: /sdlc:verify --phase 9   ← run this before proceeding
```
