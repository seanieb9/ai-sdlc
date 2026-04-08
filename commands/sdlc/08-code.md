---
name: sdlc:08-code
description: Implement features following clean architecture, clean code, and established design patterns. Requires a plan. Uses /simplify. Never vibes.
argument-hint: "<task-id or feature> [--task <id>] [--layer <domain|app|infra|api>] [--dry-run]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

<objective>
Implement planned tasks following clean architecture and clean code principles. A plan MUST exist before any implementation.

Gate check: `$ARTIFACTS/plan/implementation-plan.md` must exist and `phases.plan.status` in state.json must be `completed`. If not, run /sdlc:07-plan first.

Implementation order (always follow this sequence):
  1. Domain entities and value objects (pure, no dependencies)
  2. Domain services and business rules
  3. Application use cases / command handlers (orchestrate domain)
  4. Port interfaces (define contracts)
  5. Repository implementations (infrastructure adapters)
  6. External service adapters
  7. API layer (controllers, serializers)
  8. Dependency injection wiring

Code standards enforced:
  - Clean Architecture: no domain/application code imports infrastructure
  - Single Responsibility: one reason to change per class/module
  - Dependency Inversion: depend on abstractions, not concretions
  - Don't Repeat Yourself: extract after second occurrence, not before
  - No magic numbers or strings — use constants/enums
  - Error handling: explicit, typed, never swallow exceptions
  - Logging at entry/exit of use cases and service boundaries (structured, with trace IDs)

After implementation:
  - Run /simplify on all changed code
  - Mark tasks complete in implementation-plan.md
  - Update state.json task statuses
</objective>

<context>
Task or feature: $ARGUMENTS

Flags:
  --task <id>              Work on specific TODO task ID
  --layer <layer>          Focus on a specific clean architecture layer
  --dry-run                Show what would be implemented without writing files
</context>

<execution_context>
@~/.claude/sdlc/workflows/code.md
@~/.claude/sdlc/references/clean-architecture.md
@~/.claude/sdlc/references/observability-standards.md
@~/.claude/sdlc/references/microservices.md
@~/.claude/sdlc/references/resilience-patterns.md
@~/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 8 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

