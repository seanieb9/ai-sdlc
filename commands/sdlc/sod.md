---
name: sdlc:sod
description: Start of day orientation. Reads yesterday's checkpoint, reviews the task list, plans today's session, and delivers a brief with the first action — before executing anything.
argument-hint: ""
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

<objective>
Orient Claude and plan the session in under two minutes.

Process:
  1. Read state.json (checkpoint field + phases) + relevant artifacts (implementation-plan.md if exists) + git log in parallel
  2. Check for stale decisions, unverified phases, or blockers from yesterday
  3. Plan today's session: realistic goal + first action + known decision points ahead
  4. Deliver SOD brief: where we left off, first action, today's goal, watch-outs, attention items
  5. Wait for "go" before executing anything

Reminder (once only): suggest /loop 15m /sdlc:checkpoint after the user starts work.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/sod.md
@~/.claude/sdlc/workflows/resume.md
</execution_context>
