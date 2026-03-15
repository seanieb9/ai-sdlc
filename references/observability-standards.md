# Observability Standards Reference

## The Three Pillars

**Logs** — what happened (events, facts, errors)
**Traces** — how it happened (request flow, timing, causality)
**Metrics** — how often and how fast (counts, rates, durations)

All three are required. Any one alone is insufficient for production diagnosis.

---

## Logging Standard

### Mandatory JSON Fields

Every log entry must include ALL of these:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "INFO",
  "service": "order-service",
  "service_version": "2.1.0",
  "environment": "production",
  "host": "pod-abc-123",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "correlation_id": "req-f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "request_id": "api-gw-req-123",
  "action": "create_order",
  "outcome": "success",
  "message": "Order created successfully"
}
```

### Contextual Fields (add when applicable)

```json
{
  "user_id": "usr_hashed_abc123",
  "session_id": "sess_xyz",
  "entity_type": "order",
  "entity_id": "ord_456",
  "duration_ms": 142,
  "http_method": "POST",
  "http_path": "/api/v1/orders",
  "http_status": 201,
  "db_operation": "INSERT",
  "db_table": "orders",
  "error_type": "ValidationException",
  "error_code": "INVALID_ITEMS"
}
```

### Log Levels

| Level | When | Example |
|-------|------|---------|
| TRACE | Detailed flow for debugging, dev/staging only | "Entering loop iteration 3 of 10" |
| DEBUG | Diagnostic info for troubleshooting | "Cache miss for key: order-123" |
| INFO | Business events, state changes | "Order placed", "Payment processed" |
| WARN | Unexpected but handled | "Payment retry #2 initiated", "Fallback activated" |
| ERROR | Operation failed, needs attention | "Database write failed after 3 retries" |
| FATAL | Service cannot continue | "Cannot connect to database on startup" |

### What Never To Log

- Passwords, API keys, tokens, secrets
- Credit card numbers, CVV, full PAN
- SSN, passport numbers, government IDs
- Full email addresses (use hashed version)
- Personally identifiable medical information
- Private keys, certificates

---

## OpenTelemetry Tracing Standard

### Instrumentation Points

Auto-instrumented (framework-level):
- All HTTP incoming requests/responses
- All database queries (query, table, duration)
- All message queue operations (publish, consume)
- All outbound HTTP calls

Custom spans (add manually):
- Every use case/business operation
- Every significant business decision point
- Every external service call (if not auto-instrumented)
- Every cache operation

### Span Naming Convention

Format: `[service].[layer].[operation]`

Examples:
- `order-service.usecase.create_order`
- `order-service.repository.find_order_by_id`
- `order-service.adapter.payment_gateway.charge`
- `order-service.domain.order.calculate_total`

### Required Span Attributes

```
service.name        = "order-service"          (from config)
service.version     = "2.1.0"                  (from config)
deployment.environment = "production"           (from config)
user.id             = "hashed-user-id"          (never raw PII)
operation.name      = "create_order"
outcome             = "success" | "failure"
entity.type         = "order"                  (if applicable)
entity.id           = "ord_456"                (if available)
error               = true                     (on failure spans)
error.type          = "PaymentFailedException" (exception class)
```

### Trace Context Propagation

ALL outbound calls must include W3C TraceContext headers:
```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
tracestate:  vendor-specific-info
```

ALL inbound requests: read and continue trace context from headers.
ALL queue messages: embed trace context in message headers/attributes.

### Sampling Strategy

```
100% sample:  All requests with errors
100% sample:  All requests > p99 latency threshold
10% sample:   Successful requests (configurable via env var)
100% sample:  All trace IDs that began with error in any span
```

---

## Metrics Standard (Prometheus/OpenMetrics)

### RED Metrics (every service, every endpoint)

```
# Rate — how many requests per second
http_requests_total{service, method, route, status_code}

# Errors — how many failed
http_errors_total{service, method, route, error_type}

# Duration — how long
http_request_duration_seconds_bucket{service, method, route, le}
http_request_duration_seconds_sum{service, method, route}
http_request_duration_seconds_count{service, method, route}
```

### USE Metrics (infrastructure resources)

```
# Utilization
resource_utilization_ratio{service, resource_type}

# Saturation
db_connection_pool_utilization{service, pool}
queue_depth{service, queue_name}

# Errors
resource_errors_total{service, resource_type, error_type}
```

### Business Metrics (per domain)

Define at least 3-5 business metrics per service. Examples:
```
orders_created_total{status, channel}
payments_processed_total{outcome, payment_method, currency}
users_registered_total{channel, plan}
inventory_low_stock_items{warehouse}
```

### Metric Naming Conventions

- Use `_total` suffix for counters
- Use `_seconds` suffix for time (not milliseconds)
- Use `_bytes` suffix for sizes
- Use `_ratio` for percentages (0.0 to 1.0)
- Label values: lowercase with underscores
- Never use high-cardinality labels (user IDs, request IDs in metric labels)

---

## Health Endpoint Standard

### Required Endpoints

```
GET /health/live     → Liveness: is the process alive?
                       200 if yes, 503 if not
                       Kubernetes uses this for restart decisions

GET /health/ready    → Readiness: can it serve traffic?
                       200 if DB connected and dependencies available
                       503 if not ready (removes from load balancer)

GET /health/startup  → Startup: has initialization completed?
                       200 when ready, 503 during startup
                       Kubernetes uses to delay liveness probe

GET /metrics         → Prometheus text format (port 9090 or configured)
```

### Health Response Format

```json
{
  "status": "healthy",
  "version": "2.1.0",
  "uptime_seconds": 3600,
  "checks": {
    "database": { "status": "healthy", "latency_ms": 2 },
    "cache": { "status": "healthy", "latency_ms": 1 },
    "payment_gateway": { "status": "degraded", "message": "elevated latency" }
  }
}
```

Overall status: `healthy` | `degraded` | `unhealthy`
- `healthy`: all checks pass
- `degraded`: some non-critical checks failing (still serve traffic)
- `unhealthy`: critical check failed (remove from load balancer)

---

## Central Configuration Standard

All configuration from environment variables or config service. Never hardcoded.

### Config Categories

```
# Service identity (always required)
SERVICE_NAME=order-service
SERVICE_VERSION=2.1.0
ENVIRONMENT=production

# Database
DATABASE_URL=postgresql://...          (or from secrets manager)
DATABASE_POOL_SIZE=10
DATABASE_CONNECTION_TIMEOUT_MS=5000

# Observability
LOG_LEVEL=INFO
OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4317
OTEL_TRACES_SAMPLER_ARG=0.1
METRICS_PORT=9090

# Feature flags
FEATURE_NEW_CHECKOUT=false            (from config service, not env)

# External services
PAYMENT_GATEWAY_URL=https://...
PAYMENT_GATEWAY_TIMEOUT_MS=30000
```

### Startup Validation

At startup, validate ALL required config:

```python
REQUIRED_CONFIG = ['DATABASE_URL', 'SERVICE_NAME', 'ENVIRONMENT', 'OTEL_ENDPOINT']

def validate_config():
    missing = [k for k in REQUIRED_CONFIG if not os.getenv(k)]
    if missing:
        raise StartupError(f"Missing required config: {', '.join(missing)}")

    logger.info("Config validation passed", {"config_keys_present": len(REQUIRED_CONFIG)})
```

**Fail fast:** A service that starts without required config is worse than one that refuses to start.
