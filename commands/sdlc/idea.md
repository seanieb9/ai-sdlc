---
name: sdlc:idea
description: Product specification — REQ-IDs, BR-IDs, NFR-IDs, BDD scenarios, acceptance criteria. The authoritative source of truth for what the system must do.
argument-hint: "<feature or system name> [--update] [--section <name>]"
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
Create or update the product specification — the authoritative source of truth for what the system must do.

Output (always update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md

Spec structure:
  1. Overview — purpose, scope, success metrics
  2. Personas and roles
  3. Business rules (BR-IDs — permanent, immutable IDs)
  4. Functional requirements (REQ-IDs, MoSCoW prioritized)
  5. Non-functional requirements (NFR-IDs with numeric thresholds)
  6. Exception handling (EH-IDs — every error case)
  7. BDD scenarios (Given/When/Then per use case)
  8. API intent (high level, pre-architecture)
  9. Acceptance criteria
  10. Open questions

ID rules — PERMANENT once assigned:
  - REQ-NNN: functional requirement
  - BR-NNN: business rule (invariant)
  - NFR-NNN: non-functional requirement (must have numeric threshold)
  - EH-NNN: exception/error case
  - IDs are NEVER reused or renumbered — only DEPRECATED with reason and date
</objective>

<context>
Feature/System: $ARGUMENTS

Flags:
  --update           Update existing spec (identifies sections to change vs add)
  --section <name>   Update a specific section only
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/product-spec.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 3 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

