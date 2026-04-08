---
name: sdlc:11-observability
description: Design and implement enterprise-grade observability — structured logging, OpenTelemetry distributed tracing, Prometheus metrics, central config, full E2E traceability.
argument-hint: "<service/feature> [--logging] [--tracing] [--metrics] [--config] [--audit]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - Task
  - AskUserQuestion
  - WebFetch
---

<objective>
Implement enterprise-grade observability ensuring full E2E traceability across all services.

Manages:
  - docs/sre/OBSERVABILITY.md — standards, implementation guide, configuration reference
  - Observability implementation in source code

Three pillars:

LOGGING (Structured JSON):
  Mandatory fields on every log entry:
    timestamp (ISO 8601), level, service, version, environment,
    trace_id, span_id, correlation_id, request_id,
    user_id (if authenticated), session_id (if applicable),
    action, outcome, duration_ms (for operations)
  Log levels: TRACE (dev only) | DEBUG | INFO | WARN | ERROR | FATAL
  Rules: No PII in logs, no secrets, structured not interpolated strings

TRACING (OpenTelemetry):
  - Auto-instrumentation for HTTP, DB, queue operations
  - Custom spans for all business operations (use case boundaries)
  - Trace context propagated via W3C TraceContext headers
  - Span attributes: service, operation, user_id (hashed), result
  - All external calls (API, DB, cache, queue) wrapped in spans
  - Trace sampling: 100% errors, 10% success (configurable)

METRICS (Prometheus/OpenMetrics):
  RED metrics for every service endpoint:
    Rate (requests/sec), Errors (error rate %), Duration (p50/p95/p99 latency)
  Business metrics: defined per domain (e.g., orders_created, payments_processed)
  Resource metrics: CPU, memory, connections, queue depth
  Alerting rules: defined in OBSERVABILITY.md

CENTRAL CONFIG:
  - All config from environment variables or config service (AWS SSM / Vault / etc.)
  - No hardcoded URLs, credentials, feature flags
  - Config validation at startup (fail fast on missing required config)
  - Secrets never logged
</objective>

<context>
Service/feature: $ARGUMENTS

Flags:
  --logging     Focus on logging standards and implementation
  --tracing     Focus on distributed tracing setup
  --metrics     Focus on metrics and alerting
  --config      Focus on central configuration management
  --audit       Audit existing code for observability gaps
</context>

<execution_context>
@~/.claude/sdlc/workflows/observability.md
@~/.claude/sdlc/references/observability-standards.md
@~/.claude/sdlc/templates/observability.md
@~/.claude/sdlc/references/doc-writing-standards.md
@~/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 11 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

