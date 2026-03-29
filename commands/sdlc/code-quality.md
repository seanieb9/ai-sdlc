---
name: sdlc:code-quality
description: Run static analysis, security scan, dependency audit, and complexity checks. Auto-chains after every build. Can also be run manually at any time.
argument-hint: "[--fix] [--strict]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

<objective>
Run code quality checks: linting, type safety, security scanning, dependency audit, dead code detection. Produces a quality report and routes findings to the technical debt register.

Flags:
  --fix      Attempt to auto-fix lint/format issues where safe (runs eslint --fix, ruff --fix, prettier --write, etc.)
  --strict   Treat warnings as errors for reporting purposes — useful for pre-release hardening

Runs automatically after every build phase (auto-chain). Can also be invoked manually at any time with `/sdlc:code-quality`.
</objective>

<context>
Input: $ARGUMENTS — optional flags `--fix` and/or `--strict`

When auto-chained after build: run silently (no interactive prompts), return compact summary line.
When invoked manually: show full report inline and wait for acknowledgement.
</context>

<execution_context>
@~/.claude/sdlc/workflows/code-quality.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
