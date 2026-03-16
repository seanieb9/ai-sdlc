---
name: sdlc:05-data-model
description: Canonical data model — the foundation everything is built on. Create, evolve, or review the data model. ALL changes require review. Uses DDD, industry standards, Mermaid ERDs.
argument-hint: "<domain or entity> [--review] [--impact-analysis] [--new-domain <name>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - Task
  - AskUserQuestion
  - Agent
  - WebFetch
---

<objective>
The canonical data model is the FOUNDATION. Everything — tech architecture, APIs, code, tests — derives from it.

Manages:
  - docs/data/DATA_MODEL.md — entities, relationships, aggregates, invariants, ERDs (Mermaid)
  - docs/data/DATA_DICTIONARY.md — every field: name, type, constraints, business meaning, source

Process:
  1. Read all existing data model docs first
  2. Analyze requirements from PRODUCT_SPEC.md
  3. Apply Domain-Driven Design: identify bounded contexts, aggregates, entities, value objects
  4. Check industry standards for the domain (e.g., ISO 20022 for payments, FHIR for health, OpenID for identity)
  5. Define relationships, cardinality, invariants, lifecycle states
  6. Build Mermaid ERD diagrams
  7. Document in DATA_DICTIONARY.md (field level)
  8. Perform impact analysis on any change to existing entities
  9. Flag breaking changes explicitly — require confirmation before finalizing
  10. Update DATA_MODEL.md — evolve, never replace history

Critical rules:
  - NEVER delete entities or fields — deprecate with reason and date
  - ANY change to existing entities triggers --review automatically
  - Data model drives API shapes, not the other way around
  - External standards take precedence over convenience
</objective>

<context>
Domain/entity focus: $ARGUMENTS

Flags:
  --review           Run impact analysis on proposed changes before writing
  --impact-analysis  Show what downstream artifacts are affected by a change
  --new-domain <n>   Initialize a new bounded context/domain section
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/data-model.md
@/Users/seanlew/.claude/sdlc/references/data-standards.md
@/Users/seanlew/.claude/sdlc/templates/data-model.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 5 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

