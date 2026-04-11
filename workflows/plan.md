# Plan Workflow

Create a precise, dependency-ordered execution plan before any code is written. No vibe. No improvised coding. Always plan first.

## Step 0: Workspace Resolution
Run this bash to determine workspace paths:
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$WORKSPACE/artifacts"
```
Then use $WORKSPACE, $STATE, $ARTIFACTS throughout.

## Step 1: Pre-Flight

Read in parallel:
- `$ARTIFACTS/data-model/data-model.md` — understand entities to implement
- `$ARTIFACTS/design/tech-architecture.md` — understand components to build
- `$ARTIFACTS/idea/prd.md` — understand requirements to fulfill
- `$ARTIFACTS/design/api-spec.md` — understand contracts to implement
- `docs/frontend/SCREEN_SPEC.md` — if exists: screens to build as [fe] tasks
- `docs/frontend/DESIGN_TOKENS.md` — if exists: confirms FE setup complete
- `$ARTIFACTS/plan/implementation-plan.md` — existing plan (if any — update, don't replace)
- `$STATE` — project context (includes todos/tasks — read and parse JSON)

If data-model.md missing: STOP. Cannot plan without data model.
If tech-architecture.md missing: WARN. Recommend running the tech architecture phase (tell Claude to proceed) first, but allow continuation.
If tech-architecture.md has a ## Frontend Architecture section but SCREEN_SPEC.md missing: WARN. Recommend running the fe-setup workflow inline first — FE tasks cannot be generated without SCREEN_SPEC.md.

If existing implementation-plan.md: read fully. Add new phases/tasks rather than replacing.

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

### Required Engineering Tasks (auto-add to every plan)

These tasks must always be present in the plan, in addition to feature tasks. They are often forgotten but are non-negotiable:

**Security & Quality Setup (once per project, first sprint):**
- [ ] Configure linting and formatting tools (.eslintrc, .prettierrc, pyproject.toml, etc.)
- [ ] Configure pre-commit hooks (lint, format, secrets scan, commit message validation)
- [ ] Set up CODEOWNERS file
- [ ] Configure coverage thresholds in CI (fail build if coverage drops below [N]%)
- [ ] Set up dependency vulnerability scanning (npm audit / pip-audit / govulncheck in CI)
- [ ] Set up secrets scanning in CI (gitleaks or similar)

**Database (every feature that adds schema):**
- [ ] Write database migration file (forward migration)
- [ ] Write rollback migration file (reverse migration)
- [ ] Test migration in isolated environment before merging
- [ ] Add seed/fixture data for development environment

**Testing (every feature):**
- [ ] Unit tests for all domain entities and use cases
- [ ] Integration tests for all repository implementations
- [ ] Contract tests for all external API integrations (if any)
- [ ] E2E test for the primary happy path of the feature
- [ ] Performance test if the feature has a latency NFR

**Documentation (every feature):**
- [ ] Update API documentation (OpenAPI spec) for any new/changed endpoints
- [ ] Update README if setup steps changed
- [ ] Update runbooks if new failure modes introduced
- [ ] Create/update ADR for any significant technical decisions made during implementation

**Observability (every feature):**
- [ ] Add structured log entries for key business events
- [ ] Add metrics for key operations (created_total, duration_seconds)
- [ ] Update health check if new external dependency added

---

### Definition of Done

A task is only DONE when ALL of the following are true:

**Code quality:**
- [ ] Linting passes with 0 errors, 0 warnings
- [ ] Type checking passes with 0 errors (TypeScript / mypy / etc.)
- [ ] Code follows the project's style guide (format check passes)
- [ ] No commented-out code in the commit
- [ ] No debug logging left in
- [ ] No hardcoded secrets or environment-specific values

**Testing:**
- [ ] Unit tests written and passing for new business logic
- [ ] Test coverage for this task meets or exceeds the project threshold
- [ ] Integration tests written for new DB/service interactions
- [ ] All existing tests still pass (no regressions)
- [ ] New tests are not flaky (run them 3 times to confirm)

**Security:**
- [ ] No new security vulnerabilities introduced (dependency scan clean)
- [ ] Input validation added for all new user-facing inputs
- [ ] No sensitive data exposed in logs or error messages
- [ ] New endpoints have authentication and authorization

**Documentation:**
- [ ] Code is self-documenting (intent clear from names and structure)
- [ ] Complex logic has explanatory comments (the "why", not the "what")
- [ ] API spec updated for new endpoints

**Review:**
- [ ] Code reviewed by at least one other person (if team) or self-reviewed after 24 hours (if solo)
- [ ] All review comments addressed or explicitly deferred with reason
- [ ] PR description explains the "why" of the change

Only mark a task COMPLETE in the plan when every item above is checked.

---

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

## Release Branching Strategy

Choose ONE branching strategy and document it. Don't mix strategies — inconsistency causes merge conflicts and CI confusion.

**Option A: Trunk-Based Development (recommended for small teams and CI/CD)**
- All development happens on `main`
- Feature branches are short-lived (< 1 day ideally, max 3 days)
- Feature flags gate incomplete work in production
- Benefits: no long-lived branches, no painful merges, encourages small commits

**Option B: GitHub Flow (good for teams with less frequent releases)**
- Feature branches off `main`, merged via PR
- `main` is always deployable
- Releases tagged from `main`
- Benefits: simple, clear, good for cloud-native projects

**Option C: Git Flow (for teams with scheduled releases)**
- `main` = production
- `develop` = integration
- `feature/*` branches off `develop`
- `release/*` branches for release prep
- `hotfix/*` for production patches
- Benefits: clear separation, supports multiple versions
- Caution: complex, long-lived branches cause merge pain

Document the choice in `$ARTIFACTS/plan/implementation-plan.md`:
```
Branching Strategy: [trunk-based / github-flow / git-flow]
Reason: [why this fits the team and release cadence]
Branch naming: [e.g., feat/TICKET-123-description, fix/TICKET-456-description]
Commit standard: Conventional Commits (feat, fix, docs, chore, refactor, test, perf, ci, build)
```

## Dependency Management Policy

Document how third-party dependencies are managed:

**Selection criteria (before adding any dependency):**
1. Is there a simpler solution without a new dependency?
2. How actively maintained is it? (last commit within 6 months, issues responded to)
3. What is the license? (MIT/Apache-2.0: fine. GPL: requires legal review for commercial use)
4. How large is the dependency tree? (avoid dependency-heavy packages for simple problems)
5. Are there known security vulnerabilities? (check npm audit / snyk / osv.dev)

**Version pinning rules:**
- Pin exact versions in lockfile (package-lock.json, poetry.lock, go.sum)
- Use `^` or `~` in package.json/pyproject.toml as minimum, but lockfile is authoritative
- Never use `*` or `latest` in dependencies

**Security update SLA:**
- CRITICAL CVE in direct dependency: patch within 24 hours
- HIGH CVE in direct dependency: patch within 7 days
- MEDIUM CVE: next sprint
- LOW CVE: next quarterly dependency update

**Quarterly dependency audit:**
- Run `npm outdated` / `pip list --outdated` / `go list -m -u all`
- Review major version updates for breaking changes
- Update minor/patch versions in batch
- Document any dependencies intentionally held back (with reason)

---

## Step 6: Write Output Files

**Write/update $ARTIFACTS/plan/implementation-plan.md:**

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

**Write/update tasks into $STATE (state.json) under a "tasks" key:**

Tasks are stored as a JSON array in state.json. Each task object:
```json
{
  "id": "TASK-001",
  "description": "[description]",
  "effort": "M",
  "assignee": "@eng1",
  "depends": [],
  "status": "pending",
  "layer": "domain",
  "phase": 1,
  "tags": []
}
```
Status values: "pending" | "in_progress" | "blocked" | "done"

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

Mark Phase 7 (Plan) complete in $STATE.

Output:
```
✅ Plan Complete

Phases: [N]
Tasks: [N total] ([N] this session, [N] upcoming)
Parallelizable: [N tasks]
Highest Risk: [top risk]

Files:
• $ARTIFACTS/plan/implementation-plan.md
• $STATE (tasks array updated)

⚠️  GATE UNLOCKED: the code phase (tell Claude to proceed) can now proceed.
Recommended Next: the code phase (tell Claude to proceed) --task TASK-001
```
