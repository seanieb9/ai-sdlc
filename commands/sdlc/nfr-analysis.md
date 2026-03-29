---
name: sdlc:nfr-analysis
description: NFR decomposition — translates non-functional requirements into architectural implications [auto-chain after idea]
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
Decompose NFR-NNN entries from the PRD into concrete architectural patterns, ADR requirements, test layer assignments, and SLO candidates. Each NFR is traced to the architectural decision it demands, flagging which require dedicated ADRs in the design phase.

Auto-chain: runs automatically after idea phase.
Condition: prd.md has NFR-NNN entries.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/nfr-analysis.md
</execution_context>
