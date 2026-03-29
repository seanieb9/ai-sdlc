---
name: sdlc:review
description: Cross-cutting quality audit — 12 dimensions across requirements, data model, architecture, tests, resilience, observability, security, and deployment readiness.
argument-hint: "[area] [--full] [--arch] [--data] [--test] [--obs] [--code]"
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
Cross-cutting quality audit across 12 dimensions. Checks that all SDLC artifacts are consistent, complete, and internally coherent before shipping.

Dimensions: requirements traceability, data model integrity, architecture compliance, API contract coverage, test coverage and pyramid shape, observability completeness, SRE runbook coverage, resilience pattern implementation, security controls, deployment readiness, documentation quality, and code quality.
</objective>

<context>
Input: $ARGUMENTS — optional area to focus on

Flags:
  --full     Full 12-dimension audit (default)
  --arch     Architecture and data model only
  --data     Data model integrity only
  --test     Test coverage and traceability only
  --obs      Observability and SRE only
  --code     Code quality and security only
</context>

<execution_context>
@~/.claude/sdlc/workflows/review.md
@~/.claude/sdlc/workflows/workspace-resolution.md
@~/.claude/sdlc/references/clean-architecture.md
@~/.claude/sdlc/references/testing-standards.md
</execution_context>
