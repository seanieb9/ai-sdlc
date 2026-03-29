---
name: sdlc:adr-gen
description: ADR completeness validation — ensures all architectural decisions are documented [auto-chain after design]
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
Validate completeness of all Architecture Decision Records. Checks that each ADR has required sections, is back-referenced from tech-architecture.md, and has a specific review trigger. Creates stub ADRs for undocumented major decisions found in the architecture.

Auto-chain: runs automatically after design phase.
Condition: always (validates ADR completeness).
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/adr-gen.md
</execution_context>
