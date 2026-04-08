---
name: sdlc:12-sre
description: SRE practices — runbooks, SLOs/SLAs, incident response, capacity planning, reliability patterns. Requires observability to be defined first.
argument-hint: "<service/area> [--runbook] [--slo] [--incident] [--reliability-review]"
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
Define and document SRE practices for enterprise-grade reliability.

Manages:
  - docs/sre/RUNBOOKS.md — operational runbooks for every critical process
  - docs/sre/SLO.md — Service Level Objectives and error budgets
  - docs/sre/INCIDENT_RESPONSE.md — incident classification, escalation, post-mortems

SRE deliverables:

SERVICE LEVEL OBJECTIVES:
  - Define SLOs for each service (availability, latency, error rate)
  - Error budget policy (what happens when budget is consumed)
  - SLO monitoring queries (Prometheus/PromQL)
  - Customer-facing SLAs derived from internal SLOs

RUNBOOKS (one per critical operation):
  - When to use this runbook (trigger conditions)
  - Prerequisites and access requirements
  - Step-by-step procedure with verification at each step
  - Expected outcomes and how to verify success
  - Rollback procedure
  - Escalation path

RELIABILITY PATTERNS:
  - Circuit breakers for all downstream dependencies
  - Retry with exponential backoff and jitter
  - Bulkhead isolation for critical paths
  - Graceful degradation strategies
  - Health check endpoints (liveness, readiness, startup)

INCIDENT RESPONSE:
  - Severity classification (SEV1/2/3/4)
  - On-call rotation and escalation matrix
  - Communication templates
  - Post-mortem process and template
</objective>

<context>
Service/area: $ARGUMENTS

Flags:
  --runbook           Create/update runbook for specific operation
  --slo               Define or review SLOs
  --incident          Set up incident response process
  --reliability-review Audit existing code for reliability gaps
</context>

<execution_context>
@~/.claude/sdlc/workflows/sre.md
@~/.claude/sdlc/references/resilience-patterns.md
@~/.claude/sdlc/references/observability-standards.md
@~/.claude/sdlc/references/process.md
@~/.claude/sdlc/references/doc-writing-standards.md
@~/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 12 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

