---
name: sdlc:observability
description: Enterprise-grade observability — structured logging, OpenTelemetry distributed tracing, Prometheus metrics, central config, full E2E traceability.
argument-hint: "[service/scope] [--update]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Implement enterprise-grade observability. This is not optional. Full E2E traceability is a requirement, not a nice-to-have.

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/tech-architecture.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/observability/observability.md (update, never recreate)
  - .claude/ai-sdlc/codebase/architecture.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/observability/observability.md

Deliverables:
  - Structured logging spec (log levels, required fields, PII masking rules)
  - OpenTelemetry distributed tracing (span naming conventions, propagation, sampling)
  - Prometheus metrics (counters, gauges, histograms — RED method per service)
  - Alerting rules (SLO-based, with severity and escalation path)
  - Dashboard specs (Grafana layout, panel definitions)
  - Central observability config (environment-aware, no hardcoded endpoints)
  - E2E trace coverage: every user-facing request must be traceable start to finish
</objective>

<context>
Service/scope: $ARGUMENTS

Flags:
  --update   Update existing observability spec (add new services, update alert thresholds)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/observability.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 11 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
