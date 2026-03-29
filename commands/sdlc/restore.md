---
name: sdlc:restore
description: Restore session from checkpoint — reads state.json and delivers brief. Run as the first command after /clear or in a new session.
argument-hint: "[--verbose]"
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
Re-orient Claude completely after /clear, a new session, or context loss. Reads all persistent state and delivers a crisp brief so work continues in under a minute.

Run as the very first command in a new context window.

Reads:
  - .claude/ai-sdlc/workflows/<branch>/state.json — checkpoint, tasks, decisions, context log
  - .claude/ai-sdlc/workflows/<branch>/artifacts/ — scans for existing phase artifacts
  - .claude/ai-sdlc/codebase/architecture.md — if exists

Output:
  - No files written. Delivers a structured brief only.

Brief structure:
  1. Branch and workspace path
  2. Phase progress (which phases have artifacts, which are pending)
  3. Last checkpoint (what was being done, exact next action)
  4. Pending tasks (from state.json tasks array — status: pending/in_progress/blocked)
  5. Open decisions (from state.json)
  6. Recommended first action
</objective>

<context>
Options: $ARGUMENTS

Flags:
  --verbose   Include full task list and all context log entries (not just recent)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/resume.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>
