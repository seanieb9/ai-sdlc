---
name: sdlc:pii-audit
description: PII observability audit — verifies PII fields are excluded or masked in all log entries [auto-chain after build]
argument-hint: "[--auto-chain]"
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
Cross-reference PII fields from data-model.md against OBS-NNN log entries in observability.md and source file logging statements. Identifies cases where PII is logged unmasked (CRITICAL), unverified (WARN), or could be improved (INFO). Produces a PII audit report.

Auto-chain: runs automatically after build phase.
Condition: observability phase completed (observability.md exists).
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/pii-audit.md
</execution_context>
