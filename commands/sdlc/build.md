---
name: sdlc:build
description: Implement tasks following clean architecture — domain→application→infrastructure→delivery. Requires a plan. Uses /simplify. Never vibes.
argument-hint: "[task-id or scope] [--task <id>] [--all-pending]"
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
Implement planned tasks following clean architecture, clean code, and established patterns. A plan MUST exist. No improvised coding.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/plan/implementation-plan.md (must exist)
  - tasks array in state.json with at least one "pending" task

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/tech-architecture.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/api-spec.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-model.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md
  - .claude/ai-sdlc/codebase/architecture.md

Implementation rules:
  - Layer order: domain → application → infrastructure → delivery
  - Clean architecture: no leaking dependencies across layer boundaries
  - One concern per class/function
  - No magic numbers — named constants only
  - Error handling at every boundary
  - Run /simplify after implementing each task
  - Mark task status "in_progress" before starting, "done" when complete
  - Update checkpoint in state.json after each task
</objective>

<context>
Task ID or scope: $ARGUMENTS

Flags:
  --task <id>      Implement a specific TASK-ID
  --all-pending    Implement all pending tasks in dependency order
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/code.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 8 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
