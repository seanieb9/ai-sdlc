---
name: sdlc:01-research
description: Market and competitive research, customer voice analysis, and gap identification. Outputs to docs/research/RESEARCH.md and docs/research/GAP_ANALYSIS.md (update, never recreate).
argument-hint: "<topic or feature> [--deep] [--competitive-only] [--customer-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Conduct thorough market, competitive, and customer research for a feature or project.

Outputs (always update existing, never recreate):
  - docs/research/RESEARCH.md — market landscape, trends, competitors
  - docs/research/GAP_ANALYSIS.md — customer pain points, unmet needs, opportunities

Research pillars:
  1. Market landscape — size, trends, direction
  2. Competitive analysis — top 3-5 competitors, feature matrix, positioning
  3. Customer voice — forums, reviews, support tickets patterns, feature requests
  4. Gap analysis — where competitors fall short, what customers are asking for
  5. Codebase context — what already exists in this project that's relevant
</objective>

<context>
Topic/Feature: $ARGUMENTS

Flags:
  --deep             Expand search breadth, more sources
  --competitive-only Skip customer voice research
  --customer-only    Skip competitor deep-dive
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/research.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 1 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

