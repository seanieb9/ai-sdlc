---
name: sdlc:00-start
description: SDLC Orchestrator — reads intent, assesses current project state, enforces phase gates, and routes to the correct lifecycle phase. Always run this first.
argument-hint: "<idea or command> [--status] [--force <phase>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
The SDLC Orchestrator. Entry point for all lifecycle work — new projects, new features, bug fixes, improvements.

Reads state, classifies intent, checks phase gates, and drives the correct next action. No phase is skipped without explicit override.

SDLC phases in order:
  1. RESEARCH → 2. SYNTHESIZE → 3. PRODUCT-SPEC → 4. CUSTOMER-JOURNEY
  5. DATA-MODEL (critical gate — everything downstream depends on this)
  6. TECH-ARCH → 7. PLAN → 8. CODE → 9. TEST-CASES → 10. TEST-AUTO
  11. OBSERVABILITY → 12. SRE → 13. REVIEW

Key rules enforced:
  - No CODE without a PLAN
  - No PLAN without DATA-MODEL approved
  - No DATA-MODEL changes without review
  - Docs are updated, never re-created
  - TODO.md is always maintained
</objective>

<context>
Input: $ARGUMENTS

Flags:
  --status        Show SDLC dashboard and current state, then exit
  --force <phase> Override gate check for named phase (document reason in STATE.md)
  --new           Force new project initialization even if state exists
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/orchestrate.md
@/Users/seanlew/.claude/sdlc/references/process.md
@/Users/seanlew/.claude/sdlc/references/doc-management.md
@/Users/seanlew/.claude/sdlc/templates/state.md
</execution_context>

