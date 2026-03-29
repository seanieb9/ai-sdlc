---
name: sdlc:journey
description: Map customer journeys — who uses the system, why, and how. Happy paths, failure paths, business process integration, and screen flows.
argument-hint: "[feature/persona] [--persona <name>] [--update]"
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
Map who uses the system, why they use it, and exactly how. These journeys are the basis for E2E test design and business process documentation.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/personas/personas.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/gap-analysis.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/journey/customer-journey.md

Journey structure:
  - Personas (from PERSONAS.md or inline if skipped)
  - Journey maps: trigger → steps table (user action, system response, emotional state) → outcome
  - Required per journey: happy path + primary failure path + edge case
  - Business process integration
  - Screen/interaction flows
  - Journey coverage matrix (persona × journey × test coverage)
</objective>

<context>
Feature/persona focus: $ARGUMENTS

Flags:
  --persona <name>   Focus on a specific persona's journeys
  --update           Update existing journeys (add new flows, update steps)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/customer-journey.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 4 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

