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

Gate check: .sdlc/PLAN.md and .sdlc/TODO.md must exist. If not, run /sdlc:plan first.

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
  - Mark TODO items as done
  - Update STATE.md
</objective>

<context>
Task or feature: $ARGUMENTS

Flags:
  --task <id>              Work on specific TODO task ID
  --layer <layer>          Focus on a specific clean architecture layer
  --dry-run                Show what would be implemented without writing files
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/code.md
@/Users/seanlew/.claude/sdlc/references/clean-architecture.md
@/Users/seanlew/.claude/sdlc/references/observability-standards.md
@/Users/seanlew/.claude/sdlc/references/microservices.md
@/Users/seanlew/.claude/sdlc/references/resilience-patterns.md
</execution_context>

