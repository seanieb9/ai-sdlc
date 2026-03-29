---
name: sdlc:test-gaps
description: Test coverage gap analysis — maps requirements to test cases and identifies uncovered gaps [auto-chain after build]
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
Analyse test coverage by mapping every REQ-ID and acceptance criterion in prd.md to TC-IDs in test-cases.md. Identifies uncovered requirements (CRITICAL), missing test layers (WARN), API endpoints without contract tests, and thin coverage areas (INFO). Produces a structured gap report.

Auto-chain: runs automatically after build phase.
Condition: always.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/test-gaps.md
</execution_context>
