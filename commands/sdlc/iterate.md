---
name: sdlc:iterate
description: Scoped mini-lifecycle for adding or evolving features — runs only the phases the change actually touches.
argument-hint: "<feature description> [--type new|enhancement|nfr|data|ux] [--voc] [--auto]"
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
Scoped mini-lifecycle for a feature iteration. Classifies the change type, determines which SDLC phases are in scope, generates an ITER-NNN tracking file, runs only the relevant phases, and marks the iteration complete.

Flags:
- `--type new|enhancement|nfr|data|ux` — explicit iteration type (inferred if omitted)
- `--voc` — start with voice-of-customer phase before the standard flow
- `--auto` — skip confirmation pauses between phases
</objective>

<execution_context>
@~/.claude/sdlc/workflows/iterate.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
