---
name: sdlc:gaps
description: Spawn 3 parallel gap analysis agents — tech debt, architecture drift, quality/coverage gaps. Run after /sdlc:map.
argument-hint: "[focus area]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Agent
---

<objective>
Spawn 3 read-only parallel agents to analyze the codebase for technical debt, architecture violations, and quality gaps. Aggregate findings into a unified gap-analysis.md with prioritized remediation plan and TD-NNN entries in state.json.

Prerequisites: /sdlc:map should be run first. Will warn if codebase map is missing.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/gaps.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
