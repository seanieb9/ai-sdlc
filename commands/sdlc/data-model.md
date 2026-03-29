---
name: sdlc:data-model
description: Canonical data model — the foundation everything is built on. Domain-driven design, Mermaid ERDs, data dictionary, normalization rules, and migration strategy.
argument-hint: "[domain/entity] [--update] [--review]"
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
Build the canonical data model that everything downstream derives from — architecture, APIs, code, and tests. Treat this as the most critical artifact in the system.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/business-process/business-process.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/synthesis.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-model.md (update, never recreate)
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-dictionary.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-model.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-dictionary.md

Deliverables:
  - Domain model (DDD — aggregates, entities, value objects, bounded contexts)
  - Mermaid ERD (logical and physical)
  - Data dictionary (field-level: type, constraints, nullability, business meaning)
  - Normalization decisions with rationale
  - Index strategy
  - Migration notes (brownfield: impact on existing tables)
</objective>

<context>
Domain/entity focus: $ARGUMENTS

Flags:
  --update   Update existing data model (add entities, evolve schema — ALL changes require review)
  --review   Review existing model for integrity, normalization, and consistency issues
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/data-model.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 5 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
