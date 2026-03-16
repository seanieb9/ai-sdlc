# Plan Workflow

Create a precise, dependency-ordered execution plan before any code is written. No vibe. No improvised coding. Always plan first.

## Step 1: Pre-Flight

Read in parallel:
- `docs/data/DATA_MODEL.md` — understand entities to implement
- `docs/architecture/TECH_ARCHITECTURE.md` — understand components to build
- `docs/product/PRODUCT_SPEC.md` — understand requirements to fulfill
- `docs/architecture/API_SPEC.md` — understand contracts to implement
- `docs/frontend/SCREEN_SPEC.md` — if exists: screens to build as [fe] tasks
- `docs/frontend/DESIGN_TOKENS.md` — if exists: confirms FE setup complete
- `.sdlc/PLAN.md` — existing plan (if any — update, don't replace)
- `.sdlc/TODO.md` — existing todos (if any)
- `.sdlc/STATE.md` — project context

If DATA_MODEL.md missing: STOP. Cannot plan without data model.
If TECH_ARCHITECTURE.md missing: WARN. Recommend running /sdlc:06-tech-arch first, but allow continuation.
If TECH_ARCHITECTURE.md has a ## Frontend Architecture section but SCREEN_SPEC.md missing: WARN. Recommend running /sdlc:fe-setup first — FE tasks cannot be generated without SCREEN_SPEC.md.

If existing PLAN.md: read fully. Add new phases/tasks rather than replacing.

## Step 2: Work Breakdown Structure

Decompose the work following clean architecture layers:

**Backend layer ordering (strict — never deviate):**
1. Data layer (migrations, schema changes)
2. Domain layer (entities, value objects, domain services)
3. Application layer (use cases, command/query handlers, port interfaces)
4. Infrastructure layer (repository implementations, external adapters)
5. Delivery layer (API controllers, serializers, validators)
6. Cross-cutting (observability, config, error handling)
7. Tests (unit, integration, contract, E2E)

**Frontend layer ordering (when SCREEN_SPEC.md exists — tag all FE tasks with `[fe]`):**
1. Design tokens + Tamagui config (`tamagui.config.ts`, token setup)
2. Shared component primitives (`components/ui/` — from SCREEN_SPEC.md shared component registry)
3. TanStack Query hooks (`hooks/use-[resource].ts` — one per API resource)
4. Screen implementations (`app/(scope)/screen.tsx` — one task per screen)
5. Navigation wiring (Expo Router layout files, tab/stack configuration)
6. FE tests (RNTL component tests, Maestro E2E flows)

**For each task, define:**
- Task ID: TASK-[NNN] (sequential, never reuse)
- Title: "[verb] [what]" (e.g., "Implement OrderRepository", "Add CreateOrder use case")
- Layer: [data|domain|application|infrastructure|delivery|crosscutting|test]
- Phase: which delivery phase this belongs to
- Dependencies: [TASK-XXX, TASK-YYY] — what must be done first
- Done Criteria: specific, verifiable outcome ("All unit tests pass", "API returns 201 with order ID")
- Effort: S (< 1hr) | M (1-4hrs) | L (4-8hrs) | XL (> 1 day — should be split)
- Risk: LOW | MEDIUM | HIGH

**XL tasks must be split** — no task should span more than one session.

## Step 3: Dependency Graph

Build the dependency graph:

```
TASK-001: Create DB migration for orders table
    ↓
TASK-002: Implement Order entity (domain)
    ↓
TASK-003: Implement OrderRepository interface (port)
    ↓                                    ↓
TASK-004: PostgresOrderRepository     TASK-005: CreateOrder use case
    ↓                                    ↓ (depends on 003, 004)
TASK-006: POST /orders controller (depends on 005)
    ↓
TASK-007: Unit tests for Order entity
TASK-008: Integration tests for OrderRepository
TASK-009: E2E test for POST /orders
```

Identify parallelizable tasks (no dependencies between them — can be done in same session or by different people).

## Step 4: Phase Planning

Group tasks into delivery phases:

**Phase 1: Foundation** — data model, domain entities, port interfaces
**Phase 2: Application** — use cases, application services
**Phase 3: Infrastructure** — repository implementations, external adapters
**Phase 4: Delivery** — API controllers, middleware, validators
**Phase 5: Quality** — tests, observability, documentation

Each phase should be independently releasable to a dev environment.

## Step 5: Risk Identification

For each risk area:
```
RISK                          | LIKELIHOOD | IMPACT | MITIGATION
[Risk description]            | H/M/L      | H/M/L  | [How to address]
```

Common risks:
- Data migration risks (existing data transformation)
- External service integration (API changes, availability)
- Performance (query plans on new tables)
- Security (auth changes, data exposure)
- Breaking changes to existing functionality

## Step 6: Write Output Files

**Write/update .sdlc/PLAN.md:**

```markdown
# Execution Plan: [Feature/Project Name]
*Created: [date] | Last Updated: [date]*

## Goal
[What this plan achieves — 2-3 sentences]

## Prerequisites
- [ ] DATA_MODEL.md approved
- [ ] TECH_ARCHITECTURE.md reviewed
- [ ] PRODUCT_SPEC.md complete

## Phases

### Phase 1: Foundation
[Task list with IDs, descriptions, effort]

### Phase 2: Application
[Task list]

### Phase 3: Infrastructure
[Task list]

### Phase 4: Delivery
[Task list]

### Phase 5: Quality
[Task list]

## Dependency Graph
[Mermaid flowchart]

## Risk Register
[Risk table]

## Definition of Done
[How we know the whole plan is complete]
```

**Write/update .sdlc/TODO.md:**

```markdown
# TODO
*Last Updated: [date]*

## Active (Current Phase)
- [ ] TASK-001: [description] | M | @eng1 | depends: none
- [ ] TASK-002: [description] | S | @eng2 | depends: TASK-001
- [~] TASK-003: [description] | L | @eng1 | IN PROGRESS — push [~] immediately on pickup

## Upcoming (Next Phase)
- [ ] TASK-004: [description] | M | @unassigned | depends: TASK-002

## Blocked
- [ ] TASK-005: [description] | @eng2 | waiting for: [external dependency]

## Done
- [x] TASK-000: [description] | @eng1 | completed: [date]
```

**Task tagging:**
- Backend tasks: no tag (default)
- Frontend tasks: add `[fe]` tag — this triggers the FE code workflow in Phase 8
- Example: `- [ ] TASK-021: Implement LoginScreen | M | @eng2 | [fe] | depends: TASK-001`

**Task assignment rules (microsquad with 2 engineers):**
- Assign every task to `@eng1`, `@eng2`, or `@unassigned` during planning
- Balance load: roughly equal total effort (S/M/L) per engineer across phases
- Assign lower-layer tasks (domain, application) first — they unblock upper layers
- Dependencies determine ordering — never assign a task before its dependencies are assigned to someone who will complete them first
- `@unassigned` tasks: first engineer to change `[ ]` → `[~]` and push owns it

**For solo developer:** omit the `@assignee` field entirely — not needed.

## Step 7: Update State

Mark Phase 7 (Plan) complete in STATE.md.

Output:
```
✅ Plan Complete

Phases: [N]
Tasks: [N total] ([N] this session, [N] upcoming)
Parallelizable: [N tasks]
Highest Risk: [top risk]

Files:
• .sdlc/PLAN.md
• .sdlc/TODO.md

⚠️  GATE UNLOCKED: /sdlc:08-code can now proceed.
Recommended Next: /sdlc:08-code --task TASK-001
```
