---
name: sdlc:compare
description: Generate 2-3 design alternatives with trade-off analysis — output as Architecture Decision Record.
argument-hint: "<design decision to compare>"
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
  - WebSearch
---

<objective>
Generate 2–3 concrete alternatives for a design decision, analyze each against the project's existing architecture and NFR constraints, build a trade-off matrix, make a recommendation, and produce a formal Architecture Decision Record (ADR).

Output: `$ARTIFACTS/design/adr-<slug>.md` and a new DEC-NNN entry in state.json.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/compare.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
