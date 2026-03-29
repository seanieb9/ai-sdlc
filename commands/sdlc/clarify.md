---
name: sdlc:clarify
description: Guided requirements elicitation — structured questions to produce FR-IDs and NFR-IDs before writing the product spec.
argument-hint: "<feature or problem statement>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

<objective>
Structured requirements elicitation session. Asks targeted questions across functional, edge-case, NFR, and scope dimensions. Assigns REQ-NNN and NFR-NNN IDs with numeric thresholds. Produces a clarify-brief.md artifact ready to feed into /sdlc:idea.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/clarify.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
