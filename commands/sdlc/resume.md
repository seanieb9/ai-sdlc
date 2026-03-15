---
name: sdlc:resume
description: Resume work after /clear or a new session. Reads .sdlc/NEXT_ACTION.md and all state files to re-orient Claude instantly. Delivers a structured brief showing phase progress, last completed work, exact next action, and any critical verbal context from the previous session.
argument-hint: ""
allowed-tools:
  - Read
  - Glob
  - Grep
---

<objective>
Re-orient Claude completely after /clear or context loss. Work should resume in under a minute.

Process:
  1. Read .sdlc/NEXT_ACTION.md (last checkpoint) + STATE.md + TODO.md + PLAN.md in parallel
  2. Spot-read only the in-progress files named in the checkpoint — not all docs
  3. Deliver a structured resume brief: phase progress, last completed, exact next action, open decisions, do-not-lose items
  4. Wait for user confirmation before executing

If no NEXT_ACTION.md exists: fall back to reading STATE.md and routing like /sdlc:00-start.

Do NOT re-read all docs in full. The checkpoint exists precisely to avoid that.
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/resume.md
</execution_context>
