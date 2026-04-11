# Observability Workflow

Implement enterprise-grade observability. This is not optional. Full E2E traceability is a requirement, not a nice-to-have.

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

## Step 1: Read Context

Read in parallel:
- `$ARTIFACTS/design/tech-architecture.md` — services, components, integration points
- `$ARTIFACTS/design/api-spec.md` — endpoints to instrument
- `$ARTIFACTS/data-model/data-model.md` — entities and operations to track
- `$ARTIFACTS/observability/observability.md` — existing standards (if any)
- `$STATE` — tech stack, constraints (read and parse JSON)

Identify:
- All services to instrument
- All external integrations (each needs spans)
- All critical business operations (each needs metrics)
- Existing logging/tracing setup (if any — extend, don't replace)

## Step 2: Define Logging Standards

**Mandatory structured log fields (JSON, every entry):**

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",   // ISO 8601, UTC
  "level": "INFO",                            // TRACE|DEBUG|INFO|WARN|ERROR|FATAL
  "service": "order-service",                 // service name from config
  "version": "1.2.3",                         // semantic version
  "environment": "production",                // from env var
  "trace_id": "abc123def456",                 // W3C trace ID (propagated)
  "span_id": "789xyz",                        // current span ID
  "correlation_id": "req-uuid-here",          // request-scoped ID
  "request_id": "api-req-uuid",               // API gateway request ID
  "user_id": "usr_abc123",                    // hashed/anonymized if PII concern
  "action": "create_order",                   // what is happening
  "outcome": "success",                       // success|failure|in_progress
  "duration_ms": 142,                         // for completed operations
  "message": "Order created successfully"     // human-readable, no PII
}
```

**Additional fields by context:**
- HTTP requests: `method`, `path`, `status_code`, `request_size_bytes`, `response_size_bytes`
- Database: `db_operation`, `table`, `rows_affected`, `query_duration_ms`
- Queue: `queue_name`, `message_id`, `attempt_number`
- External calls: `target_service`, `target_endpoint`, `http_status`

**Log level guide:**
- TRACE: detailed flow (dev/staging only, never production by default)
- DEBUG: diagnostic data useful for troubleshooting
- INFO: business operations, state changes, lifecycle events
- WARN: unexpected but handled situations (fallback used, retry triggered)
- ERROR: operation failed, requires attention (with full error context)
- FATAL: service cannot continue, immediate action required

**Strict rules:**
- NEVER log PII (name, email, SSN, card numbers, passwords, tokens)
- NEVER log secrets or credentials
- NEVER use string interpolation — use structured fields
- ALWAYS log at entry AND exit of use case boundaries
- ALWAYS include trace context in every log entry

### Log Redaction Rules

The following field types MUST NEVER appear in logs (redact or mask at the logging layer):

| Category | Examples | Masking Rule |
|---------|---------|-------------|
| Passwords / secrets | password, secret, token, api_key, private_key | Replace entirely: [REDACTED] |
| Payment card data | card_number, cvv, pan | Keep first 6 + last 4: 411111******1234 |
| Social security / tax IDs | ssn, tax_id, sin | Replace entirely: [REDACTED] |
| Personal health info | diagnosis, medication, health_condition | Replace entirely: [REDACTED-PHI] |
| Full email addresses in prod | email | Mask domain: u***@domain.com |
| Authentication tokens | bearer tokens, session IDs, refresh tokens | Replace entirely: [REDACTED] |
| Private keys / certificates | -----BEGIN PRIVATE KEY----- | Replace entirely: [REDACTED-KEY] |

Implementation: apply masking at the logging middleware level, not ad-hoc per call site. Create a `sanitize(obj)` utility function that all structured loggers call before writing.

Validation: the pii-audit auto-chain verifies these rules are in place after every build.

## Step 3: Distributed Tracing (OpenTelemetry)

**Instrumentation points:**
- Every HTTP request/response (auto-instrumented via OTel HTTP instrumentation)
- Every database operation (auto-instrumented via OTel DB instrumentation)
- Every queue publish/consume operation
- Every external HTTP call
- Every business use case (custom span)
- Every significant business event (custom span with attributes)

**Custom span standard:**
```
Span name: "[service].[layer].[operation]" (e.g., "order-service.usecase.create_order")
Attributes:
  - service.name: from config
  - service.version: from config
  - operation.name: use case name
  - user.id: hashed user ID (never raw PII)
  - entity.type: "order" (what entity is being operated on)
  - entity.id: ID if available after creation
  - outcome: "success" | "failure"
  - error.type: if failure (exception class name)
```

**Trace propagation:**
- Incoming: read W3C `traceparent` and `tracestate` headers
- Outgoing: inject W3C `traceparent` and `tracestate` into all outbound calls
- Queue messages: include trace context in message headers/attributes
- Sampling: 100% errors + slow requests (> p99 threshold), 10% of successful requests (configurable)

## Step 4: Metrics (Prometheus/OpenMetrics)

**RED metrics for every service endpoint:**
```
# Rate
http_requests_total{service, method, path, status_code}

# Errors
http_errors_total{service, method, path, error_type}
http_error_rate = rate(http_errors_total[5m]) / rate(http_requests_total[5m])

# Duration
http_request_duration_seconds{service, method, path, quantile}
http_request_duration_seconds_bucket{service, method, path, le}
```

**Use case / business operation metrics:**
```
usecase_executions_total{service, usecase, outcome}
usecase_duration_seconds{service, usecase, quantile}
```

**Business metrics (define per domain):**
```
# Examples — define actual metrics per business domain
orders_created_total{status}
payments_processed_total{outcome, payment_method}
users_registered_total{channel}
```

**Infrastructure metrics:**
```
db_connections_active{service, db}
db_query_duration_seconds{service, operation, table}
cache_hits_total{service, cache_type}
cache_misses_total{service, cache_type}
queue_messages_published_total{service, queue}
queue_messages_consumed_total{service, queue, outcome}
queue_depth{queue}
```

### Custom Business Metrics

Beyond the standard RED metrics (Rate, Errors, Duration), define domain-specific metrics that measure business outcomes:

For each significant business operation, define:

```
Metric name: [snake_case_metric_name]_total (counter) or [name]_duration_seconds (histogram)
Labels: [label names — keep cardinality low, max ~20 values per label]
What it measures: [business meaning]
Alert condition: [when should this fire an alert]
Dashboard placement: [which dashboard section]
```

Minimum custom metrics required:
- `[entity]_created_total` counter (with `status` label: success/failed)
- `[entity]_processing_duration_seconds` histogram for any async processing
- `active_[entity]_count` gauge for key business objects
- `[critical_external_call]_duration_seconds` histogram for each external API call

Example:
```
Metric: orders_created_total
Labels: status=success|failed, channel=web|mobile|api
Meaning: How many orders are being placed (and how many fail)
Alert: if orders_created_total{status="failed"} / orders_created_total > 0.05 (5% failure rate)
```

## Step 5: Central Configuration

All observability config (and all service config) from environment or config service:

```
# Logging
LOG_LEVEL=INFO                          # TRACE|DEBUG|INFO|WARN|ERROR
LOG_FORMAT=json                         # json|text (text for local dev)

# Tracing
OTEL_EXPORTER_OTLP_ENDPOINT=http://...  # OTel collector endpoint
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1             # 10% sampling rate

# Metrics
METRICS_PORT=9090                       # Prometheus scrape port
METRICS_PATH=/metrics

# Service identity
SERVICE_NAME=order-service
SERVICE_VERSION=1.2.3
ENVIRONMENT=production
```

**Startup validation:**
At service startup, validate ALL required config is present. If not, fail fast with a clear error message listing what's missing. Never start with default secrets.

## Step 6: Health Endpoints

Every service must expose:

```
GET /health/live     → 200 if process is alive, 503 if not (used by Kubernetes liveness)
GET /health/ready    → 200 if can serve traffic (DB connected, dependencies ready), 503 if not
GET /health/startup  → 200 if initial startup complete
GET /metrics         → Prometheus text format metrics
```

Health check response:
```json
{
  "status": "healthy",
  "version": "1.2.3",
  "checks": {
    "database": "healthy",
    "cache": "healthy",
    "queue": "degraded"
  }
}
```

## Step 7: Alerting Rules

Define base alerting rules (document in OBSERVABILITY.md):

```yaml
# High error rate
- alert: HighErrorRate
  expr: rate(http_errors_total[5m]) / rate(http_requests_total[5m]) > 0.05
  severity: warning (> 5%) | critical (> 10%)

# High latency
- alert: HighLatency
  expr: http_request_duration_seconds{quantile="0.99"} > 2.0
  severity: warning (> 2s) | critical (> 5s)

# Service down
- alert: ServiceDown
  expr: up == 0
  severity: critical (immediate)

# Disk/memory pressure
- alert: HighMemoryUsage
  expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.85
  severity: warning
```

### Alerting Strategy

**Alert fatigue prevention rules:**
1. Every alert MUST have a runbook link — no alert without documented response procedure
2. Every alert MUST be actionable — if there's nothing to do, it shouldn't fire
3. Alerts are grouped by severity: P1 (page immediately), P2 (page within 30 min), P3 (ticket created)
4. Alert windows: use multi-minute windows to avoid flapping (minimum 2/5-minute evaluation windows)

**SLO-to-Alert mapping:**

For each SLO defined in the SRE phase, create:
1. **Burn rate alert (fast burn)**: alert when error budget burns at 14x normal rate over 1 hour
2. **Burn rate alert (slow burn)**: alert when error budget burns at 2x normal rate over 6 hours

```
SLO: [name, e.g., API Availability 99.9%]
Error budget: 0.1% = 43.8 minutes/month
Fast burn alert: error rate > 14.4% over 5 minutes → P1
Slow burn alert: error rate > 2.88% over 1 hour → P2
Exhaustion alert: error budget < 10% remaining → P2 (ticket)
```

**Minimum alert set for every service:**
| Alert | Condition | Severity | Runbook |
|-------|-----------|---------|---------|
| Service down | /health/live returning non-200 for 2 minutes | P1 | [runbook link] |
| Error rate spike | 5xx rate > 5% for 5 minutes | P1 | [runbook link] |
| High latency | p95 > [2x SLO target] for 10 minutes | P2 | [runbook link] |
| Error budget burn | Burning at 14x rate | P1 | [runbook link] |
| Disk space | > 85% used | P2 | [runbook link] |
| Memory pressure | > 90% used | P2 | [runbook link] |
| Certificate expiry | < 30 days to expiry | P2 | [runbook link] |

## Step 8: Write Output Document

**Create/update $ARTIFACTS/observability/observability.md:**

```markdown
# Observability Standards
*Last Updated: [date]*

## Logging Standard
[Mandatory fields, log levels, rules, examples]

## Distributed Tracing
[OTel setup, span naming, propagation, sampling]

## Metrics Catalog
[All metrics defined, with labels and types]

## Configuration Reference
[All env vars, config service keys]

## Health Endpoints
[Endpoints and response formats]

## Alerting Rules
[Alert definitions and thresholds]

## Implementation Guide
[How to instrument a new service]
[How to add a new business metric]
[How to add a new custom span]
```

## Step 9: Implementation

After writing the standards document, implement in the codebase:

1. Add OTel SDK dependencies
2. Create logging utility/library (wraps logger with mandatory fields)
3. Create tracing utility (span creation helper with standard attributes)
4. Create metrics registry (all metrics defined in one place)
5. Add middleware for HTTP auto-instrumentation
6. Add DB instrumentation
7. Instrument all use case boundaries
8. Add health endpoints
9. Add config validation at startup
10. Verify: send test request, check logs are structured JSON, check trace appears in collector, check metrics endpoint

## Step 10: Update State

Mark Phase 11 (Observability) complete in $STATE.

Output:
```
✅ Observability Complete

Services Instrumented: [N]
Metrics Defined: [N]
Custom Spans: [N]
Health Endpoints: implemented

Files:
• $ARTIFACTS/observability/observability.md
• [implementation files]

Recommended Next: the SRE phase (tell Claude to proceed)
```
