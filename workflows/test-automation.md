# Test Automation Workflow

Generate and maintain automated test scripts strictly from test-cases.md. Test cases are the specification — scripts implement them, not the other way around. Every TC-ID must map to exactly one automated test. No TC-ID without automation. No automation without a TC-ID.

---

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

## Step 1: Gate Check

Read in parallel — ALL required:
- `$ARTIFACTS/test-cases/test-cases.md` — REQUIRED. Cannot automate without defined test cases.
- `$ARTIFACTS/test-gen/test-automation.md` — existing automation index (update, don't recreate)
- `$ARTIFACTS/design/api-spec.md` — for contract test assertions
- `$ARTIFACTS/observability/observability.md` — for log/metric/span assertions in observability tests
- `$ARTIFACTS/design/tech-architecture.md` — for resilience pattern config (timeout values, circuit breaker thresholds)
- Existing test files (Glob `**/*.test.*`, `**/*.spec.*`, `**/test_*.py`, etc.)

If test-cases.md missing: STOP. Run `/sdlc:test-cases` first.
If test-cases.md has untreated staleness findings: STOP. Resolve staleness before automating.

---

## Step 2: Detect Test Framework

From existing test files and package/config files:
- JavaScript/TypeScript: Jest, Vitest, Mocha, Playwright, Cypress
- Python: pytest, unittest
- Java: JUnit 5, TestNG
- Go: testing + testify
- Performance: k6, Gatling, Locust, Artillery
- Contract: Pact, Dredd

If multiple frameworks: document which layer uses which.
If `--framework` flag provided: use that framework.
If new project with no tests yet: propose framework based on language from TECH_ARCHITECTURE.md, confirm with user before creating files.

---

## Step 3: Build TC-ID to Automation Map

Read TEST_CASES.md and build a complete mapping before writing any code:

```
TC-001 (Unit,       P0) → [EXISTS] → src/domain/order.test.ts:12    "TC-001: throws when items empty"
TC-002 (Unit,       P0) → [EXISTS] → src/domain/order.test.ts:28    "TC-002: emits OrderCreated event"
TC-003 (Integration,P1) → [NEW]    → to create in tests/integration/order-repository.test.ts
TC-004 (Contract,   P0) → [NEW]    → to create in tests/contract/orders.contract.test.ts
TC-045 (Performance,P1) → [NEW]    → to create in tests/performance/create-order.k6.ts
TC-050 (Resilience, P1) → [NEW]    → to create in tests/resilience/circuit-breaker.test.ts
```

For each TC-ID:
- Search existing test files for `TC-[NNN]` in comments/annotations
- If found: verify the test still matches the current GWT — update if drifted
- If not found: create new test

**Never create a duplicate** — if TC-001 exists in one file, do not create TC-001 in another file.

---

## Step 4: Unit Test Implementation

One test function per test case. TC-ID in the comment on the line above.

```typescript
// TC-001: Order: throws DomainException when items list is empty
// REQ: BR-001
describe('Order', () => {
  it('TC-001: throws when constructed with empty items', () => {
    // Arrange
    const customerId = makeCustomerId()

    // Act & Assert
    expect(() => new Order(customerId, []))
      .toThrow(DomainException)
    expect(() => new Order(customerId, []))
      .toThrow('Order must have at least one item')
  })
})

// TC-002: Order: collects OrderCreated event on construction
// REQ: REQ-001
it('TC-002: collects OrderCreated domain event after creation', () => {
  // Arrange
  const customer = makeCustomer()
  const items = [makeOrderItem()]

  // Act
  const order = new Order(customer.id, items)
  const events = order.collectEvents()

  // Assert
  expect(events).toHaveLength(1)
  expect(events[0]).toBeInstanceOf(OrderCreated)
  expect(events[0].orderId).toBe(order.id)
  expect(events[0].customerId).toBe(customer.id)
  // Does NOT: emit OrderSubmitted at creation
  expect(events.some(e => e instanceof OrderSubmitted)).toBe(false)
})
```

Rules:
- TC-ID comment on the line above the `it()` block
- Arrange-Act-Assert structure — always three distinct sections
- One scenario per test — one `When` tested per `it()`
- Negative assertions (`Does NOT`) must be explicit — `expect(...).toBe(false)` not just absence of assertion
- Factories for all test data — never inline object literals unless trivially obvious
- Fixed mock clock for any time-dependent logic (`jest.useFakeTimers()`)
- No `Math.random()` in test setup

---

## Step 5: Integration Test Implementation

```typescript
// TC-045: PostgresOrderRepository: saves and retrieves order by ID
// REQ: REQ-004
describe('PostgresOrderRepository', () => {
  let repo: PostgresOrderRepository
  let db: TestDatabase

  beforeEach(async () => {
    db = await TestDatabase.start()    // test container — real Postgres, isolated schema
    repo = new PostgresOrderRepository(db)
    await db.runMigrations()
  })

  afterEach(async () => {
    await db.stop()
  })

  it('TC-045: saves order and retrieves by ID with correct fields', async () => {
    // Arrange
    const order = makeOrder()

    // Act
    await repo.save(order)
    const retrieved = await repo.findById(order.id)

    // Assert
    expect(retrieved).not.toBeNull()
    expect(retrieved!.id).toEqual(order.id)
    expect(retrieved!.status).toBe(OrderStatus.PENDING)
    expect(retrieved!.items).toHaveLength(order.items.length)
    expect(retrieved!.version).toBe(1)   // initial version after first save
  })

  it('TC-046: save increments version on update', async () => {
    const order = makeOrder()
    await repo.save(order)

    order.submit()
    await repo.save(order)

    const retrieved = await repo.findById(order.id)
    expect(retrieved!.version).toBe(2)
    expect(retrieved!.status).toBe(OrderStatus.SUBMITTED)
  })

  it('TC-047: concurrent modification throws ConflictException', async () => {
    const order = makeOrder()
    await repo.save(order)

    // Simulate concurrent modification — load twice, save first wins
    const copy1 = await repo.findById(order.id)
    const copy2 = await repo.findById(order.id)

    copy1!.submit()
    await repo.save(copy1!)    // succeeds

    copy2!.submit()
    await expect(repo.save(copy2!)).rejects.toThrow(ConflictException)
  })
})
```

Rules:
- Always use test containers or a dedicated test DB — never production DB, never shared state
- Reset DB between tests (stop/start container or transaction rollback)
- Test CRUD, pagination, constraints, concurrent modification, rollback
- Verify the full round-trip: save entity → retrieve entity → fields match exactly

---

## Step 6: Contract Test Implementation

```typescript
// TC-067: POST /api/v1/orders: valid payload returns 201 with order_id in body and Location header
// REQ: API_SPEC.md POST /orders
describe('POST /api/v1/orders', () => {
  it('TC-067: valid payload returns 201', async () => {
    // Arrange
    const token = await getAuthToken('customer')
    const payload = makeCreateOrderRequest()
    const idempotencyKey = randomUUID()

    // Act
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', idempotencyKey)
      .send(payload)

    // Assert — status
    expect(res.status).toBe(201)

    // Assert — body shape (exact fields, correct types)
    expect(res.body).toMatchObject({
      order_id: expect.stringMatching(UUID_PATTERN),
      status: 'PENDING',
    })
    expect(res.body.password).toBeUndefined()    // no sensitive field leakage

    // Assert — headers
    expect(res.headers['location']).toMatch(/\/api\/v1\/orders\/[0-9a-f-]+$/)
    expect(res.headers['content-type']).toMatch(/application\/json/)

    // Assert — idempotency: same key = same response, no duplicate
    const res2 = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', idempotencyKey)
      .send(payload)
    expect(res2.status).toBe(201)
    expect(res2.body.order_id).toBe(res.body.order_id)   // same order, not a new one
  })

  it('TC-068: missing items returns 422 with field error', async () => {
    const token = await getAuthToken('customer')
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({})    // no items

    expect(res.status).toBe(422)
    expect(res.body.code).toBe('VALIDATION_ERROR')
    expect(res.body.fields).toContainEqual(
      expect.objectContaining({ field: 'items', message: expect.any(String) })
    )
    expect(res.body.trace_id).toBeDefined()
    expect(res.body.trace_id).not.toBe('')
  })

  it('TC-069: unauthenticated request returns 401', async () => {
    const res = await request(app).post('/api/v1/orders').send(makeCreateOrderRequest())
    expect(res.status).toBe(401)
    expect(res.body.code).toBe('UNAUTHORIZED')
  })

  it('TC-070: wrong role returns 403', async () => {
    const token = await getAuthToken('admin')   // admin cannot place orders
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${token}`)
      .send(makeCreateOrderRequest())
    expect(res.status).toBe(403)
    expect(res.body.code).toBe('FORBIDDEN')
  })
})
```

---

## Step 7: E2E Test Implementation

```typescript
// TC-089: Journey: Customer — Successful Checkout
// REQ: CUSTOMER_JOURNEY.md Checkout + REQ-001, REQ-002, REQ-003
describe('Checkout Journey', () => {
  it('TC-089: customer completes checkout end-to-end', async () => {
    // Arrange — seed the full world
    const customer = await createTestCustomer()
    const product = await createTestProduct({ stock: 10, price: '50.00', currency: 'USD' })

    // Act — simulate journey steps
    const cart = await api.createCart(customer.token)
    await api.addToCart(cart.id, product.id, 2, customer.token)
    const order = await api.checkout(cart.id, customer.token)

    // Assert — outcome (what the persona achieved)
    expect(order.status).toBe('CONFIRMED')
    expect(order.items).toHaveLength(1)
    expect(order.total).toBe('100.00')

    // Assert — DB state (data persisted correctly)
    const dbOrder = await db.orders.findById(order.id)
    expect(dbOrder.customerId).toBe(customer.id)
    expect(dbOrder.status).toBe('CONFIRMED')

    // Assert — inventory side effect
    const updatedProduct = await db.products.findById(product.id)
    expect(updatedProduct.stock).toBe(8)

    // Assert — domain events published
    const events = await eventBus.getPublished()
    expect(events).toContainEqual(
      expect.objectContaining({ type: 'OrderPlaced', orderId: order.id })
    )
    expect(events).toContainEqual(
      expect.objectContaining({ type: 'InventoryReserved', orderId: order.id })
    )

    // Does NOT: charge payment twice
    const payments = await db.payments.findByOrderId(order.id)
    expect(payments).toHaveLength(1)
  })
})
```

---

## Step 8: Performance Test Implementation

```typescript
// TC-100: Performance: POST /orders meets NFR-001 latency targets under 100 concurrent users
// REQ: NFR-001 — p95 < 200ms at 50 rps
// k6 script
import http from 'k6/http'
import { check, sleep } from 'k6'
import { Rate, Trend } from 'k6/metrics'

const errorRate = new Rate('errors')
const orderCreationDuration = new Trend('order_creation_duration')

export const options = {
  scenarios: {
    sustained_load: {
      executor: 'constant-arrival-rate',
      rate: 50,                // 50 requests/second
      timeUnit: '1s',
      duration: '2m',          // sustained for 2 minutes
      preAllocatedVUs: 100,
    },
  },
  thresholds: {
    // TC-100 gates — test FAILS if not met
    'http_req_duration{name:create_order}': ['p(95)<200', 'p(99)<500'],
    'http_req_failed': ['rate<0.001'],      // < 0.1% error rate
    'errors': ['rate<0.001'],
  },
}

export default function () {
  const payload = JSON.stringify(makeOrderPayload())
  const res = http.post(`${BASE_URL}/api/v1/orders`, payload, {
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${AUTH_TOKEN}` },
    tags: { name: 'create_order' },
  })

  const ok = check(res, {
    'status is 201': (r) => r.status === 201,
    'response has order_id': (r) => JSON.parse(r.body).order_id !== undefined,
  })

  errorRate.add(!ok)
  orderCreationDuration.add(res.timings.duration)
  sleep(0.1)
}
```

---

## Step 9: Resilience Test Implementation

```typescript
// TC-110: Resilience: Circuit breaker trips on payment service failure
// REQ: ADR-005 — circuit breaker on payment gateway
describe('Resilience: Payment Service Circuit Breaker', () => {
  it('TC-110: circuit opens after failure threshold and fast-fails subsequent calls', async () => {
    // Arrange — mock payment service to fail
    paymentServiceMock.respondWith(503)
    const CIRCUIT_THRESHOLD = 10   // from CircuitBreaker config

    // Act — exhaust the circuit
    const results: number[] = []
    for (let i = 0; i < CIRCUIT_THRESHOLD + 5; i++) {
      const res = await api.post('/api/v1/orders/checkout', validPayload, customerToken)
      results.push(res.status)
    }

    // Assert — degraded but not crashed
    const successCount = results.filter(s => s === 201).length
    const degradedCount = results.filter(s => s === 422 || s === 503).length
    expect(degradedCount).toBeGreaterThan(0)

    // Assert — circuit is now open: fast fail (< 50ms, not timeout)
    paymentServiceMock.resetHistory()
    const start = Date.now()
    const fastFail = await api.post('/api/v1/orders/checkout', validPayload, customerToken)
    const duration = Date.now() - start
    expect(duration).toBeLessThan(50)   // fast fail, not wait for timeout
    expect(paymentServiceMock.callCount).toBe(0)   // circuit prevented the call

    // Assert — metrics
    const metrics = await getMetrics()
    expect(metrics['circuit_breaker_state{name="payment-service"}']).toBe(1)   // 1 = OPEN
  })

  it('TC-111: circuit recovers after open timeout', async () => {
    // Trip the circuit
    paymentServiceMock.respondWith(503)
    for (let i = 0; i < 15; i++) {
      await api.post('/api/v1/orders/checkout', validPayload, customerToken).catch(() => {})
    }

    // Wait for open timeout to elapse
    await jest.advanceTimersByTimeAsync(CIRCUIT_OPEN_TIMEOUT_MS + 100)

    // Restore service
    paymentServiceMock.respondWith(201)

    // Assert — half-open probe succeeds, circuit closes
    const res = await api.post('/api/v1/orders/checkout', validPayload, customerToken)
    expect(res.status).toBe(201)

    const metrics = await getMetrics()
    expect(metrics['circuit_breaker_state{name="payment-service"}']).toBe(0)   // 0 = CLOSED
  })
})
```

---

## Step 10: Observability Test Implementation

```typescript
// TC-120: Observability: create_order use case emits structured log with required fields
// REQ: OBSERVABILITY.md — Use Case Logging Standard
describe('Observability: create_order logging', () => {
  it('TC-120: emits INFO log with all required fields on success', async () => {
    // Arrange — capture logs
    const logCapture = new LogCapture()

    // Act
    await createOrderUseCase.execute(makeCreateOrderCommand({ traceId: 'test-trace-123' }))

    // Assert — log emitted
    const completionLog = logCapture.find({ action: 'create_order', outcome: 'success' })
    expect(completionLog).not.toBeNull()
    expect(completionLog.level).toBe('INFO')
    expect(completionLog.trace_id).toBe('test-trace-123')
    expect(completionLog.duration_ms).toBeGreaterThan(0)
    expect(completionLog.entity_id).toBeDefined()

    // Does NOT contain PII
    const logText = JSON.stringify(logCapture.all())
    expect(logText).not.toMatch(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)  // no email
    expect(logText).not.toMatch(/password/i)
    expect(logText).not.toMatch(/\b\d{16}\b/)   // no card number pattern
  })

  it('TC-121: increments usecase_executions_total metric on success', async () => {
    const before = await metrics.get('usecase_executions_total', { action: 'create_order', outcome: 'success' })

    await createOrderUseCase.execute(makeCreateOrderCommand())

    const after = await metrics.get('usecase_executions_total', { action: 'create_order', outcome: 'success' })
    expect(after - before).toBe(1)
  })
})
```

---

## Step 11: Test Data Factories

All factories in `tests/factories/`. Every factory has sensible defaults and overridable fields:

```typescript
// tests/factories/order.factory.ts
export function makeOrder(overrides: Partial<OrderProps> = {}): Order {
  return new Order({
    customerId: randomUUID(),
    items: [makeOrderItem()],
    ...overrides,
  })
}

export function makeOrderItem(overrides: Partial<OrderItemProps> = {}): OrderItem {
  return new OrderItem({
    productId: randomUUID(),
    quantity: 1,
    unitPrice: new Money(new Decimal('10.00'), 'USD'),
    ...overrides,
  })
}

export function makeCreateOrderRequest(overrides: Partial<CreateOrderRequest> = {}): CreateOrderRequest {
  return {
    items: [{ product_id: randomUUID(), quantity: 1, unit_price: '10.00', currency: 'USD' }],
    ...overrides,
  }
}
```

Rules:
- Never use hardcoded IDs — always `randomUUID()`
- Never use `new Date()` — use a fixed mock clock or a passed parameter
- Factories create valid objects by default (pass all invariants)
- Override only what the test cares about — other fields use defaults

---

## Step 12: Coverage Gate Configuration

Coverage gates must be enforced in CI. Configure in the test framework's coverage config:

```javascript
// jest.config.js (or vitest.config.ts)
module.exports = {
  coverageThreshold: {
    './src/domain/**': {
      lines:    90,   // domain: highest gate
      branches: 85,
      functions: 90,
    },
    './src/application/**': {
      lines:    90,
      branches: 85,
      functions: 90,
    },
    './src/infrastructure/**': {
      lines:    80,
      branches: 75,
    },
    global: {
      lines:    70,   // overall minimum
      branches: 65,
    },
  },
}
```

```yaml
# CI step — fails the build if coverage drops below thresholds
- name: Run tests with coverage
  run: npm test -- --coverage --ci
  # --ci flag: fails on any coverage threshold breach, no interactive prompts
```

**Per-layer gate enforcement:**
- `tests/contract/**`: every endpoint in API_SPEC.md must have a test — checked by comparing OpenAPI operation IDs to test file content
- `tests/e2e/**`: every P0 journey in TEST_CASES.md must have a corresponding test — checked by scanning TC-IDs

---

## Coverage Ratchet Enforcement

**Rule: Code coverage can never decrease. Any commit that lowers overall test coverage is rejected by CI.**

This is different from a coverage threshold (minimum). A ratchet means if you're at 82%, you stay at 82% or go higher — never 81%.

### CI Implementation

**Jest (JavaScript/TypeScript):**
```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: npm test -- --coverage --coverageReporters=json

- name: Coverage ratchet check
  run: |
    # Get current coverage from this run
    CURRENT=$(cat coverage/coverage-summary.json | node -e "
      const d = require('./coverage/coverage-summary.json');
      process.stdout.write(d.total.statements.pct.toString());
    ")
    # Get baseline from main branch artifact
    BASELINE=$(cat .coverage-baseline 2>/dev/null || echo "0")
    echo "Current: $CURRENT% | Baseline: $BASELINE%"
    if awk "BEGIN{exit !($CURRENT < $BASELINE)}"; then
      echo "COVERAGE RATCHET FAILED: Coverage dropped from ${BASELINE}% to ${CURRENT}%"
      echo "You must not decrease test coverage. Add tests for the code you changed."
      exit 1
    fi
    echo "Coverage ratchet passed: ${CURRENT}% >= ${BASELINE}%"

- name: Update coverage baseline on main
  if: github.ref == 'refs/heads/main'
  run: |
    CURRENT=$(cat coverage/coverage-summary.json | node -e "
      const d = require('./coverage/coverage-summary.json');
      process.stdout.write(d.total.statements.pct.toString());
    ")
    echo "$CURRENT" > .coverage-baseline
    git config user.email "ci@example.com"
    git config user.name "CI"
    git add .coverage-baseline
    git commit -m "chore: update coverage baseline to ${CURRENT}%" || true
    git push || true
```

**pytest (Python):**
```yaml
- name: Run tests with coverage
  run: pytest --cov=src --cov-report=json --cov-fail-under=$BASELINE_COVERAGE

- name: Coverage ratchet
  run: |
    CURRENT=$(python -c "import json; d=json.load(open('coverage.json')); print(d['totals']['percent_covered_display'])")
    BASELINE=$(cat .coverage-baseline 2>/dev/null || echo "0")
    python -c "import sys; c=float('$CURRENT'); b=float('$BASELINE'); sys.exit(0 if c >= b else 1)" || \
      (echo "Coverage dropped from ${BASELINE}% to ${CURRENT}%"; exit 1)
```

### Rules for Coverage Exceptions

If a PR legitimately reduces coverage (e.g., deleted a tested feature, removed a test file):

1. Author adds `coverage-exception: <reason>` to PR description
2. Reviewer explicitly approves the exception
3. CI reads the exception label and skips ratchet check for that PR
4. Exception is logged — too many exceptions signal a culture problem

### Coverage Targets Per Layer

Track coverage separately per layer (not just overall):

| Layer | Minimum | Ratchet | Rationale |
|-------|---------|---------|-----------|
| Domain entities | 95% | Yes | Core business logic, zero tolerance for bugs |
| Application use cases | 90% | Yes | Orchestration logic, must be fully tested |
| Infrastructure adapters | 70% | Yes | DB/HTTP adapters — integration tests cover partially |
| Delivery layer | 60% | No | Thin controllers — E2E tests cover the rest |
| Config/startup | 50% | No | Hard to unit test, covered by smoke tests |

Add per-layer coverage reporting to CI so regressions are visible per layer.

---

## Test Speed Budgets

Tests that are too slow don't get run. Enforce speed budgets:

| Test Layer | Max per test | Max for full suite | CI enforcement |
|-----------|-------------|-------------------|----------------|
| Unit | 100ms | 60 seconds | Hard fail if exceeded |
| Integration | 5 seconds | 5 minutes | Hard fail if exceeded |
| Contract | 10 seconds | 2 minutes | Hard fail if exceeded |
| E2E | 30 seconds | 15 minutes | Warn if exceeded |
| Performance | N/A (they're measuring time) | 30 minutes | N/A |

If a unit test exceeds 100ms: it's likely not actually a unit test (probably hitting DB or network). Investigate and fix.

Slow test detection in CI:
```yaml
# Jest example
jest --testTimeout=100 --forceExit

# pytest
pytest --timeout=5 tests/unit/
```

---

## Test Failure Artifacts

When tests fail in CI, capture these artifacts for debugging:

For E2E tests:
- Screenshot at point of failure (Playwright: `page.screenshot()` on test failure)
- Video of test run (Playwright: `video: 'retain-on-failure'`)
- Browser console logs captured
- Network request log (all XHR/fetch calls made during test)

For integration tests:
- Database state at time of failure (selected records from affected tables)
- Application logs from the test run

For all tests:
- Full test output (not just summary)
- Environment variables used (redacted for secrets)
- Timestamp and test machine info

CI configuration: store artifacts for 30 days, accessible from PR check link.

---

## Parallel Test Execution

Speed up test suites by running tests in parallel:

**Unit tests**: always safe to parallelize (each test is fully isolated)
**Integration tests**: parallelize only if each test gets its own DB schema or transaction rollback
**E2E tests**: parallelize with separate browser contexts; ensure test data doesn't conflict

```yaml
# Jest example (parallel workers)
jest --maxWorkers=50%

# pytest-xdist
pytest -n auto tests/unit/

# Playwright sharding
npx playwright test --shard=1/3  # Run on CI matrix
```

**Database isolation for parallel integration tests:**
- Option A: Transaction rollback — each test wraps in a transaction, never commits
- Option B: Schema per worker — each parallel worker gets a dedicated schema (test_1, test_2...)
- Option C: Container per worker — each worker gets its own DB container (slow but fully isolated)

Recommended: Option A (transaction rollback) for speed; Option C for tests that commit transactions explicitly.

---

## Step 13: Automation Completeness Audit

After implementing automation, run the completeness check:

```
For every TC-ID in TEST_CASES.md (excluding deprecated):
  Search test files for "TC-[NNN]" comment
  If not found → AUTOMATION GAP — log as CRITICAL finding

For every automated test:
  Verify it has a TC-ID comment
  Verify the TC-ID exists in TEST_CASES.md (not orphaned automation)
  If TC-ID not found in TEST_CASES.md → ORPHANED TEST — log as HIGH finding
```

Rules:
- No TC-ID without automation → CRITICAL finding, blocks release
- No automation without TC-ID → HIGH finding (automation without a requirement is untraceable)
- Orphaned automation (TC-ID deprecated but test not removed or deprecated) → MEDIUM

---

## Step 14: Drift Detection

After any test update, run the drift check to catch test cases that no longer match their source:

**Contract test drift:**
- For each contract test: does the response schema assertion still match API_SPEC.md?
- Flag: test asserts a field that was removed from API_SPEC → stale test, update it
- Flag: API_SPEC has a new required response field with no test assertion → missing coverage

**Unit test drift:**
- For each unit test: does the `When` call still match the current method signature?
- Flag: method renamed or parameters changed → test will fail to compile → update test case + TC GWT

**Requirement drift:**
- For each test with a REQ-ID reference: is that REQ-ID still active in PRODUCT_SPEC.md?
- Flag: REQ-ID deprecated → deprecate corresponding test cases

Run drift detection on every `/sdlc:10-test-automation` run, not just the first time.

---

## Step 15: Write Automation Index

**Update $ARTIFACTS/test-gen/test-automation.md:**

```markdown
# Test Automation
*Last Updated: [date]*

## Framework Stack
- Unit/Integration: [framework] — [file pattern]
- Contract:         [framework] — [file pattern]
- E2E:              [framework] — [file pattern]
- Performance:      [framework] — [file pattern]
- Resilience:       [framework] — [file pattern]

## Coverage Gates
- Domain (unit):     [N]% line / [N]% branch  (gate: 90% / 85%)  [PASS/FAIL]
- Application (unit):[N]% line / [N]% branch  (gate: 90% / 85%)  [PASS/FAIL]
- Infrastructure:    [N]% line                (gate: 80%)         [PASS/FAIL]
- API (contract):    [N]/[N] endpoints        (gate: 100%)        [PASS/FAIL]
- E2E P0 journeys:   [N]/[N] covered          (gate: 100%)        [PASS/FAIL]

## TC-ID Coverage
- Total TC-IDs in TEST_CASES.md: [N]
- Automated: [N] ([%])
- Automation gaps: [N] (listed below)

## Test Execution Commands
# Run all tests
[command]

# Run by layer
npm test -- --testPathPattern=unit
npm test -- --testPathPattern=integration
npm test -- --testPathPattern=contract
npm test -- --testPathPattern=e2e
npm run test:performance
npm run test:resilience

# Run single test by TC-ID
npm test -- --testNamePattern="TC-001"

# Run with coverage
npm test -- --coverage

## TC Coverage Index
| TC-ID | Layer | File | Test Name | Status |
|-------|-------|------|-----------|--------|
| TC-001 | Unit | src/domain/order.test.ts | TC-001: throws when items empty | ✅ |

## Automation Gaps
| TC-ID | Layer | Priority | Target File | Due |
|-------|-------|----------|-------------|-----|
| TC-045 | Integration | P1 | tests/integration/order-repo.test.ts | [date] |

## Factory Index
| Factory | File | Creates |
|---------|------|---------|
| makeOrder | tests/factories/order.ts | Order domain entity |
```

---

## Step 16: Update State

Mark Phase 10 (Test Automation) complete in $STATE.

Output:
```
✅ Test Automation Complete

Tests automated: [N] total
  Unit: [N] | Integration: [N] | Contract: [N] | E2E: [N]
  Performance: [N] | Resilience: [N] | Observability: [N] | Security: [N]

TC-ID coverage: [N]/[N] ([%])
Coverage: [N]% line / [N]% branch
All coverage gates: [PASS / FAIL — list failing gates]

Automation gaps: [N] (added to $STATE tasks if > 0)
Orphaned tests: [N] (resolved)
Drift findings: [N] (resolved)

Files:
• $ARTIFACTS/test-gen/test-automation.md
• [test files created/updated]

Recommended Next: /sdlc:verify --phase 10   ← run this before proceeding
Then:           /sdlc:observability
```
