---
name: sdlc:retro
description: Project retrospective — timeline, contributing factors, action items with owners
argument-hint: "[focus area] [--incident]"
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
Phase 16 project retrospective. Reads the full state history and all artifacts to construct a blameless retrospective covering what went well, what was difficult, what surprised the team, and what action items follow.

The retro is derived from real data: phase completion timestamps, gate overrides, autoChainLog failures, technical debts incurred, and decisions recorded. Nothing is invented — everything is sourced from state.json and the artifact record.

Reads:
  - `$STATE` (state.json) — full history: phases, decisions, gateOverrides, autoChainLog, technicalDebts
  - All artifacts that exist in `$ARTIFACTS/` — read in parallel

Outputs:
  - `$ARTIFACTS/retro/retro.md` — project summary, timeline, what went well, what was difficult, key decisions, action items
</objective>

<context>
Focus area (optional): $ARGUMENTS

Flags:
  --incident    Frame the retro as an incident post-mortem (adds contributing factors and timeline sections)
</context>

<execution_context>
@~/.claude/sdlc/workflows/retro.md
</execution_context>
