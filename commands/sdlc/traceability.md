---
name: sdlc:traceability
description: Requirements traceability matrix — bidirectional REQ↔TC↔ADR↔SLO coverage map [auto-chain after test-cases]
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
Build a bidirectional traceability matrix linking requirements to test cases, architecture decisions, and observability targets. Surfaces orphaned test cases with no source requirement and requirements with no test coverage. Provides the full NFR → ADR → TC → SLO chain.

Auto-chain: runs automatically after test-cases phase.
Condition: always.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/traceability.md
</execution_context>
