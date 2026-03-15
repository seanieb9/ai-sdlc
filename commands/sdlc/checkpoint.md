---
name: sdlc:checkpoint
description: Save a precise session snapshot to .sdlc/NEXT_ACTION.md. Captures current phase/step, exact next action, open decisions, and any verbal context from this session. Run proactively before context fills or at natural stopping points.
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

<objective>
Save a complete session snapshot so work can resume instantly after /clear or in a new session.

Captures:
  - Current phase and exact step within it
  - What was just completed this session
  - The single exact next command to run
  - Open decisions that haven't been resolved
  - Any files that are mid-edit or incomplete
  - Verbal instructions, constraints, or preferences from this session that aren't written in any document

Output: .sdlc/NEXT_ACTION.md (always overwritten with current state — not a log)

After saving, confirm with: phase/step, next action, count of open decisions and do-not-lose items.

Recommend: /loop 15m /sdlc:checkpoint to auto-save on a timer while working.
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/checkpoint.md
</execution_context>
