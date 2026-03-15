# Testing Standards Reference

## Testing Pyramid

```
         /\
        /E2E\          Few — slow, fragile, expensive
       /------\
      /  Integ  \      Some — test component boundaries
     /------------\
    /  Unit Tests  \   Many — fast, isolated, cheap
   /________________\
```

**Coverage targets:**
- Unit: 90%+ line coverage on domain and application layers
- Integration: all repository methods, all external adapters
- Contract: every API endpoint
- E2E: every happy path journey + top failure paths

---

## MECE Principle for Test Design

**Mutually Exclusive:** No two tests test the same thing. If two tests have identical Given/When/Then, one is redundant.

**Collectively Exhaustive:** Every requirement, every business rule, every error code, every boundary condition is tested.

**MECE checklist:**
- [ ] Every REQ-ID appears in at least one test
- [ ] Every BR-ID (business rule) has a unit test
- [ ] Every EH-ID (exception) has a negative test
- [ ] Every API endpoint has a contract test
- [ ] Every state transition has a test
- [ ] No two tests have identical Given/When/Then

---

## Given/When/Then Format

**Given:** Describes the system state BEFORE the action. Sets up the world. Be specific — include IDs, counts, states.
- Good: `Given a customer exists with id "cust-123" and has placed 2 orders`
- Bad: `Given a customer`

**When:** The SINGLE action that triggers the behavior being tested. One action per test.
- Good: `When the customer submits a new order with 3 items totaling $150`
- Bad: `When the customer logs in and submits an order and checks status`

**Then:** ALL observable outcomes. Be exhaustive — state, return value, events, side effects.
- Good: `Then the response is 201 Created AND the order is persisted with status PENDING AND an OrderPlaced event is published AND the customer's order count is 3`
- Bad: `Then it works`

**Negative form:**
After Then, add what should NOT have happened:
- `Does NOT send a confirmation email (payment not yet collected)`
- `Does NOT change the customer's credit limit`

---

## Test Isolation Rules

1. **Tests are independent:** No test depends on another test running first
2. **Tests are repeatable:** Same result on every run
3. **Tests clean up after themselves:** No shared mutable state between tests
4. **Test data setup:** Use factories/fixtures, not production data
5. **Time:** Never use `new Date()` in tests — use a fixed mock clock
6. **Random:** Never use `Math.random()` in tests — use deterministic seeds
7. **External services:** Mock in unit tests. Use real implementations in integration tests. Use test containers where possible.

---

## Contract Testing

Contract tests verify the API behaves exactly as documented in API_SPEC.md.

**For every endpoint, test:**
1. Happy path — correct request → correct response shape and status
2. Missing required fields → 422 with field-level errors
3. Invalid field values → 422 with specific error codes
4. Unauthenticated → 401
5. Unauthorized (wrong role) → 403
6. Resource not found → 404
7. Conflict (duplicate) → 409
8. Server error shape → 500 response matches error schema

**Response shape validation:**
- All fields present that are documented as always-present
- No extra fields that could leak internal details
- Correct types (string not number, array not object)
- Correct pagination envelope if paginated

---

## Test Naming Conventions

Pattern: `[context]_[scenario]_[expected_outcome]`

Examples:
- `create_order_with_empty_items_raises_domain_exception`
- `order_repository_find_by_id_returns_none_when_not_found`
- `POST_orders_with_valid_payload_returns_201_with_order_id`
- `checkout_journey_when_payment_fails_shows_retry_option`

---

## Test Data Management

**Factories (not fixtures):** Create test data programmatically with sensible defaults that can be overridden.

```python
# Good — factory with defaults
def make_order(customer_id=None, items=None, status=OrderStatus.PENDING):
    return Order(
        customer_id=customer_id or uuid4(),
        items=items or [make_order_item()],
        status=status
    )

# Bad — hardcoded fixture file with magic data
# order.json: { "id": "123", "status": "PENDING" ... }
```

**Database state:** Use transactions that roll back after each test (not truncate). If using test containers, reset between test suites.

---

## Performance Tests

Performance tests validate NFR thresholds defined in PRODUCT_SPEC.md/TECH_ARCHITECTURE.md.

**Sources:** NFR-IDs from PRODUCT_SPEC.md, SLOs from OBSERVABILITY.md, ADRs from TECH_ARCHITECTURE.md.

**Tool:** k6 (preferred), Locust, or JMeter.

**TC structure:**
```
Given  System at [N] concurrent users / [RPS] sustained load
When   [Scenario: steady-state | ramp-up | spike | soak]
Then   p50 latency ≤ [X]ms
  And  p95 latency ≤ [Y]ms
  And  p99 latency ≤ [Z]ms
  And  Error rate ≤ [N]%
  And  Throughput ≥ [N] RPS
```

**Required scenario types:**
| Scenario | Purpose | Duration |
|----------|---------|---------|
| Baseline | Establish normal behavior | 5 min steady |
| Load | At expected peak traffic | 15 min steady |
| Stress | 2× expected peak | Until degradation |
| Spike | 10× load in 10 seconds | 30 sec spike |
| Soak | Sustained load for memory/leak detection | 1 hour |

**Coverage gate:** Every NFR with a numeric threshold must have a performance test.

**k6 example:**
```javascript
// TC-XXX: NFR-001 — Order creation p95 < 200ms under 1000 RPS
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 1000 },   // ramp up
    { duration: '5m', target: 1000 },   // steady state
    { duration: '1m', target: 0 },      // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.post('/api/v1/orders', JSON.stringify(payload), { headers });
  check(res, { 'status is 201': (r) => r.status === 201 });
  sleep(1);
}
```

---

## Resilience Tests

Resilience tests verify the system handles failures gracefully per the resilience-patterns.md classification.

**Sources:** Dependency classification in TECH_ARCHITECTURE.md, circuit breaker and retry config in SRE docs.

**TC structure:**
```
Given  [Dependency] is [down | slow (Xms) | returning 500 | timing out]
When   [Use case / endpoint] is called
Then   [Circuit opens after N failures | Fallback value returned | Retry attempts N times | Request rejected with 503]
  And  Error metric incremented
  And  Alert triggered (if CRITICAL dependency)
Does NOT: Propagate error to caller (for DEGRADABLE dependencies)
```

**Required failure modes per dependency class:**
| Classification | Required tests |
|---------------|---------------|
| CRITICAL | Timeout → 503, dependency down → circuit opens, circuit open → fast fail |
| DEGRADABLE | Timeout → fallback returned, dependency down → stale cache or default, partial failure → degraded mode |
| OPTIONAL | Failure → ignored, no impact to primary flow |

**Test tooling:** Test containers (Toxiproxy for latency/timeout injection), mock server returning error codes.

**Coverage gate:** Every CRITICAL and DEGRADABLE dependency must have at least one resilience test per failure mode.

---

## Observability Tests

Observability tests verify logging, tracing, and metrics are emitted correctly.

**Sources:** OBS-IDs from OBSERVABILITY.md, metric definitions, alert rules.

**TC structure (logging):**
```
Given  [System state / trace context]
When   [Use case executed]
Then   Log line emitted at [level] containing:
  - trace_id: matches W3C format
  - span_id: present
  - service: [service name]
  - event: "[event name]"
  - [domain fields: user_id, order_id, etc.]
Does NOT: Contain PII (email, SSN, card number)
```

**TC structure (metrics):**
```
Given  [N] requests made to [endpoint]
When   Prometheus metrics scraped
Then   http_requests_total{method="POST", path="/orders", status="201"} == N
  And  http_request_duration_seconds_bucket matches latency distribution
```

**TC structure (tracing):**
```
Given  Distributed request spanning [service-A → service-B → service-C]
When   Request completes
Then   Single trace_id propagated across all 3 services
  And  Parent-child span relationships correct
  And  db.query span present with duration
  And  No orphaned spans
```

**Coverage gate:** Every OBS-ID commitment in OBSERVABILITY.md must have a corresponding observability test.

---

## Security Tests

Security tests verify authentication, authorization, input validation, and data protection per OWASP API Top 10.

**Sources:** Security requirements in PRODUCT_SPEC.md, auth model in TECH_ARCHITECTURE.md, OWASP API Top 10.

**TC structure:**
```
Given  [Attacker | unauthenticated user | user with insufficient role]
When   [Malicious or unauthorized request]
Then   [401 | 403 | 422 with no information leakage]
Does NOT: Return any internal stack trace, DB error, or implementation detail
```

**Required security test categories:**
| Category | Tests required |
|---------|---------------|
| Authentication | Missing token → 401, expired token → 401, tampered token → 401 |
| Authorization | User accesses other user's resource → 403, insufficient role → 403, IDOR test for every resource |
| Input validation | SQL injection patterns → 422, XSS payloads → 422 or escaped, oversized payloads → 413 or 422 |
| Rate limiting | Exceeding rate limit → 429 with Retry-After header |
| Sensitive data | Passwords not in responses, no PII in error messages, no secrets in logs |
| Mass assignment | Extra fields in request not persisted if not whitelisted |

**Coverage gate:** Every API endpoint must have auth, authz, and input validation security tests.

---

## Automation Coverage Gates

| Layer | Metric | Gate |
|-------|--------|------|
| Domain (unit) | Line coverage | ≥ 90% |
| Domain (unit) | Branch coverage | ≥ 85% |
| Application (unit) | Line coverage | ≥ 90% |
| Infrastructure (integration) | All methods | 100% |
| API (contract) | All endpoints | 100% |
| E2E | Happy path journeys | 100% |
| E2E | P0 failure journeys | 100% |
| Performance | Every NFR with numeric threshold | 100% |
| Resilience | Every CRITICAL/DEGRADABLE dependency | 100% |
| Observability | Every OBS-ID commitment | 100% |
| Security | Every endpoint: auth + authz + input | 100% |

CI pipeline must fail if gates are not met.

---

## Test Automation Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Testing implementation details | Tests break on refactor | Test behavior, not internals |
| Order-dependent tests | Flaky test suite | Isolate each test completely |
| Slow unit tests (> 100ms) | Developers skip tests | Mock all I/O in unit tests |
| Magic test data | Unclear intent | Named factory methods |
| Assert nothing | False confidence | At least one assertion per test |
| Catch expected exceptions loosely | Wrong exception type passes | Assert on specific exception type and message |
| Shared mutable state | Intermittent failures | Reset state before each test |
