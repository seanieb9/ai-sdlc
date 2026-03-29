---
name: sdlc:ci-verify
description: CI pipeline completeness gate — verifies required jobs exist before deploy [auto-chain after deploy]
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
Gate check for the deploy phase. Verifies that a CI pipeline exists and contains the required jobs: build, test with coverage, lint, and security scan. Checks that coverage thresholds are enforced and the pipeline runs on both PRs and main branch pushes. Hard FAIL if no CI config found.

Auto-chain: runs automatically after deploy phase (as gate check).
Condition: deploy phase requires CI to pass.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/ci-verify.md
</execution_context>
