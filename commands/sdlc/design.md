---
name: sdlc:design
description: Technical architecture — C4 diagrams, LLD, API spec, ADRs, resilience design. Clean architecture. Established patterns only. Requires data model to exist first.
argument-hint: "[focus area] [--update] [--adr <title>]"
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
Design the technical architecture from the canonical data model and product spec outward. Clean architecture. Established patterns only. No exotic choices.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-model.md (must exist)
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/synthesis.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/journey/customer-journey.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/tech-architecture.md (update, never replace)
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/api-spec.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/tech-architecture.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/api-spec.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/solution-design.md

Deliverables:
  - C4 model (Context → Container → Component, Mermaid)
  - Low-level design per component
  - API spec (OpenAPI-style: endpoints, request/response schemas, auth, error codes)
  - Architecture Decision Records (ADRs) for every non-obvious choice
  - Resilience design (retries, circuit breakers, timeouts, graceful degradation)
  - NFR mapping (every NFR-ID mapped to an architectural mechanism)
</objective>

<context>
Focus area: $ARGUMENTS

Flags:
  --update         Update existing architecture (extend, not replace)
  --adr <title>    Record a specific architecture decision
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/tech-arch.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 6 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
