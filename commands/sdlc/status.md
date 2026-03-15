---
name: sdlc:status
description: Show the current SDLC state — phases completed, active work, todos, doc health, and recommended next action.
argument-hint: "[--verbose] [--docs] [--todos]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

<objective>
Display a clear SDLC dashboard for the current project.

Dashboard sections:
  1. Project summary (name, type, last updated)
  2. Phase progress (✅ complete | 🔄 in progress | ⛔ blocked | ⬜ not started)
  3. Active todos (from .sdlc/TODO.md)
  4. Document health (exists, missing, stale)
  5. Recommended next action

Read from:
  - .sdlc/STATE.md
  - .sdlc/TODO.md
  - .sdlc/PLAN.md
  - docs/ (check what exists)

Show clearly what the recommended next step is based on current state.
</objective>

<context>
Flags: $ARGUMENTS
  --verbose  Show full details per phase
  --docs     Focus on document health
  --todos    Show full todo list with statuses
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/status.md
</execution_context>

