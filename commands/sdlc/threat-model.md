---
name: sdlc:threat-model
description: STRIDE threat modeling — identifies security threats across components [auto-chain after design]
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
Run STRIDE threat modeling against the current architecture. Identifies spoofing, tampering, repudiation, information disclosure, denial of service, and elevation of privilege threats per component. Produces a threat model with severity ratings, attack vectors, and mitigations mapped to ADRs.

Auto-chain: runs automatically after design phase.
Condition: architecture includes auth mechanisms or external service integrations.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/threat-model.md
</execution_context>
