---
name: sdlc:eod
description: End of day wrap-up. Reaches a clean stopping point, commits work in progress, saves a checkpoint, and produces a summary with tomorrow's first action.
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

<objective>
Wrap up the session cleanly so tomorrow starts in seconds.

Process:
  1. Check for broken mid-state — fix or stub out any half-implemented code
  2. Identify a clean stopping point (finish the task if close, stop before starting a new one if not)
  3. Commit completed work with a clear message
  4. Save checkpoint to .sdlc/NEXT_ACTION.md with EOD framing (daily summary + tomorrow's first action)
  5. Print EOD summary: today's progress, what was committed, first action tomorrow, blockers, open decisions

The goal: leave the project in a known, committed, resumable state.
Run /sdlc:sod tomorrow to start the next session.
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/eod.md
@/Users/seanlew/.claude/sdlc/workflows/checkpoint.md
</execution_context>
