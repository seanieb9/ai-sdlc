# SRE Workflow

Define service reliability objectives, runbooks, and incident response. This makes operations predictable and reduces MTTR.

## Step 1: Pre-Flight

Read:
- `docs/sre/OBSERVABILITY.md` — metrics and alerting (must exist)
- `docs/architecture/TECH_ARCHITECTURE.md` — services and dependencies
- `docs/product/PRODUCT_SPEC.md` — NFRs (availability, latency targets)
- `.sdlc/STATE.md` — constraints

If OBSERVABILITY.md missing: WARN — SRE is less meaningful without observability defined.

## Step 2: Define Service Level Objectives

For each service, define SLOs:

**Template per service:**
```
Service: [name]

Availability SLO: 99.9% uptime (43.8 min/month downtime budget)
Latency SLO:      p99 < 500ms, p95 < 200ms, p50 < 50ms
Error Rate SLO:   < 0.1% error rate on successful requests
Throughput SLO:   [N] requests/sec sustained

Error Budget:
  Monthly budget: 43.8 minutes downtime
  Budget burn rate alert: 2x over 1hr → page, 5x over 5min → page immediately

SLO Monitoring:
  Availability: 1 - (rate(http_errors_total[30d]) / rate(http_requests_total[30d]))
  Latency: histogram_quantile(0.99, http_request_duration_seconds_bucket[5m])
```

SLO targets come from PRODUCT_SPEC.md NFRs. If not specified, use:
- Standard: 99.9% availability, p99 < 1s
- Critical path: 99.95% availability, p99 < 500ms
- Background jobs: 99% availability, best-effort latency

## Step 3: Write Runbooks

For each critical operational procedure, write a runbook.

**Required runbooks (minimum):**
1. Service deployment
2. Service rollback
3. Database migration
4. High error rate investigation
5. High latency investigation
6. Service restart / recovery
7. Incident communication template

**Runbook format:**
```markdown
## Runbook: [Name]
*Trigger: [when to use this runbook]*
*Owner: [team/role]*
*Last Tested: [date]*

### Prerequisites
- [ ] Access to [system]
- [ ] [Tool] installed and configured

### Procedure

#### Step 1: [Verify the situation]
```[command to diagnose]```
Expected output: [what you should see]
If unexpected: [what to do]

#### Step 2: [Take action]
```[command]```
Expected: [outcome]

#### Step N: Verify resolution
```[verification command]```
Expected: [what healthy looks like]

### Rollback
If procedure fails or worsens situation:
```[rollback command]```

### Escalation
- If unresolved in 30min: escalate to [role]
- If customer impact: trigger incident process (see INCIDENT_RESPONSE.md)

### Notes
[Known quirks, gotchas, context]
```

## Step 4: Incident Response Process

Define in docs/sre/INCIDENT_RESPONSE.md:

**Severity classification:**
```
SEV1 (Critical):   Complete service outage, data loss risk, security breach
                   Response: immediate (< 5 min), all hands
SEV2 (High):       Partial outage, major feature unavailable, > 5% error rate
                   Response: < 30 min, on-call + lead
SEV3 (Medium):     Degraded performance, non-critical feature down
                   Response: < 2 hrs, on-call
SEV4 (Low):        Minor degradation, no user impact yet
                   Response: next business day
```

**Response flow:**
1. Detect (alert fires or user reports)
2. Acknowledge (on-call acknowledges within SLA)
3. Assess severity (classify SEV1-4)
4. Communicate (notify stakeholders per severity)
5. Investigate (use runbooks)
6. Mitigate (reduce impact)
7. Resolve (fix root cause)
8. Post-mortem (within 48hrs for SEV1/2)

**Post-mortem template:**
```
Incident: [title]
Date: [date] | Duration: [how long]
Severity: SEV[N]
Author: [who wrote this]

## Impact
[Who was affected, how many, what couldn't they do]

## Timeline
[Chronological: detected → mitigated → resolved]

## Root Cause
[Actual root cause — not the symptom]

## Contributing Factors
[What made this worse or harder to detect]

## What Went Well
[What helped resolve quickly]

## Action Items
- [ ] [Preventive action] | Owner: [person] | Due: [date]
```

## Step 5: Resilience Implementation

This step implements resilient code. Do not skip it and do not treat it as a review checklist — write the code here or verify it exists with the correct implementation.

Reference: `resilience-patterns.md` is loaded in context with full implementation patterns for every item below.

### 5a: Classify all dependencies

Before writing any resilience code, classify every external dependency this service calls:

```
For each dependency in TECH_ARCHITECTURE.md:
  Name: [service/DB/queue/external API]
  Classification: CRITICAL | DEGRADABLE | OPTIONAL
  Fallback (if DEGRADABLE/OPTIONAL): [what to return when unavailable]
  Timeout connect: [ms]
  Timeout read:    [ms]
```

Document this table in `docs/sre/RUNBOOKS.md` under "Dependency Registry".

### 5b: Implement timeouts on every outbound call

For every external call in the codebase (Grep for HTTP clients, DB clients, queue clients):
- Set explicit connect timeout AND read timeout
- Verify no call relies on OS default timeouts
- Implement deadline propagation via RequestContext if service makes multiple downstream calls

Timeout values follow the dependency classification:
- CRITICAL: tight timeouts (DB simple query 2s, internal service 2s)
- DEGRADABLE: tighter (external API 3s, search/recommendation 500ms)
- OPTIONAL: shortest (analytics 200ms)

### 5c: Implement retry with backoff

For every CRITICAL and DEGRADABLE dependency:
- Implement `withRetry()` using exponential backoff + full jitter
- Define `isRetryable()` filter — only retry network errors, 408, 429, 503, 504
- Set max attempts (3 for most cases)
- Verify retry is NOT applied to non-idempotent operations (POST without idempotency key)
- Verify total retry time fits within the request's deadline budget

### 5d: Implement circuit breakers

For every CRITICAL and DEGRADABLE dependency:
- Wrap with `CircuitBreaker` (see resilience-patterns.md for implementation)
- Configure thresholds appropriate to classification:
  - CRITICAL: failureThreshold 30%, openTimeout 5s (fail fast, recover fast)
  - DEGRADABLE: failureThreshold 50%, openTimeout 30s (degrade fast, recover slower)
- Ensure circuit breaker WRAPS retry — not the other way around
- Verify state transitions emit metrics: `circuit_breaker.state`, `circuit_breaker.transition`, `circuit_breaker.rejected`

### 5e: Implement bulkheads

For DB and every external service with a connection pool:
- Configure connection pool with explicit min/max, acquire timeout, idle timeout, max lifetime
- Acquire timeout must throw `BulkheadFullException` → 503, never queue indefinitely
- For async services: implement semaphore-based bulkhead limiting concurrent calls per dependency

DB pool sizing: `(core_count × 2) + effective_spindle_count` — minimum 5, maximum 20 (adjust post load testing).

### 5f: Implement graceful degradation

For every DEGRADABLE dependency:
- Implement `withDegradation()` wrapper with explicit fallback value
- Fallback must be a safe default (empty list, minimal object, cached stale value) — not an error
- Degradation events must be logged at WARN level and metered (`degradation.{dependency}`)
- For OPTIONAL dependencies: wrap in try/catch with silent failure + metric only

### 5g: Implement load shedding

For the HTTP delivery layer:
- Add `LoadShedder` middleware with configurable `maxQueueDepth`
- Return 503 with `Retry-After: 5` when limit exceeded
- Instrument: `load_shedder.rejected` metric
- Starting threshold: maxQueueDepth = `maxReplicas × expectedConcurrentRequestsPerPod`

### 5h: Implement rate limiting

For all public and authenticated API endpoints:
- Add inbound rate limiter (token bucket, per user ID or IP)
- Apply stricter limits to auth endpoints (login, token refresh, password reset)
- Store rate limit state in Redis (not in-memory — state must survive pod restart and be shared across replicas)
- Return 429 with `Retry-After` header and machine-readable error code

### 5i: Verify graceful shutdown

The SIGTERM handler must be implemented (see microservices reference):
- Stop accepting new connections
- Wait for in-flight requests to complete
- Close DB pool cleanly
- Close message broker connection
- Flush pending telemetry
- Force exit after grace period (terminationGracePeriodSeconds − 5s)

### 5j: Run resilience checklist

After implementing, run the per-service resilience checklist from `resilience-patterns.md`. Every item must be checked. Any unchecked item is a known reliability risk — document it as a TODO in `.sdlc/TODO.md` with risk level.

### 5k: Chaos test each failure mode

For each dependency, test the failure path:
- Kill/mock the dependency as unavailable
- Verify the service degrades correctly (not 500s)
- Verify circuit breaker trips after threshold
- Verify circuit breaker recovers when dependency comes back
- Verify load shedding activates under saturation
- Verify SIGTERM drains gracefully

Add these as integration tests tagged `[resilience]` so they can be run in CI.

## Step 6: Write Output Documents

**docs/sre/RUNBOOKS.md** — all runbooks
**docs/sre/SLO.md** — SLO definitions, error budgets, monitoring queries
**docs/sre/INCIDENT_RESPONSE.md** — severity guide, response process, post-mortem template

## Step 7: Update State

Mark Phase 12 (SRE) complete.

Output:
```
✅ SRE Complete

Services with SLOs: [N]
Runbooks written: [N]
Incident response: defined

Files:
• docs/sre/RUNBOOKS.md
• docs/sre/SLO.md
• docs/sre/INCIDENT_RESPONSE.md

Recommended Next: /sdlc:13-review
```
