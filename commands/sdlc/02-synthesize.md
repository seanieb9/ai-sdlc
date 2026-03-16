---
name: sdlc:02-synthesize
description: Synthesizes research findings with existing codebase analysis to produce unified insights and readiness assessment before specs are written.
argument-hint: "[feature/area] [--codebase-only] [--research-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - Agent
  - WebSearch
  - WebFetch
---

<objective>
Synthesize research outputs with deep codebase analysis to produce a unified picture before specs are written.

Reads:
  - docs/research/RESEARCH.md
  - docs/research/GAP_ANALYSIS.md
  - Existing codebase (architecture, patterns, conventions, data models)
  - Existing docs (product spec, data model, tech arch)

Outputs (update existing):
  - docs/research/SYNTHESIS.md — unified findings, readiness assessment, reuse opportunities, risk flags

Synthesis covers:
  1. What research says we need
  2. What the codebase already provides
  3. Gaps between current state and target state
  4. Reuse opportunities (don't reinvent)
  5. Risk areas (data model impacts, breaking changes, integration complexity)
  6. Recommended approach summary
</objective>

<context>
Focus area: $ARGUMENTS (optional — synthesizes everything if omitted)

Flags:
  --codebase-only  Skip research files, analyze codebase only
  --research-only  Skip codebase analysis
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/synthesize.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 2 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

