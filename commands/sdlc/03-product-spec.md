---
name: sdlc:03-product-spec
description: Create or update the product specification — full requirements, business rules, exception handling, Given/When/Then BDD scenarios, and API contracts. Single source of truth.
argument-hint: "<feature/area> [--new-section <name>] [--update <section>] [--full-rewrite]"
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
  - WebFetch
---

<objective>
Create or update docs/product/PRODUCT_SPEC.md — the single source of truth for what the system must do.

Document structure (always maintained):
  1. Overview — purpose, scope, non-goals
  2. User personas and roles
  3. Business rules — numbered, unambiguous
  4. Functional requirements — MoSCoW prioritized
  5. Non-functional requirements — performance, security, availability, scalability
  6. Exception handling — every error state documented
  7. BDD scenarios — Given/When/Then for every significant flow
  8. API contracts — endpoint, request/response shapes, error codes
  9. Screen/interaction flows — step-by-step user journeys
  10. Acceptance criteria — testable, linked to requirements

Rules:
  - Update existing sections, never overwrite without reading first
  - Requirements are numbered and never renumbered (only appended or deprecated)
  - Shard to PRODUCT_SPEC_[DOMAIN].md only when a domain section exceeds 400 lines
  - Every requirement must be traceable to a business rule
</objective>

<context>
Feature/area to specify: $ARGUMENTS

Flags:
  --new-section <name>  Add a new named section to the spec
  --update <section>    Update a specific section only
  --full-rewrite        Re-derive full spec from research/synthesis (destructive — asks confirmation)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/product-spec.md
@/Users/seanlew/.claude/sdlc/references/product-standards.md
@/Users/seanlew/.claude/sdlc/references/testing-standards.md
@/Users/seanlew/.claude/sdlc/templates/product-spec.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>

