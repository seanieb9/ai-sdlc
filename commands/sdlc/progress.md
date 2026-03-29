---
name: sdlc:progress
description: Show implementation task progress — reads progress.json and displays checklist with completion stats.
argument-hint: "[--update <task-id> done|skip] [--next]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Task
  - TaskCreate
  - TaskUpdate
  - TaskList
---

<objective>
Display implementation task progress from progress.json. Supports updating task status and hydrating the native Claude task panel. Shows overall completion stats, breakdown by phase, in-progress and blocked tasks, and the single next recommended task.

Flags:
- `--update <TASK-ID> done|skip` — mark a task as done or skipped
- `--next` — show only the single next task with full context
</objective>

<execution_context>
@~/.claude/sdlc/workflows/progress.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
