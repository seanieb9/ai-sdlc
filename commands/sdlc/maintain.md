---
name: sdlc:maintain
description: Maintenance planning — tech debt registry, scheduled operations, upgrade roadmap
argument-hint: "[area] [--debt-only] [--schedule-only]"
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
Phase 15 maintenance planning. Consolidates all technical debt incurred during the project, identifies scheduled operational tasks, and produces a forward-looking upgrade roadmap.

Tech debt is gathered from three sources: the technicalDebts array in state.json, WARN/INFO findings in the verification report, and TODO/FIXME/HACK comments in source code. Each debt item is assigned a TD-ID and prioritized.

Reads:
  - `$STATE` (state.json) — technicalDebts array
  - `$ARTIFACTS/verify/verification-report.md` — WARN and INFO findings (if exists)
  - `$ARTIFACTS/design/tech-architecture.md` — scheduled operations implied by architecture (if exists)
  - Source code — scanned for TODO/FIXME/HACK comments

Outputs:
  - `$ARTIFACTS/maintain/maintenance-plan.md` — tech debt register, scheduled operations table, dependency health, upgrade roadmap
</objective>

<context>
Area to focus on: $ARGUMENTS

Flags:
  --debt-only       Output tech debt register only (skip scheduled ops and upgrade roadmap)
  --schedule-only   Output scheduled operations table only (skip debt and roadmap)
</context>

<execution_context>
@~/.claude/sdlc/workflows/maintain.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the maintain verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
