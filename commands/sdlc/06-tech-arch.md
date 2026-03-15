---
name: sdlc:06-tech-arch
description: Design and document technical architecture — clean architecture, C4 model, solution design, API specs, design patterns. Requires data model to exist first.
argument-hint: "<feature/system> [--c4] [--api-spec] [--solution-design] [--patterns]"
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
Design the technical architecture starting from the canonical data model and product spec.

Manages:
  - docs/architecture/TECH_ARCHITECTURE.md — system design, C4 diagrams, component decisions
  - docs/architecture/API_SPEC.md — full OpenAPI/REST/GraphQL specifications
  - docs/architecture/SOLUTION_DESIGN.md — detailed design decisions, ADRs, patterns chosen

Architecture principles (non-negotiable):
  - Clean Architecture: domain → application → infrastructure (dependency rule inward)
  - Ports and adapters (hexagonal) for all external integrations
  - Domain layer has zero infrastructure dependencies
  - CQRS where read/write patterns diverge significantly
  - Repository pattern for all data access
  - Dependency injection throughout

Design process:
  1. Read DATA_MODEL.md and PRODUCT_SPEC.md (REQUIRED before designing)
  2. Define bounded contexts and service boundaries
  3. Document using C4 model: Context → Containers → Components
  4. Design API contracts from data model (not from convenience)
  5. Select design patterns with justification (no pattern without reason)
  6. Document all architecture decisions as ADRs in SOLUTION_DESIGN.md
  7. Run /simplify check on all designs — favor simplicity

Rules:
  - No exotic patterns — use established, well-understood designs
  - Every pattern choice must be justified
  - API spec must be machine-readable (OpenAPI 3.x)
  - Breaking API changes require versioning strategy
</objective>

<context>
System/feature: $ARGUMENTS

Flags:
  --c4            Focus on C4 context/container/component diagrams
  --api-spec      Focus on API specification only
  --solution-design  Focus on ADRs and design decisions
  --patterns      Analyze and recommend patterns for current codebase
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/tech-arch.md
@/Users/seanlew/.claude/sdlc/references/clean-architecture.md
@/Users/seanlew/.claude/sdlc/references/microservices.md
@/Users/seanlew/.claude/sdlc/templates/api-spec.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>

