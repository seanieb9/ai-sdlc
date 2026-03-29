---
name: sdlc:prr
description: Production Readiness Review — mandatory gate before production deployment. Verifies runbooks, observability, resilience, security, scalability, and team readiness.
argument-hint: "[--staging] [--production]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Formal Production Readiness Review (PRR). Every system must pass PRR before deploying to production. Checks: runbook completeness, observability, resilience patterns, security posture, scalability (load test results), team readiness, data compliance.

Outcome: APPROVED | APPROVED WITH CONDITIONS | REJECTED

Flags:
  --staging     Run a lighter PRR for staging (skip capacity + compliance checks)
  --production  Full PRR (default for production)
</objective>

<context>
Input: $ARGUMENTS — optional deployment target flag

Gate: Requires verification-report.md with 0 open CRITICAL findings.
</context>

<execution_context>
@~/.claude/sdlc/workflows/prr.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
