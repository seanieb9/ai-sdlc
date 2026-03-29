---
name: sdlc:squad
description: Team dashboard — shows all active SDLC workflows across branches in the project.
argument-hint: ""
allowed-tools:
  - Read
  - Bash
  - Glob
---

<objective>
Display a team-level dashboard showing all active SDLC workflows across branches. Reads all state.json files under .claude/ai-sdlc/workflows/, extracts key fields, and presents a consolidated view highlighting stale, blocked, and review-ready branches.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/squad.md
</execution_context>
