---
name: sdlc:synthesize
description: Synthesize research findings with codebase analysis to produce a unified readiness picture. Bridges research phase to product spec.
argument-hint: "[topic] [--research-only] [--codebase-only]"
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
Synthesize research findings with deep codebase analysis to produce a unified readiness picture before specs are written.

Inputs consumed:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/research.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/gap-analysis.md
  - .claude/ai-sdlc/codebase/architecture.md (if exists — brownfield index)

Output:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/synthesis.md

Key deliverables:
  - Reuse matrix: what already exists vs what needs building
  - Risk assessment: what existing code will be touched
  - Recommended approach: extend vs build vs replace
  - Readiness assessment: data model impact, breaking changes risk
</objective>

<context>
Topic/focus: $ARGUMENTS

Flags:
  --research-only   Skip codebase analysis (greenfield or no codebase yet)
  --codebase-only   Only analyze codebase, skip research synthesis
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/synthesize.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 2 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

