---
name: sdlc:plan
description: Create a precise, dependency-ordered execution plan before any code is written. Breaks work into atomic tasks stored in state.json. No code without a plan.
argument-hint: "[scope/milestone] [--update] [--reset]"
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
Create a precise, dependency-ordered execution plan before any code is written. No vibe coding. No improvised implementation. Always plan first.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/tech-architecture.md (must exist)
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-model.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/test-cases/test-cases.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/plan/implementation-plan.md (update, never recreate)

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/plan/implementation-plan.md
  - tasks array in .claude/ai-sdlc/workflows/<branch>/state.json

Plan structure:
  - Milestones with acceptance criteria
  - Atomic tasks with TASK-IDs, dependencies, layer (domain/application/infrastructure/delivery)
  - Frontend tasks tagged [fe], backend [be], infra [infra], test [test]
  - Estimated complexity (S/M/L)
  - Critical path identified
  - Tasks stored as JSON in state.json tasks array with status: "pending"/"in_progress"/"done"/"blocked"
</objective>

<context>
Scope/milestone: $ARGUMENTS

Flags:
  --update   Update existing plan (add tasks, reprioritize, mark complete)
  --reset    Rebuild plan from scratch (requires confirmation)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/plan.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 7 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
