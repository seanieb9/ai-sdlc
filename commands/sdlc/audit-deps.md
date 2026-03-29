---
name: sdlc:audit-deps
description: Dependency audit — scans for CVEs, outdated packages, unused deps, license issues [auto-chain after build]
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
Audit project dependencies for known vulnerabilities (CVEs), outdated versions, unused packages, and license compliance issues. Runs native audit tools when available (npm audit, pip-audit, go list). Categorizes findings by severity and produces an actionable dependency audit report.

Auto-chain: runs automatically after build phase.
Condition: always.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/audit-deps.md
</execution_context>
