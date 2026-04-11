# SRE Workflow

Define service reliability objectives, runbooks, and incident response. This makes operations predictable and reduces MTTR.

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

## Step 1: Pre-Flight

Read:
- `$ARTIFACTS/observability/observability.md` — metrics and alerting (must exist)
- `$ARTIFACTS/design/tech-architecture.md` — services and dependencies
- `$ARTIFACTS/idea/prd.md` — NFRs (availability, latency targets)
- `$STATE` — constraints (read and parse JSON)

If observability.md missing: WARN — SRE is less meaningful without observability defined.

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

## Incident SLA Matrix

| Severity | Definition | Time to Acknowledge (TTA) | Time to Mitigate (TTM) | Post-Mortem |
|----------|-----------|--------------------------|----------------------|-------------|
| SEV1 | Complete outage, data loss risk, active security breach, revenue stopped | 5 minutes | 1 hour | Required — within 4 hours of resolution |
| SEV2 | Partial outage, major feature unavailable, >5% error rate, SLO breach | 15 minutes | 2 hours | Required — within 24 hours |
| SEV3 | Degraded performance, minor feature unavailable, elevated errors (not SLO breach) | 1 hour | 8 hours | Required — within 48 hours |
| SEV4 | Minor issue, no current user impact, warning signs | Next business day | Next sprint | Optional — recommended for patterns |

SLA enforcement:
- TTA is measured from when the alert fires to when the on-call acknowledges in the alerting tool
- TTM (mitigation) means users are no longer impacted — full root cause fix can follow asynchronously
- If TTA is missed: auto-escalate to on-call lead + engineering manager
- If TTM is missed: auto-escalate to director/VP level for SEV1, engineering manager for SEV2

For solo developers: TTA and TTM targets still apply. If you cannot meet them, adjust your SLOs to match reality.

## Post-Mortem Process

Every SEV1, SEV2, and SEV3 incident requires a post-mortem. No exceptions.

### Required Post-Mortem Fields

```markdown
# Post-Mortem: [Incident Title]
*Severity: SEV[N]*
*Date: [date]*
*Duration: [start → end]*
*Impact: [number of users affected, revenue impact, feature unavailability]*

## Timeline (chronological)
| Time | Event |
|------|-------|
| HH:MM | Alert fired |
| HH:MM | On-call acknowledged |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Resolved |

## Root Cause
[ONE specific root cause — not "our system failed" but "the connection pool was exhausted because the retry logic did not respect the backoff window"]

## Contributing Factors
[What made this worse or allowed it to happen]

## What Went Well
[Genuinely honest — detection was fast, rollback worked, team communicated well]

## What Went Wrong
[What we wish had happened differently]

## Action Items

| Item | Owner | Priority | Due Date | Status |
|------|-------|----------|----------|--------|
| [specific fix] | [name] | P1/P2/P3 | [date] | Open |

Priorities:
- P1: Fix within current sprint (1-2 weeks) — prevents recurrence of this exact incident
- P2: Fix within 2 sprints — reduces risk significantly
- P3: Fix in backlog — nice-to-have improvement

## Closure Criteria
This post-mortem is CLOSED when:
- [ ] All P1 action items completed and verified
- [ ] Root cause fix deployed and confirmed working
- [ ] Runbook updated with new knowledge
- [ ] Alert thresholds reviewed (were we warned early enough?)
```

### Repeated Incident Policy

If the same root cause occurs 3 times in 90 days:
1. Escalate to engineering lead immediately
2. Block all non-critical work until systemic fix is implemented
3. Root cause is classified as a "chronic reliability issue"
4. Add to technical debt register with P1 priority

### Post-Mortem Tracking

Maintain an incident log: `$ARTIFACTS/sre/incident-log.md`

| Date | Severity | Title | Duration | Root Cause | Status | Action Items Closed |
|------|---------|-------|----------|-----------|--------|---------------------|
| [date] | SEV[N] | [title] | [mins] | [one-liner] | Open/Closed | [N/N] |

Review open post-mortems weekly. Close only when all P1 items are verified complete.

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

Document this table in `$ARTIFACTS/sre/runbooks.md` under "Dependency Registry".

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

After implementing, run the per-service resilience checklist from `resilience-patterns.md`. Every item must be checked. Any unchecked item is a known reliability risk — document it as a task in $STATE with risk level.

### 5k: Chaos test each failure mode

For each dependency, test the failure path:
- Kill/mock the dependency as unavailable
- Verify the service degrades correctly (not 500s)
- Verify circuit breaker trips after threshold
- Verify circuit breaker recovers when dependency comes back
- Verify load shedding activates under saturation
- Verify SIGTERM drains gracefully

Add these as integration tests tagged `[resilience]` so they can be run in CI.

---

## Capacity Planning + Load Testing

Every service must be load tested before production deployment. "It works on my machine" is not sufficient.

### Step 5l: Load Testing Requirements

**Required for:**
- All production deployments (first time)
- Any deployment that changes request handling, DB queries, or scaling config
- Any deployment after 3x growth in user count

**Load test plan template:**

```yaml
# k6 load test configuration
scenarios:
  baseline:
    executor: constant-arrival-rate
    rate: [BASELINE_RPS]  # Expected normal load
    timeUnit: '1s'
    duration: '5m'
    preAllocatedVUs: 20

  peak:
    executor: constant-arrival-rate
    rate: [BASELINE_RPS * 2]  # 2x expected peak
    timeUnit: '1s'
    duration: '15m'  # Sustained — not just a spike
    preAllocatedVUs: 50
    startTime: '6m'

  stress:
    executor: ramping-arrival-rate
    stages:
      - duration: '2m', target: [BASELINE_RPS * 3]
      - duration: '5m', target: [BASELINE_RPS * 3]
      - duration: '2m', target: 0

thresholds:
  http_req_duration:
    - 'p(50) < [P50_TARGET_MS]'
    - 'p(95) < [P95_TARGET_MS]'  # From NFRs
    - 'p(99) < [P99_TARGET_MS]'
  http_req_failed:
    - 'rate < 0.001'  # < 0.1% error rate

checks: [health_check, auth_endpoint, primary_endpoint]
```

**Pass criteria (all must pass):**
- [ ] p95 latency within NFR target at 2x peak load
- [ ] Error rate < 0.1% at 2x peak load
- [ ] Memory usage stable (no upward trend over 15-minute sustained test)
- [ ] CPU < 80% at peak load (headroom for spikes)
- [ ] No DB connection pool exhaustion (check pool metrics during test)
- [ ] No leaked goroutines/threads (check after test, not during)
- [ ] Graceful behavior at 3x peak: either handles it or returns 429 — never crashes

**If any check fails:**
1. Profile: identify bottleneck (CPU, DB, network, memory)
2. Fix: add cache, optimize query, increase pool size, scale horizontally
3. Re-test: run full suite again
4. Document: what was the bottleneck, what was the fix, what headroom exists now

**Capacity headroom documentation (required output):**

```markdown
## Capacity Report

Baseline load:   [N] rps
Peak tested:     [N] rps (2x baseline)
System limit:    ~[N] rps (estimated from stress test — point where p99 > NFR or errors spike)
Headroom:        [N]x (system_limit / baseline)

Performance at peak:
  p50: [N]ms (target: [N]ms) ✅/❌
  p95: [N]ms (target: [N]ms) ✅/❌
  p99: [N]ms (target: [N]ms) ✅/❌
  Errors: [N]% (target: < 0.1%) ✅/❌

Bottleneck: [if found — e.g., "DB query on /search endpoint, takes 180ms at peak, needs index"]
Scaling plan: [what to do when we approach 80% of system_limit]
```

Save to: `$ARTIFACTS/sre/capacity-report.md`

---

## Chaos Engineering Plan

Adapt complexity based on team size from $STATE projectAssumptions.teamSize:
- solo-developer: skip formal chaos plan; document manual resilience tests
- small-team/enterprise: full chaos schedule below

### Chaos Experiment Catalog

For each critical dependency, define a chaos experiment:

```
Experiment: [Name, e.g., "Database Connection Loss"]
Target: [what is being disrupted]
Hypothesis: "When [condition], the system will [expected behavior]"
Method: [how to introduce the failure — e.g., Toxiproxy network timeout, kill container, block port]
Duration: [how long to run the experiment — typically 5-15 minutes]
Success criteria: [what passing looks like — e.g., "circuit breaker opens within 30s, fallback serves stale data"]
Rollback: [how to restore normal state immediately]
Frequency: [monthly / quarterly]
```

Minimum experiments (run quarterly):
1. Primary database connection loss
2. Cache (Redis/Memcached) unavailable
3. Downstream service timeout (slowness, not failure)
4. Single pod/instance crash (restart recovery)
5. High CPU load (at 90% capacity)
6. Disk full simulation (if applicable)

### Chaos Experiment Schedule Template

| Experiment | Frequency | Last Run | Next Due | Owner | Result |
|-----------|-----------|----------|----------|-------|--------|
| DB connection loss | Quarterly | - | [date] | [name] | - |
| Cache unavailable | Quarterly | - | [date] | [name] | - |
| Downstream timeout | Monthly | - | [date] | [name] | - |

---

## Disaster Recovery Plan

### RTO and RPO Targets
*(from NFRs in product spec)*

| Scenario | RTO | RPO | Validated |
|---------|-----|-----|-----------|
| Primary database failure | [target] | [target] | Never / [date] |
| Full region outage | [target] | [target] | Never / [date] |
| Accidental data deletion | [target] | [target] | Never / [date] |
| Application service crash | [target] | [target] | Never / [date] |

### Backup Verification Schedule

- Database backup: daily automated + weekly manual restore test
- Weekly restore test procedure:
  1. Identify most recent backup
  2. Restore to isolated test environment
  3. Verify data integrity (record count, spot check key records)
  4. Measure restore time (compare against RTO)
  5. Document result in this table

| Test Date | Backup Taken | Restore Time | Data Integrity | Pass/Fail |
|-----------|-------------|--------------|----------------|-----------|
| [date] | [backup timestamp] | [duration] | [verified] | ✅/❌ |

### Failover Runbook

If primary [database/service/region] becomes unavailable:
1. Detection: alert fires in [monitoring tool] for [metric] exceeding [threshold]
2. Confirm failure: [verification command/check]
3. Execute failover: [exact steps — commands, URLs, procedures]
4. Verify failover successful: [health check / smoke test]
5. Notify stakeholders: [channels, message template]
6. Document incident: [incident tracking tool/procedure]
7. Post-incident: schedule post-mortem within 48 hours

---

## Incident Communication Plan

### Status Page
[Link to status page, or "Not configured — configure one at statuspage.io / atlassian / etc."]

### Communication Templates

**SEV1 — Customer-impacting outage (send within 15 minutes):**
```
Subject: [Service Name] — Service Disruption — [Start Time]

We are aware of an issue affecting [service/feature]. Our team is actively investigating.

Impact: [what users cannot do]
Started at: [time]
We will provide an update by: [time + 30 minutes]

We apologize for the inconvenience.
— [Team Name]
```

**SEV1 Update (every 30 minutes):**
```
Subject: [Service Name] — Update #[N] — [Start Time]

We continue to investigate the issue affecting [service/feature].

Current status: [what we know, what we've tried]
ETA to resolution: [estimate or "unknown, still investigating"]
Next update by: [time + 30 minutes]
```

**Resolution:**
```
Subject: [Service Name] — Resolved — [Start Time] → [End Time]

The issue affecting [service/feature] has been resolved.

Duration: [N hours N minutes]
Root cause: [brief description]
What we're doing to prevent recurrence: [action items]

Thank you for your patience.
— [Team Name]
```

### Escalation Matrix

| Severity | Who is notified | Within | Channel |
|---------|----------------|--------|---------|
| SEV1 | [list] | 15 min | [channel] |
| SEV2 | [list] | 30 min | [channel] |
| SEV3 | [list] | 2 hours | [channel] |
| SEV4 | [list] | Next business day | [channel] |

---

## Step 6: Write Output Documents

**$ARTIFACTS/sre/runbooks.md** — all runbooks
**$ARTIFACTS/sre/slo.md** — SLO definitions, error budgets, monitoring queries
**$ARTIFACTS/sre/incident-response.md** — severity guide, response process, post-mortem template

## Step 7: Update State

Mark Phase 12 (SRE) complete in $STATE.

Output:
```
✅ SRE Complete

Services with SLOs: [N]
Runbooks written: [N]
Incident response: defined

Files:
• $ARTIFACTS/sre/runbooks.md
• $ARTIFACTS/sre/slo.md
• $ARTIFACTS/sre/incident-response.md

Recommended Next: the review phase (tell Claude to proceed)
```
