---
name: sdlc:resume
description: Resume work after /clear or a new session. Reads the checkpoint field in state.json to re-orient Claude instantly. Delivers a structured brief showing phase progress, last completed work, exact next action, and any critical verbal context from the previous session.
argument-hint: ""
allowed-tools:
  - Read
  - Glob
  - Grep
---

<objective>
Re-orient Claude completely after /clear or context loss. Work should resume in under a minute.

Process:
  1. Read state.json (checkpoint field) + spot-read in-progress artifact files named in the checkpoint
  2. Do not re-read all docs in full — the checkpoint exists precisely to avoid that
  3. Deliver a structured resume brief: phase progress, last completed, exact next action, open decisions, do-not-lose items
  4. Wait for user confirmation before executing

If no checkpoint exists in state.json: fall back to reading state.json phases and routing like /sdlc:00-start.

Do NOT re-read all docs in full. The checkpoint exists precisely to avoid that.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/resume.md
</execution_context>
