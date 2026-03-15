# Observability Standards
*Service: {{SERVICE_NAME}} | Last Updated: {{DATE}}*

---

## Logging

### Mandatory Fields (every log entry)

```json
{
  "timestamp": "ISO 8601 UTC",
  "level": "INFO",
  "service": "{{service-name}}",
  "service_version": "{{semver}}",
  "environment": "{{env}}",
  "trace_id": "W3C trace ID",
  "span_id": "W3C span ID",
  "correlation_id": "request-scoped UUID",
  "request_id": "API gateway request ID",
  "action": "operation name",
  "outcome": "success | failure",
  "message": "human readable, no PII"
}
```

### Log Level Guide

| Level | When |
|-------|------|
| DEBUG | Diagnostic, dev/staging only |
| INFO | Business events, state changes |
| WARN | Unexpected but handled |
| ERROR | Operation failed |
| FATAL | Cannot continue |

---

## Distributed Tracing (OpenTelemetry)

### Span Naming
`{{service}}.{{layer}}.{{operation}}`

### Auto-Instrumented
- HTTP requests/responses
- Database operations
- Queue publish/consume

### Custom Spans Required
- Every use case: `{{service}}.usecase.{{use_case_name}}`
- Every external service call
- Every significant business decision

### Context Propagation
Outbound: inject `traceparent` and `tracestate` W3C headers
Inbound: read and continue W3C trace context

---

## Metrics

### RED Metrics (all endpoints)
```
http_requests_total{service, method, route, status_code}
http_errors_total{service, method, route, error_type}
http_request_duration_seconds_bucket{service, method, route, le}
```

### Business Metrics
| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| {{metric_name}}_total | Counter | {{labels}} | {{description}} |

---

## Configuration

```
SERVICE_NAME={{service-name}}
SERVICE_VERSION={{version}}
ENVIRONMENT={{env}}
LOG_LEVEL=INFO
OTEL_EXPORTER_OTLP_ENDPOINT=http://{{collector}}:4317
OTEL_TRACES_SAMPLER_ARG=0.1
METRICS_PORT=9090
```

---

## Health Endpoints

```
GET /health/live   → 200 alive | 503 not alive
GET /health/ready  → 200 ready | 503 not ready
GET /metrics       → Prometheus text format
```

---

## Alerting Rules

| Alert | Condition | Severity |
|-------|-----------|---------|
| HighErrorRate | error_rate > 5% (5m) | Warning |
| CriticalErrorRate | error_rate > 10% (5m) | Critical |
| HighLatency | p99 > 2s (5m) | Warning |
| ServiceDown | up == 0 | Critical |
