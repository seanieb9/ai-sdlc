# Resilience Patterns Reference

Resilience is not bolted on — it is designed in. Every external call, every database operation, every queue interaction is a failure point. These patterns make failure survivable.

---

## Dependency Classification — Do This First

Before implementing any pattern, classify every dependency. The classification drives every other decision.

```
CRITICAL     Service cannot function at all without this dependency.
             Examples: primary database, auth service
             Strategy: retry aggressively, circuit break, alert immediately on failure
             On failure: return 503, do not serve stale/degraded response

DEGRADABLE   Service can continue with reduced capability without this dependency.
             Examples: recommendation engine, search index, notification service
             Strategy: circuit break fast, serve fallback, alert but don't page
             On failure: return partial response or safe default, log degradation

OPTIONAL     Nice-to-have enrichment. Core function is unaffected if unavailable.
             Examples: analytics events, A/B test logging, feature flag non-blocking reads
             Strategy: best-effort, fire-and-forget, silent failure
             On failure: skip silently, do not affect response or latency
```

Document the classification of every dependency in TECH_ARCHITECTURE.md. Every resilience decision flows from this.

---

## Timeouts — The Foundation

**A service without explicit timeouts will eventually hang.** This is not optional.

### Rule: Every outbound call needs two independent timeouts

```typescript
// Connect timeout: how long to wait to establish the connection
// Read timeout: how long to wait for the response after connection
// NEVER rely on OS defaults (can be minutes or infinite)

const client = new HttpClient({
  connectTimeout: 1_000,   // 1s to establish TCP connection
  readTimeout:    5_000,   // 5s to receive full response
  // Total max: connectTimeout + readTimeout = 6s
})
```

### Timeout values by dependency type

```
CRITICAL dependencies:    Set tight — you want to fail fast and try another replica
  DB query (simple):        connectTimeout: 500ms  | readTimeout: 2s
  DB query (complex):       connectTimeout: 500ms  | readTimeout: 10s
  Internal service (sync):  connectTimeout: 200ms  | readTimeout: 2s

DEGRADABLE dependencies:  Set even tighter — degrade fast, don't hold up the response
  External API:             connectTimeout: 500ms  | readTimeout: 3s
  Search/recommendation:    connectTimeout: 200ms  | readTimeout: 500ms

OPTIONAL dependencies:    Short timeout + fire-and-forget where possible
  Analytics event:          connectTimeout: 100ms  | readTimeout: 200ms
```

### Timeout budget propagation

When a request enters your service, it has a total time budget (from the caller's timeout or your SLO). Propagate the remaining budget to every downstream call:

```typescript
class RequestContext {
  constructor(
    public readonly traceId: string,
    public readonly deadlineMs: number,       // absolute epoch ms when this request expires
  ) {}

  remainingMs(): number {
    return Math.max(0, this.deadlineMs - Date.now())
  }

  isExpired(): boolean {
    return this.remainingMs() <= 0
  }

  // Apply before each downstream call
  timeoutForDownstreamCall(reserveMs = 100): number {
    const remaining = this.remainingMs() - reserveMs  // reserve headroom for own processing
    if (remaining <= 0) throw new DeadlineExceededException('Request deadline exceeded')
    return remaining
  }
}

// In use case: check before each external call
class PlaceOrderUseCase {
  async execute(command: PlaceOrderCommand): Promise<PlaceOrderResult> {
    if (command.context.isExpired()) {
      throw new DeadlineExceededException('Deadline exceeded before processing started')
    }

    const inventoryTimeout = command.context.timeoutForDownstreamCall()
    const stock = await this._inventoryPort.checkStock(
      command.items,
      { timeoutMs: inventoryTimeout }
    )
    // ...
  }
}
```

Pass deadlines via HTTP headers (`X-Request-Deadline: <epoch-ms>`) or gRPC context so downstream services can honour them too.

---

## Retry with Exponential Backoff and Jitter

### What to retry — strict rules

```
RETRY:
  ✅ Network errors (connection refused, connection reset, DNS failure)
  ✅ HTTP 408 Request Timeout
  ✅ HTTP 429 Too Many Requests (respect Retry-After header)
  ✅ HTTP 500 Internal Server Error (transient)
  ✅ HTTP 502 Bad Gateway
  ✅ HTTP 503 Service Unavailable (respect Retry-After header)
  ✅ HTTP 504 Gateway Timeout
  ✅ Idempotent operations only: GET, PUT, DELETE, HEAD, OPTIONS

DO NOT RETRY:
  ❌ HTTP 400 Bad Request — your request is wrong, retry won't fix it
  ❌ HTTP 401 Unauthorized — retry won't fix auth failure
  ❌ HTTP 403 Forbidden — retry won't fix authorization failure
  ❌ HTTP 404 Not Found — resource doesn't exist
  ❌ HTTP 409 Conflict — retry won't resolve conflict
  ❌ HTTP 422 Unprocessable Entity — validation failure
  ❌ Non-idempotent operations (POST) unless the endpoint is explicitly idempotent
  ❌ After the request context deadline has expired
```

### Implementation

```typescript
interface RetryConfig {
  maxAttempts: number       // total attempts (first try + retries)
  baseDelayMs: number       // initial backoff delay
  maxDelayMs: number        // cap — prevent multi-minute waits
  jitterFactor: number      // 0.0–1.0 — randomise to prevent thundering herd
  isRetryable: (error: Error) => boolean
}

const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts:   3,
  baseDelayMs:   100,
  maxDelayMs:    5_000,
  jitterFactor:  0.3,
  isRetryable: (err) => err instanceof NetworkError || err instanceof TransientServerError,
}

async function withRetry<T>(
  operation: () => Promise<T>,
  config: RetryConfig = DEFAULT_RETRY_CONFIG,
  context?: RequestContext,
): Promise<T> {
  let lastError: Error

  for (let attempt = 1; attempt <= config.maxAttempts; attempt++) {
    // Check deadline before each attempt
    if (context?.isExpired()) {
      throw new DeadlineExceededException('Deadline exceeded during retry loop')
    }

    try {
      return await operation()
    } catch (err) {
      lastError = err as Error

      const isLast = attempt === config.maxAttempts
      const retryable = config.isRetryable(lastError)

      if (isLast || !retryable) {
        logger.warn('retry.exhausted', {
          attempt,
          maxAttempts: config.maxAttempts,
          retryable,
          error: lastError.message,
        })
        throw lastError
      }

      const delay = calculateBackoff(attempt, config)
      logger.info('retry.attempt', { attempt, nextAttemptInMs: delay, error: lastError.message })
      await sleep(delay)
    }
  }

  throw lastError!
}

function calculateBackoff(attempt: number, config: RetryConfig): number {
  // Exponential: 100ms, 200ms, 400ms, 800ms, ...
  const exponential = config.baseDelayMs * Math.pow(2, attempt - 1)
  const capped = Math.min(exponential, config.maxDelayMs)

  // Full jitter: random value between 0 and capped
  // Full jitter outperforms equal jitter for reducing thundering herd
  const jitter = capped * config.jitterFactor * Math.random()
  return Math.floor(capped - jitter)
}
```

### Retry amplification warning

If service A retries 3×, and calls service B which retries 3×, and B calls C which retries 3× — one failing request becomes 27 attempts on C. Set retry budgets that account for the call chain depth. As a rule: **only the outermost caller should retry aggressively**. Inner services should retry at most once (or not at all) for synchronous chains.

---

## Circuit Breaker

### States and transitions

```
CLOSED ──(failure rate > threshold)──→ OPEN ──(timeout elapsed)──→ HALF-OPEN
  ↑                                                                      │
  └──────────────(probe request succeeds)────────────────────────────────┘
                                           (probe request fails) → OPEN
```

- **CLOSED**: normal operation. Track failure rate over a sliding window.
- **OPEN**: reject all requests immediately (fail fast). Do not call the dependency.
- **HALF-OPEN**: allow one probe request through. If it succeeds → CLOSED. If it fails → back to OPEN.

### Implementation

```typescript
enum CircuitState { CLOSED, OPEN, HALF_OPEN }

interface CircuitBreakerConfig {
  failureThreshold:    number    // % failure rate to trip: e.g. 50
  sampleSize:          number    // minimum requests before evaluating: e.g. 10
  openTimeoutMs:       number    // how long to stay OPEN before HALF-OPEN: e.g. 10_000
  halfOpenMaxCalls:    number    // concurrent probe calls allowed: e.g. 1
  successThreshold:    number    // successes needed in HALF-OPEN to close: e.g. 2
}

class CircuitBreaker<T> {
  private state = CircuitState.CLOSED
  private failures = 0
  private successes = 0
  private totalCalls = 0
  private openedAt: number | null = null

  constructor(
    private readonly name: string,
    private readonly config: CircuitBreakerConfig,
    private readonly metrics: MetricsClient,
  ) {}

  async execute(operation: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.openedAt! >= this.config.openTimeoutMs) {
        this.transitionTo(CircuitState.HALF_OPEN)
      } else {
        this.metrics.increment('circuit_breaker.rejected', { name: this.name })
        throw new CircuitOpenException(`Circuit ${this.name} is OPEN — fast failing`)
      }
    }

    try {
      const result = await operation()
      this.onSuccess()
      return result
    } catch (err) {
      this.onFailure()
      throw err
    }
  }

  private onSuccess(): void {
    this.totalCalls++
    if (this.state === CircuitState.HALF_OPEN) {
      this.successes++
      if (this.successes >= this.config.successThreshold) {
        this.transitionTo(CircuitState.CLOSED)
      }
    } else {
      // In CLOSED: reset failure count on success (sliding window resets)
      this.failures = Math.max(0, this.failures - 1)
    }
  }

  private onFailure(): void {
    this.failures++
    this.totalCalls++

    if (this.state === CircuitState.HALF_OPEN) {
      this.transitionTo(CircuitState.OPEN)
      return
    }

    if (
      this.totalCalls >= this.config.sampleSize &&
      (this.failures / this.totalCalls) * 100 >= this.config.failureThreshold
    ) {
      this.transitionTo(CircuitState.OPEN)
    }
  }

  private transitionTo(newState: CircuitState): void {
    const prev = this.state
    this.state = newState
    this.failures = 0
    this.successes = 0
    this.totalCalls = 0

    if (newState === CircuitState.OPEN) {
      this.openedAt = Date.now()
    }

    logger.warn('circuit_breaker.state_change', {
      name: this.name,
      from: CircuitState[prev],
      to: CircuitState[newState],
    })
    this.metrics.gauge('circuit_breaker.state', newState, { name: this.name })
    this.metrics.increment('circuit_breaker.transition', { name: this.name, to: CircuitState[newState] })
  }
}
```

### Configuration by dependency type

```typescript
// CRITICAL dependency — tolerate fewer failures, recover quickly
const dbCircuit = new CircuitBreaker('postgres', {
  failureThreshold:  30,      // trip at 30% failure rate
  sampleSize:        20,
  openTimeoutMs:     5_000,   // try again in 5s
  halfOpenMaxCalls:  1,
  successThreshold:  2,
}, metrics)

// DEGRADABLE dependency — trip faster, stay open longer
const recommendationCircuit = new CircuitBreaker('recommendation-service', {
  failureThreshold:  50,      // 50% failure rate
  sampleSize:        10,
  openTimeoutMs:     30_000,  // stay open 30s — don't hammer a struggling service
  halfOpenMaxCalls:  1,
  successThreshold:  1,
}, metrics)
```

### Wrapping retry + circuit breaker together

Order matters: **circuit breaker wraps retry** — not the other way around.

```typescript
// Correct: circuit breaker is outermost
const result = await circuitBreaker.execute(() =>
  withRetry(() => externalService.call(), retryConfig)
)

// Wrong: retry wraps circuit breaker — retries will re-open a tripped circuit
// const result = await withRetry(() => circuitBreaker.execute(...))  ← DON'T DO THIS
```

---

## Bulkhead

Isolate resource pools so that a slow/failing dependency cannot exhaust resources needed by other operations.

### Semaphore-based bulkhead (async/concurrent code)

```typescript
class Bulkhead {
  private inFlight = 0
  private readonly queue: Array<() => void> = []

  constructor(
    private readonly name: string,
    private readonly maxConcurrent: number,   // max simultaneous executions
    private readonly maxQueueSize: number,    // max waiting requests (0 = no queue)
    private readonly metrics: MetricsClient,
  ) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.inFlight >= this.maxConcurrent) {
      if (this.queue.length >= this.maxQueueSize) {
        this.metrics.increment('bulkhead.rejected', { name: this.name })
        throw new BulkheadFullException(`Bulkhead ${this.name} full — rejecting request`)
      }
      // Wait for a slot to open
      await new Promise<void>(resolve => this.queue.push(resolve))
    }

    this.inFlight++
    this.metrics.gauge('bulkhead.in_flight', this.inFlight, { name: this.name })

    try {
      return await operation()
    } finally {
      this.inFlight--
      const next = this.queue.shift()
      if (next) next()
      this.metrics.gauge('bulkhead.in_flight', this.inFlight, { name: this.name })
    }
  }
}

// Example: limit concurrent payment gateway calls
const paymentBulkhead = new Bulkhead('stripe', maxConcurrent: 10, maxQueueSize: 20, metrics)

await paymentBulkhead.execute(() => stripeAdapter.charge(amount, methodId))
```

### Database connection pool as a bulkhead

The DB connection pool IS a bulkhead. Size it correctly:

```
Pool size formula:  connections = (core_count * 2) + effective_spindle_count
Practical default:  min: 5  |  max: 20  (adjust based on load testing)

Connection acquire timeout:  500ms — fail fast if pool is exhausted
Connection idle timeout:     10 minutes — return idle connections to the pool
Connection max lifetime:     30 minutes — rotate connections to prevent stale state
```

```typescript
const pool = new Pool({
  connectionString: config.databaseUrl,
  min: 5,
  max: 20,
  acquireTimeoutMs: 500,      // throw PoolExhaustedException if no connection in 500ms
  idleTimeoutMs:   600_000,
  maxLifetimeMs:  1_800_000,
})

pool.on('error', (err) => {
  logger.error('db_pool.error', { error: err.message })
  metrics.increment('db_pool.error')
})
```

When pool is exhausted: throw `BulkheadFullException` → HTTP 503 with `Retry-After: 1` — do NOT queue indefinitely.

---

## Graceful Degradation

### Dependency-driven degradation

For every DEGRADABLE dependency, define its degradation contract at design time:

```typescript
interface DegradationContract<T> {
  dependency: string
  fallback: () => T | Promise<T>
  logLevel: 'warn' | 'error'
  emitMetric: string
}

async function withDegradation<T>(
  operation: () => Promise<T>,
  contract: DegradationContract<T>,
): Promise<T> {
  try {
    return await operation()
  } catch (err) {
    logger[contract.logLevel]('degradation.activated', {
      dependency: contract.dependency,
      error: (err as Error).message,
    })
    metrics.increment(contract.emitMetric)
    return contract.fallback()
  }
}

// Example: recommendations degrade to empty list
const recommendations = await withDegradation(
  () => recommendationService.getForUser(userId),
  {
    dependency: 'recommendation-service',
    fallback: () => [],             // safe empty default
    logLevel: 'warn',
    emitMetric: 'degradation.recommendations',
  }
)

// Example: user profile degrades to minimal data
const profile = await withDegradation(
  () => profileService.get(userId),
  {
    dependency: 'profile-service',
    fallback: () => ({ id: userId, name: 'Unknown', preferences: {} }),
    logLevel: 'warn',
    emitMetric: 'degradation.profile',
  }
)
```

### Stale cache fallback

For dependencies where slightly outdated data is acceptable:

```typescript
class StaleWhileRevalidateCache<T> {
  private cache = new Map<string, { value: T; cachedAt: number }>()

  async get(
    key: string,
    fetch: () => Promise<T>,
    options: { freshTtlMs: number; staleTtlMs: number },
  ): Promise<{ value: T; stale: boolean }> {
    const cached = this.cache.get(key)
    const now = Date.now()

    if (cached && now - cached.cachedAt < options.freshTtlMs) {
      return { value: cached.value, stale: false }   // fresh
    }

    if (cached && now - cached.cachedAt < options.staleTtlMs) {
      // Serve stale, revalidate in background
      this.revalidate(key, fetch, options).catch(err =>
        logger.warn('cache.revalidation_failed', { key, error: err.message })
      )
      return { value: cached.value, stale: true }   // stale but usable
    }

    // No cache or fully expired — must fetch
    const value = await fetch()
    this.cache.set(key, { value, cachedAt: now })
    return { value, stale: false }
  }

  private async revalidate(key: string, fetch: () => Promise<T>, options: any): Promise<void> {
    const value = await fetch()
    this.cache.set(key, { value, cachedAt: Date.now() })
  }
}
```

### Feature-flag-gated degradation

For controlled degradation under load:

```typescript
// In the use case — check flag before calling optional enrichment
if (await featureFlags.isEnabled('enrichment.recommendations', userId)) {
  order.recommendations = await withDegradation(
    () => recommendationService.get(userId),
    { fallback: () => [], ... }
  )
}
// If flag is disabled system-wide: skip the call entirely
```

---

## Load Shedding

When your service is overloaded, fast-reject excess requests — do not queue them to timeout.

### Request queue with depth limit

```typescript
class LoadShedder {
  private queueDepth = 0

  constructor(
    private readonly maxQueueDepth: number,   // reject when queue exceeds this
    private readonly metrics: MetricsClient,
  ) {}

  middleware() {
    return (req: Request, res: Response, next: NextFunction) => {
      if (this.queueDepth >= this.maxQueueDepth) {
        this.metrics.increment('load_shedder.rejected')
        logger.warn('load_shedder.rejected', { queueDepth: this.queueDepth })
        res.set('Retry-After', '5')
        return res.status(503).json({
          code: 'SERVICE_OVERLOADED',
          message: 'Service is temporarily overloaded. Please retry shortly.',
          trace_id: req.traceId,
        })
      }

      this.queueDepth++
      res.on('finish', () => { this.queueDepth-- })
      res.on('close', () => { this.queueDepth-- })
      next()
    }
  }
}
```

### Priority-based shedding

Not all requests are equal. Shed low-priority traffic first:

```typescript
function requestPriority(req: Request): 'critical' | 'normal' | 'low' {
  // Health checks: never shed
  if (req.path.startsWith('/health')) return 'critical'
  // Authenticated payment flows: never shed
  if (req.path.startsWith('/api/v1/payments') && req.user) return 'critical'
  // Authenticated users: normal
  if (req.user) return 'normal'
  // Unauthenticated: low priority
  return 'low'
}
```

---

## Rate Limiting

### Protecting your service (inbound)

```typescript
import { RateLimiter } from 'rate-limiter-flexible'

// Token bucket per client IP + per user
const rateLimiter = new RateLimiter({
  storeClient: redis,
  keyPrefix:   'rl',
  points:      100,          // 100 requests
  duration:    60,           // per 60 seconds
  blockDuration: 60,         // block for 60s after limit exceeded
})

// Stricter limits on auth endpoints (brute force protection)
const authRateLimiter = new RateLimiter({
  storeClient: redis,
  keyPrefix:   'rl_auth',
  points:      5,            // 5 attempts
  duration:    60 * 15,      // per 15 minutes
  blockDuration: 60 * 15,
})

async function rateLimitMiddleware(req: Request, res: Response, next: NextFunction) {
  const key = req.user?.id ?? req.ip
  try {
    await rateLimiter.consume(key)
    next()
  } catch (e) {
    const retryAfter = Math.ceil((e as any).msBeforeNext / 1000)
    res.set('Retry-After', String(retryAfter))
    res.set('X-RateLimit-Reset', String(Date.now() + (e as any).msBeforeNext))
    res.status(429).json({
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests. Please slow down.',
      retryAfterSeconds: retryAfter,
      trace_id: req.traceId,
    })
  }
}
```

### Respecting upstream rate limits (outbound)

```typescript
// When upstream returns 429, respect Retry-After and back off
async function callWithRateLimitRespect<T>(
  operation: () => Promise<T>,
): Promise<T> {
  try {
    return await operation()
  } catch (err) {
    if (err instanceof HttpError && err.status === 429) {
      const retryAfter = err.headers['retry-after']
      const waitMs = retryAfter
        ? parseInt(retryAfter) * 1000
        : 5_000    // default 5s if no header
      logger.warn('upstream.rate_limited', { waitMs })
      await sleep(waitMs)
      return operation()   // one retry after waiting
    }
    throw err
  }
}
```

---

## Database Resilience

### Query timeout enforcement

```typescript
// Every query must have an explicit timeout
await db.query(
  'SELECT * FROM orders WHERE customer_id = $1',
  [customerId],
  { queryTimeoutMs: 2_000 }   // kill query if not done in 2s
)
```

### Read replica failover

```typescript
class ResilienceAwareDatabase {
  constructor(
    private readonly primary: Database,
    private readonly replica: Database | null,
  ) {}

  async query<T>(sql: string, params: unknown[], options: QueryOptions = {}): Promise<T> {
    const db = options.replica && this.replica ? this.replica : this.primary

    try {
      return await db.query(sql, params, options)
    } catch (err) {
      // On replica failure, fall back to primary for reads
      if (options.replica && this.replica && err instanceof ConnectionError) {
        logger.warn('db.replica_fallback', { error: (err as Error).message })
        metrics.increment('db.replica_fallback')
        return this.primary.query(sql, params, options)
      }
      throw new InfrastructureException(`Database query failed: ${(err as Error).constructor.name}`)
    }
  }
}
```

### Optimistic locking — concurrent modification

```typescript
class PostgresOrderRepository implements OrderRepository {
  async save(order: Order): Promise<void> {
    const result = await this.db.query(
      `UPDATE orders
       SET status = $1, updated_at = now(), version = version + 1
       WHERE id = $2 AND version = $3`,
      [order.status, order.id, order.version]
    )

    if (result.rowCount === 0) {
      throw new ConflictException(
        'Order was modified by another process. Please reload and retry.',
        'CONCURRENT_MODIFICATION'
      )
    }
  }
}
```

---

## Cascading Failure Prevention

Cascading failure happens when the failure of one service causes others to fail, which cause others to fail.

**The pattern that causes cascading failure:**
1. Service B becomes slow
2. Service A's connection pool fills with threads waiting on B
3. Service A becomes slow/unavailable
4. Service C (which calls A) is now also starved
5. Full cascade

**Prevention — the combination required:**

| Layer | Pattern | Prevents |
|-------|---------|---------|
| Connection level | Explicit timeouts | Threads blocked indefinitely |
| Call level | Circuit breaker | Continued calls to failing service |
| Concurrency level | Bulkhead | Pool exhaustion spreading across paths |
| Response level | Graceful degradation | Propagating failure as errors |
| Ingress level | Load shedding | Queueing to timeout under overload |

All five must be present. Partial implementation is significantly less effective than the full combination.

**Minimum viable resilience per external call:**
```typescript
// Every external call: timeout + circuit breaker + retry (for idempotent) + degradation (for DEGRADABLE)
const result = await withDegradation(
  () => circuitBreaker.execute(
    () => withRetry(
      () => externalClient.call({ timeoutMs: context.timeoutForDownstreamCall() }),
      retryConfig,
      context,
    )
  ),
  degradationContract,
)
```

---

## Chaos Engineering — Validate Resilience

Resilience patterns that are never tested under real failure conditions provide false confidence.

### Failure injection tests (implement in test suite)

```typescript
describe('Resilience: Inventory Service', () => {
  it('degrades gracefully when inventory service is unavailable', async () => {
    inventoryServiceMock.respondWith(503)

    const result = await api.post('/api/v1/orders', validOrderPayload)

    // Should complete successfully with degraded response
    expect(result.status).toBe(201)
    expect(result.body.inventoryReserved).toBe(false)   // degraded state
    expect(result.body.status).toBe('PENDING_INVENTORY')
  })

  it('trips circuit breaker after threshold failures', async () => {
    inventoryServiceMock.respondWith(500)

    // Exhaust the circuit
    for (let i = 0; i < 20; i++) {
      await api.post('/api/v1/orders', validOrderPayload).catch(() => {})
    }

    // Verify circuit is open — subsequent calls should fast-fail
    const start = Date.now()
    await api.post('/api/v1/orders', validOrderPayload).catch(() => {})
    const duration = Date.now() - start

    expect(duration).toBeLessThan(50)   // circuit open = fast fail, not timeout
    expect(metrics.get('circuit_breaker.rejected', { name: 'inventory-service' })).toBeGreaterThan(0)
  })

  it('recovers when service comes back', async () => {
    inventoryServiceMock.respondWith(500)
    // Trip the circuit
    for (let i = 0; i < 20; i++) {
      await api.post('/api/v1/orders', validOrderPayload).catch(() => {})
    }

    // Wait for open timeout + restore service
    await sleep(circuitConfig.openTimeoutMs + 100)
    inventoryServiceMock.respondWith(200)

    const result = await api.post('/api/v1/orders', validOrderPayload)
    expect(result.status).toBe(201)
    expect(result.body.inventoryReserved).toBe(true)    // fully recovered
  })
})
```

### Runbook: manual chaos testing checklist

Before declaring a service production-ready, verify each failure mode manually:
- [ ] Kill the database — does the service return 503 and recover when DB comes back?
- [ ] Kill a DEGRADABLE dependency — does the service degrade and continue serving?
- [ ] Saturate the connection pool — does the service shed load rather than hang?
- [ ] Send requests faster than the service can handle — does load shedding activate?
- [ ] Cut network to an external service for 10s — does circuit breaker trip and recover?
- [ ] Send a SIGTERM — does the service drain in-flight requests gracefully?

---

## Resilience Checklist — Per Service

Use this before declaring any service production-ready:

```
TIMEOUTS
  [ ] Connect timeout set on every outbound call
  [ ] Read timeout set on every outbound call
  [ ] DB query timeout set on all queries
  [ ] Request deadline propagated to downstream calls

RETRY
  [ ] Retry only on retryable errors (network, 408, 429, 5xx)
  [ ] Not retrying non-idempotent operations without idempotency key
  [ ] Exponential backoff with jitter implemented
  [ ] Max attempts bounded
  [ ] Total retry time fits within request budget

CIRCUIT BREAKER
  [ ] Every CRITICAL and DEGRADABLE external dependency has a circuit breaker
  [ ] State changes emit metrics and logs
  [ ] Config appropriate for dependency criticality
  [ ] Circuit breaker wraps retry (not inside retry)

BULKHEAD
  [ ] DB connection pool sized and configured with acquire timeout
  [ ] Concurrent external calls bounded (semaphore or pool)
  [ ] Pool exhaustion throws BulkheadFullException → 503, not queues indefinitely

DEGRADATION
  [ ] Every DEGRADABLE dependency has a documented fallback
  [ ] Fallback returns safe default, not error
  [ ] Degradation events are logged and metered
  [ ] OPTIONAL dependencies fail silently

LOAD SHEDDING
  [ ] Inbound request queue has depth limit
  [ ] 503 with Retry-After returned when limit exceeded
  [ ] Load shedding metered

RATE LIMITING
  [ ] Inbound rate limits applied (per user/IP)
  [ ] Auth endpoints have stricter limits
  [ ] Upstream 429 responses handled with backoff

GRACEFUL SHUTDOWN
  [ ] SIGTERM handler drains in-flight requests
  [ ] DB pool closed cleanly on shutdown
  [ ] Message broker connection closed on shutdown
  [ ] Timeout forces exit after grace period

CHAOS TESTED
  [ ] DB failure mode tested
  [ ] DEGRADABLE dependency failure tested
  [ ] Circuit breaker trip and recovery tested
  [ ] Load shedding activation tested
  [ ] Graceful shutdown tested
```
