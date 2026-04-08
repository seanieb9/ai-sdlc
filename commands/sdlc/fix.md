---
name: sdlc:fix
description: Fix bugs, apply hotfixes, or do maintenance. Lighter path — no spec update unless a design gap is found.
argument-hint: "<what's broken> [--hotfix] [--maintenance]"
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
Lightweight fix path for bugs, production hotfixes, and maintenance tasks. Creates a FIX-NNN tracking record, generates a scoped implementation plan, runs the appropriate subset of phases, and adds regression test coverage.

Flags:
- `--hotfix` — production incident mode: fastest path (plan → build → verify → deploy), no test-gen
- `--maintenance` — tech debt / dependency upgrade: plan → build → test-cases → verify
- Default (no flag): bug fix path: plan → build → test-cases → verify
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/fix.md
@/Users/seanlew/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
