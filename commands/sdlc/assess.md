---
name: sdlc:assess
description: Brownfield codebase readiness assessment — scores architecture quality, test coverage, observability baseline, and migration risk.
argument-hint: "[focus area]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Agent
---

<objective>
Score the codebase across 5 quality dimensions (architecture, tests, observability, security, documentation), provide evidence-backed findings, and output an overall readiness rating of READY / NEEDS-WORK / SIGNIFICANT-GAPS with prioritized improvement recommendations.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/assess.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
