# AI-SDLC — Enterprise Software Development Lifecycle for Claude Code

> Turn Claude Code into a disciplined engineering team. Go from raw idea to production-ready, fully documented, thoroughly tested software — with process gates, architecture standards, and quality enforced at every step.

---

## The Problem

AI coding assistants are powerful but undisciplined. Left to their own devices they:

- Jump straight to code before requirements are understood
- Build on shaky data models that break everything downstream
- Skip architecture decisions that matter at scale
- Write tests that test implementation details instead of requirements
- Ship code with no observability, no resilience patterns, no runbooks
- Produce undocumented decisions that haunt the team six months later

The result is fast-looking progress that collapses under real-world conditions.

---

## The Solution

**AI-SDLC** is a Claude Code plugin (`/sdlc:*`) that enforces a rigorous, opinionated software development lifecycle. It works the way a senior engineering team works — research before spec, spec before data model, data model before architecture, architecture before code — and it doesn't let you skip steps.

Every phase produces a canonical artifact. Every artifact is verified before the next phase starts. Every requirement traces forward to a test case. Every test case maps to an automation script. Every architectural decision is recorded as an ADR with a review trigger. Nothing falls through the cracks.

All commands operate in **INTERACTIVE mode** — you confirm direction before documents are written. Decisions that matter (tech stack, data model, architecture) pause for your review. Everything else runs.

---

## How to Use

---

### 1. Start a brand-new project

```
/sdlc:00-start "I want to build a payment processing API"
```

The orchestrator reads your description, classifies intent, detects complexity tier (SIMPLE / STANDARD / CRITICAL), and walks you through the full lifecycle in order:

```
Research → Synthesize → Product Spec → Data Model → Tech Architecture
→ Plan → Code → Test Cases → Test Automation → Observability → SRE → Review → Deploy
```

Phase gates are enforced automatically. No coding without a plan. No plan without a data model. You confirm the decisions that matter; everything else runs.

Each **checkpoint phase** (product spec, data model, architecture, plan, deploy) pauses for your review before proceeding.

---

### 2. Add a new feature to an existing project

**First time on an existing codebase — map it:**
```
/sdlc:map
```
Four parallel read-only agents scan the codebase and write a persistent index. Subsequent sessions load the index instead of re-scanning. Run once.

**Then start the iteration:**
```
/sdlc:iterate "add multi-currency support"
/sdlc:iterate "loyalty points module"
/sdlc:iterate --type enhancement "improve checkout performance"
```

`/sdlc:iterate` determines which phases the change actually touches and runs only those — in the correct order, with impact propagation. New REQ-IDs, TC-IDs, and ADRs continue the existing sequence; they never restart from zero.

Every iteration gets a stable ID (`ITER-001`, `ITER-002`, ...) tracked in `.sdlc/ITERATIONS/`.

**Explore the codebase before starting:**
```
/sdlc:explore "where is payment processing handled?"
/sdlc:explore "what calls OrderService?"
/sdlc:explore "if I change the user_id field, what breaks?"
```

---

### 3. Fix a bug

```
/sdlc:fix "order total is wrong when a discount is applied"
```

Lighter path — no spec update unless the bug reveals a design gap:

1. **Diagnose** — root cause, which data or behaviour is wrong
2. **Check data model** — does this reveal a model gap? If yes, fix the model first
3. **Plan** — what exactly changes, how it will be verified
4. **Code** — implement the fix in clean architecture
5. **Regression test** — new TC-ID added and automated
6. **Verify** — did the fix introduce any new issues?

For production incidents:
```
/sdlc:fix --hotfix "payment gateway returning 500"
```

---

### 4. Modernise legacy code

```
/sdlc:map          # build codebase index (if not done)
/sdlc:gaps         # surface tech debt, architecture drift, quality gaps

/sdlc:iterate --type nfr "upgrade to Node 22 and address security advisories"
/sdlc:iterate --type data "normalise the legacy orders schema"
/sdlc:maintain     # tech debt registry, maintenance planning
```

| Type flag | Use when |
|-----------|----------|
| `--type nfr` | New SLA target, performance requirement, or security baseline |
| `--type data` | Schema change, migration, data normalisation |
| `--type enhancement` | Extend or improve an existing feature |

---

### 5. Refactor

```
/sdlc:map
/sdlc:gaps
/sdlc:synthesize   # merge codebase analysis into strategic direction

/sdlc:iterate --type enhancement "extract payment domain into bounded context"
/sdlc:iterate --type enhancement "move infrastructure dependencies behind port interfaces"

/sdlc:review       # 12-dimension quality audit after completion
```

Refactors go through the plan phase — tasks ordered by clean architecture layer (domain → application → infrastructure → delivery), independently verifiable, dependency rule enforced throughout.

---

### Daily rhythm

```
Morning:   /sdlc:sod              ← reads checkpoint, sets goal, delivers brief
During:    /sdlc:checkpoint       ← save session state (or /loop 15m /sdlc:checkpoint)
Evening:   /sdlc:eod              ← clean stop, commit WIP, write tomorrow's first action

Status:    /sdlc:status           ← phases, active work, todos, next action
Resume:    /sdlc:resume           ← picks up exactly where you left off after /clear
Ship:      /sdlc:release          ← groups ITER-NNN + FIX-NNN into versioned release
```

---

## What You Get

### Intent-driven routing — only the phases that matter

| Intent | Entry point | Phase path |
|--------|------------|-----------|
| `new-project` | Research | Full lifecycle |
| `new-feature` | Product spec | idea → data-model → design → plan → code → test-cases → test-gen → verify → deploy |
| `bug-fix` | Plan | plan → code → test-cases → verify → deploy |
| `refactor` | Synthesize | synthesize → data-model check → plan → code → test-cases → verify |
| `modernise` | Synthesize / Plan | gaps → synthesize → plan → code → test-cases → verify |

```bash
/sdlc:start --intent bug-fix "order total wrong when discount applied"
/sdlc:start --intent new-feature "add multi-currency support"
```

---

### Hard-enforced phase gates

11 gates that block progression when structural requirements aren't met. Cannot be implicitly skipped — bypass requires `--force` with a logged justification.

| Gate | Upstream requires | Blocks |
|------|-----------------|--------|
| `idea→data-model` ⚠️ | `prd.md` ≥3 REQ-IDs, ≥3 acceptance criteria, out-of-scope section, no placeholders | data-model, test-cases |
| `data-model→tech-arch` ⚠️ | Mermaid ERD, data dictionary for every entity, `id`/`created_at`/`updated_at` on every entity | tech-arch |
| `data-model→test-cases` ⚠️ | ≥1 entity with documented invariants | test-cases |
| `plan→code` ⚠️ | ≥3 tasks with file changes, DoD, explicit approval | code |
| `test-cases→test-gen` ⚠️ | ≥3 TC-IDs, coverage matrix, no duplicate IDs, pyramid shape check | test-gen |
| `verify→deploy` | 0 open CRITICAL findings | deploy |
| + 5 more | research, synthesize, tech-arch, observability gates | — |

---

### Data model challenger review

After the data model is written but before it's finalised, an adversarial review takes an active attack posture against the design — not validation, but a structured attempt to find fatal flaws.

Six challenge dimensions:
1. **Missing entities** — features in the PRD with no corresponding model entities (audit tables, join entities, reference data, config entities)
2. **Aggregate boundaries** — anything in an aggregate that changes at a different rate; any use case that needs to modify two aggregates in one transaction; child entities accessed independently of the root
3. **Missing invariants** — state machine transitions, mandatory relationships, cross-field rules, and numeric constraints not encoded in the model
4. **Primitive obsession** — currency amounts without a paired currency code, phone/email/URL stored as plain VARCHAR, status fields as raw strings instead of typed enums
5. **Wrong cardinality** — traces each relationship with a concrete example to verify the cardinality is correct today and sound for likely future changes
6. **Naming and ubiquitous language** — entity/field names that diverge from the language used in the PRD; synonyms for the same concept across entities; generic names that cause confusion

Findings are classified BLOCKING (must fix before proceeding) or WARN (can proceed with a recorded decision). BLOCKING items pause the phase.

---

### Architecture challenger review

Before moving to planning, the architecture is reviewed from two explicit positions — not a self-check, but a structured adversarial debate to surface problems that confirmation bias would miss.

**Position A — Architect's defence:** states the strongest justification for each major decision (topology, database, auth strategy, patterns).

**Position B — Challenger's attack** across six dimensions:
1. **Over-engineering** — names every service, pattern, or abstraction that exists for a requirement not in the PRD, with its cost vs the concrete requirement it supposedly satisfies
2. **NFR gaps** — for each numeric NFR, identifies the specific architectural mechanism that delivers it; flags any NFR with no corresponding design mechanism
3. **Security surface** — walks every external entry point (endpoints, event consumers, admin interfaces, webhooks) and identifies anything not covered by the threat model
4. **Data model / API mismatch** — traces every API resource back to the data model; flags shapes that require joining multiple aggregates or fields with no clear source
5. **Operational survivability** — traces the three most likely failure scenarios and checks for circuit breakers, fallbacks, and graceful degradation for each
6. **Irreversible decisions** — ranks decisions by likelihood-of-being-wrong × cost-to-reverse; the highest-risk irreversible decisions are flagged for maximum scrutiny

Both positions are presented to the human side-by-side with options: address now, or accept the risk with a statement of assumption recorded in an ADR.

---

### Auto-verify loop after every code task

After each task completes, quality checks run automatically before the task can be marked done. This is an execution step, not a checklist — commands are run, failures are handled, and the task is blocked until everything passes.

**For each check:**
1. Run the command
2. On pass → proceed to next check
3. On fail → apply auto-fix (lint/format), re-run once
4. If still failing → surface a structured failure report with root-cause diagnosis and block task completion

**Four checks run per task:**

| Check | Auto-fix on failure |
|-------|-------------------|
| Lint (`eslint` / `ruff` / `golangci-lint` / `rubocop`) | Auto-fix, re-run |
| Format (`prettier` / `ruff format` / `gofmt`) | Auto-format, re-run |
| Type check (`tsc --noEmit` / `mypy`) | Fix manually, re-run |
| Unit tests + coverage gate (from config) | Diagnose failure, fix code, re-run |

Static scans also run in parallel: debug code (`console.log`, `pdb.set_trace`, `debugger`) and hardcoded secrets patterns. Debug code is auto-removed; hardcoded secrets are flagged as TD-NNN items requiring rotation.

On all checks passing, a gate result block is output before the task is marked done:
```
✅ Auto-Verify Gate PASSED — TASK-NNN
  Lint:       ✅ 0 errors
  Format:     ✅ clean
  Type check: ✅ 0 errors
  Tests:      ✅ 47 passed, coverage 84%
  Scans:      ✅ no debug code, no hardcoded secrets
```

---

### Requirements that actually drive the work

Every requirement gets a `REQ-ID`. Every business rule gets a `BR-ID`. Every NFR gets a **numeric threshold** — not "fast" but "p95 < 200ms at 1000 RPS". These IDs flow through to test cases, automation scripts, and SLOs. When a requirement changes, the full impact is traceable.

---

### A data model that's the single source of truth

The canonical data model is designed before architecture and code. Everything derives from it — API shapes, domain entities, test factories, database migrations. Change a field and automatic impact analysis tells you exactly what breaks downstream before touching a line of code.

DDD-first: bounded contexts, aggregates, entities, value objects, domain events. Standards applied per domain (ISO 20022, FHIR, GS1, ISO 4217, RFC 4122, ISO 8601). Data security classification built in per entity: PII fields, encryption-at-rest, log masking, retention periods.

---

### Clean architecture that stays clean

Code implements in strict layer order: domain → application → infrastructure → delivery. The dependency rule is enforced — no infrastructure imports in domain or application layers. Every external integration goes through a port interface. Composition root is the only place `new` is called.

Phase 8 has an explicit scope boundary: implements business logic and application-layer error handling. Resilience patterns (circuit breakers, bulkheads, graceful degradation) are Phase 12. Observability spec is Phase 11. This keeps each phase focused and prevents scope creep.

---

### End-to-end requirements traceability

Every requirement traces forward to a test case and backward from every test to its source:

```
REQ-001 (product spec)
  → TC-012, TC-013 (test cases)
    → test files (test automation)
      → CI coverage gate
NFR-003 (p95 < 200ms)
  → ADR-005 (architecture decision)
    → TC-041 (performance test)
      → OBS-007 (SLO)
        → sre/runbooks.md
```

Traceability matrix generated automatically by `/sdlc:traceability`. No orphaned tests. No uncovered requirements. Coverage gates fail the CI build.

---

### 9-layer test coverage

Test cases derived from every source document — requirements, API spec, data model invariants, architecture decisions, observability commitments:

| Layer | What's tested |
|-------|--------------|
| Unit | Domain entities, value objects, use cases in isolation |
| Integration | Repository implementations, adapter integrations |
| Contract | API consumer-driven contracts (Pact) |
| E2E | Full user journeys via UI or API |
| Performance | Latency and throughput against NFR thresholds |
| Scalability | Behaviour under peak load multipliers |
| Resilience | Circuit breaker trips, dependency failures, chaos scenarios |
| Observability | Logs emitted, spans created, metrics incremented |
| Security | OWASP API Top 10, auth bypass attempts, injection vectors |
| + Smoke/Synthetic | Production health monitoring |

Test gen (Phase 10) is a separate checkpoint from test cases (Phase 9) — you confirm the test strategy before automation code is generated.

---

### Observability as a first-class deliverable

Structured JSON logging with mandatory `trace_id` and `span_id` on every log entry. OpenTelemetry distributed tracing with W3C context propagation. Prometheus RED metrics at every service boundary. Health endpoints (`/health/live`, `/health/ready`, `/health/startup`) that actually check dependencies.

Every observability commitment gets an `OBS-ID` that test cases verify and SRE runbooks reference. OBS-IDs committed in Phase 11 before SRE phase begins — the SRE phase cannot start without them.

---

### Resilience built in, not bolted on

Every external dependency classified (CRITICAL / DEGRADABLE / OPTIONAL). Every CRITICAL dependency gets a circuit breaker. Every DEGRADABLE dependency gets a fallback. All clients get explicit connect and read timeouts. Chaos tests verify it all actually works.

---

### STRIDE threat modeling

Every external entry point (API endpoints, event consumers, webhooks, admin interfaces) is walked for threats. Auto-chains after architecture phase. Findings produce specific mitigations in the architecture and test cases covering the threat vectors.

---

### Production-ready microservice scaffolding

```bash
/sdlc:scaffold "payment-service"
```

Generates: clean architecture skeleton, multi-stage Dockerfile (non-root, layer caching), docker-compose dev stack, Kubernetes manifests (Deployment, Service, ConfigMap, HPA, PDB), Kustomize overlays for staging/prod, GitHub Actions CI/CD with Trivy CVE scanning, graceful shutdown handler, all three health probes.

---

### Cross-platform front-end generation

When a project includes a front-end:

```bash
/sdlc:fe-setup         # after Phase 6 — design tokens + screen spec from customer journey
/sdlc:fe-screen LoginScreen   # during Phase 8 — generates the screen
```

`/sdlc:fe-setup` builds a full design token set (12-step colour palette, semantic colours, typography scale, spacing, shadow, motion), configures the component library (Tamagui), and derives a screen inventory from the customer journey — every interactive step becomes a screen with template type, API endpoints, and all four states (loading/skeleton, empty, error+retry, success).

`/sdlc:fe-screen` generates a single screen: reads data requirements, wires typed TanStack Query hooks, applies tokens via the component library, implements all four states, enforces WCAG 2.1 AA.

Stack: Expo + React Native + Expo Router v3 — one codebase for iOS, Android, and Web.

---

### Branch-scoped workspaces

Every git branch has its own isolated workspace. State, artifacts, and progress are stored at `.sdlc/workflows/<branch>/`. Switching branches switches full context.

```
.sdlc/
  workflows/
    feature--payments/       ← feature/payments branch
      STATE.md               ← phase status, mode, decisions, gate overrides
      artifacts/             ← all phase outputs
    main/
  ITERATIONS/                ← ITER-001.md, ITER-002.md, ...
  codebase/                  ← brownfield map (shared across branches)
```

---

### Stale cascade

When you re-run a phase, all downstream phases are automatically flagged stale. The artifact is still readable — but the dashboard warns before you proceed on a stale foundation.

```
✅ data-model   — completed 2026-03-25
⚠️ tech-arch    — stale (data-model re-run)
⚠️ plan         — stale (data-model re-run)
⏳ code         — pending
```

---

### Decisions captured automatically

Every architectural and product decision made in conversation is silently recorded by the always-on `/sdlc:decide` skill. "We'll use Postgres", "dropping bulk import from v1", "JWT not sessions" — all written to `STATE.md` with the reason, the phase, and a flag for any downstream documents that may now be stale.

---

### Context management across sessions

**End of day — `/sdlc:eod`:** reaches a clean stop, commits WIP, saves a precise snapshot of where you are, tells you exactly what to run first tomorrow.

**During the day — `/loop 15m /sdlc:checkpoint`:** auto-saves state every 15 minutes. If Claude auto-compacts, nothing is lost.

**Start of day — `/sdlc:sod`:** reads yesterday's checkpoint, flags stale decisions, sets a realistic goal, delivers a structured brief.

---

### Documents structured for minimal token cost

Every document produced follows a strict writing standard: first 50 lines contain a TL;DR and contents index. Tables over prose. IDs at line start for single-grep lookups. Complexity budgets with hard limits per document type. The result: as the project grows to dozens of documents, context cost stays flat because Claude loads what it needs — not everything.

---

## The Lifecycle

Phases are organised in six tiers. `◉` = checkpoint phase (pauses for developer review). ⚠️ = hard gate.

### Tier 0 — ASSESS *(optional)*
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 0 | **Feasibility** `◉` | `/sdlc:feasibility` | Go/No-Go viability: market size, technical risk, competitive moat, build vs buy | `feasibility/feasibility.md` |

### Tier 1 — DISCOVER
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 1 | **Research** | `/sdlc:research` | Market landscape, competitive SWOT, best practices, emerging trends | `research/research.md`, `gap-analysis.md` |
| 1b | **Voice of Customer** *(optional)* | `/sdlc:voc` | Synthesize interviews, support tickets, NPS data into evidence-backed pain points | `voc/voc.md` |
| 2 | **Synthesize** | `/sdlc:synthesize` | Merge research + codebase analysis into unified strategic direction | `synthesize/synthesis.md` |

### Tier 2 — DEFINE
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 3 | **Product Spec** `◉` | `/sdlc:idea` | REQ-IDs, BR-IDs, numeric NFR-IDs, acceptance criteria, BDD scenarios, error handling table | `idea/prd.md` |
| 3b | **Personas** *(optional)* | `/sdlc:personas` | JTBD personas, empathy maps, anti-personas | `personas/personas.md` |
| 4 | **Customer Journey** *(optional)* | `/sdlc:journey` | Journey maps, failure paths, emotional states, screen flows | `journey/customer-journey.md` |
| 4b | **Business Process** *(optional)* | `/sdlc:business-process` | Back-office process maps — swimlanes, RACI, SLAs, exception paths. Flags new entities for Phase 5. | `business-process/business-process.md` |
| 4c | **Prototype** `◉` *(optional)* | `/sdlc:prototype` | Low-fidelity UX flows — validates interaction model before data model locks in | `prototype/prototype-spec.md` |

### Tier 3 — BUILD
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 5 | **Data Model** `◉` ⚠️ | `/sdlc:data-model` | DDD canonical model — bounded contexts, aggregates, ERDs, invariants, data dictionary. Includes adversarial challenger review before finalising. Hard gate for tech-arch, plan, test-cases. | `data-model/data-model.md`, `data-dictionary.md` |
| 6 | **Tech Architecture** `◉` | `/sdlc:design` | C4 diagrams, clean architecture layers, LLD, API spec, ADRs, security design, resilience strategy. Includes two-position challenger review. Auto-chains: threat-model, adr-gen, infra-design. | `tech-arch/tech-architecture.md`, `lld.md`, `api-spec.md`, `solution-design.md` |
| 6b | **FE Setup** *(optional)* | `/sdlc:fe-setup` | Design tokens (3 levels), component library, screen spec derived from customer journey | `fe-setup/design-tokens.md`, `screen-spec.md` |
| 7 | **Plan** `◉` ⚠️ | `/sdlc:plan` | Atomic tasks ordered by clean architecture layer. Auto-chains: observability, sre, roadmap. | `plan/implementation-plan.md` |
| 8 | **Code** `◉` | `/sdlc:build` | Implement tasks. Auto-verify gate runs after every task (lint, format, types, tests). Auto-chains: test-gaps, security, audit-deps, pii-audit. | Source files |

### Tier 4 — VERIFY
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 9 | **Test Cases** `◉` ⚠️ | `/sdlc:test-cases` | MECE Given/When/Then across 9 layers + Smoke/Synthetic, anchored to every source document. Runs twice: after Phase 8, re-run after Phase 12. Auto-chains: traceability. | `test-cases/test-cases.md` |
| 10 | **Test Generation** `◉` | `/sdlc:test-gen` | Generate automation scripts from test cases — 1:1 TC-ID mapping, coverage gate enforcement, drift detection | `test-gen/test-automation.md`, test files |
| 11 | **Observability** | `/sdlc:observability` | Structured logging spec, OTel tracing, Prometheus RED metrics — OBS-IDs committed before SRE | `observability/observability.md` |
| 12 | **SRE** | `/sdlc:sre` | SLOs, runbooks per critical failure scenario, incident response, resilience pattern verification | `sre/runbooks.md` |
| 13 | **Verify** `◉` | `/sdlc:verify` | Cross-cutting quality audit — 0 open CRITICAL findings required to proceed | `verify/verification-report.md` |
| 13b | **UAT** `◉` *(optional)* | `/sdlc:uat` | Stakeholder acceptance testing plan — UAT-NNN scenarios, entry/exit criteria, sign-off record | `uat/uat-plan.md` |

### Tier 5 — SHIP
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 14 | **Deploy** `◉` | `/sdlc:deploy` | Deployment checklist, rollback plan, handoff. CI/CD gate: pipeline must pass before release. Auto-chains: release-notes, maintain. | `deploy/deployment-checklist.md` |

### Tier 6 — SUSTAIN *(optional)*
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 15 | **Maintain** | `/sdlc:maintain` | Tech debt registry, maintenance planning, scheduled operations | `maintain/maintenance-plan.md` |
| 16 | **Retro** `◉` | `/sdlc:retro` | Project retrospective — timeline, contributing factors, action items with owners | `retro/retro.md` |

---

## Phase Gates

All 11 gates are hard-enforced. Bypass with `--force` (reason required, logged to `STATE.md`).

| Gate | Upstream requires | Blocks | Key structural checks |
|------|-----------------|--------|----------------------|
| `research→synthesize` | `research.md` ≥2 named competitors + `gap-analysis.md` | synthesize | Market Landscape section, ≥1 gap |
| `synthesize→idea` | `synthesis.md` with synthesis language | idea | No `{{placeholder}}` or `[TBD]` |
| `idea→data-model` ⚠️ | `prd.md` ≥3 REQ-IDs + ≥3 acceptance criteria + out-of-scope section | data-model, test-cases | No placeholders |
| `data-model→tech-arch` ⚠️ | `data-model.md` ≥1 bounded context + Mermaid ERD + `data-dictionary.md` for every entity | tech-arch | id/created_at/updated_at on every entity |
| `data-model→test-cases` ⚠️ | `data-model.md` + `data-dictionary.md` + ≥1 entity with invariants | test-cases | — |
| `tech-arch→plan` | `tech-architecture.md` + `lld.md` + `api-spec.md` + `solution-design.md` ≥1 ADR | plan | No placeholders |
| `plan→code` ⚠️ | `implementation-plan.md` ≥3 tasks + file changes + DoD + explicit approval | code | — |
| `code→verify` | ≥1 source file modified + ≥1 task done | verify | — |
| `test-cases→test-gen` ⚠️ | `test-cases.md` ≥3 TC-IDs + coverage matrix + no duplicate IDs | test-gen | Pyramid shape check, AC-to-TC audit, NFR coverage |
| `observability→sre` | `observability.md` with logging spec + `trace_id`/`span_id` mandatory + RED metrics | sre | — |
| `verify→deploy` | `verification-report.md` 0 open CRITICAL findings | deploy | — |

---

## Installation

AI-SDLC is a set of Claude Code custom commands and workflow files — Markdown instruction files that Claude reads and executes. No npm package, no runtime binary, no install script.

```bash
# Clone the repo
git clone https://github.com/seanieb9/ai-sdlc.git

# Install commands globally (available in all projects)
cp -r ai-sdlc/commands/sdlc ~/.claude/commands/

# Install workflow engine, references, and templates globally
cp -r ai-sdlc/workflows ai-sdlc/references ai-sdlc/templates ~/.claude/sdlc/
```

Open any project in Claude Code and run `/sdlc:00-start "your idea"` to start a new project, or `/sdlc:00-start` (no args) to see the status of an existing one.

On first run, the system automatically:
1. Detects your git branch and creates a branch-scoped workspace at `.sdlc/workflows/<branch>/`
2. Creates `.sdlc/CLAUDE.md` (framework reference)
3. Asks setup questions → generates `.sdlc/config.yaml`
4. Offers to add `.gitignore` entries

### Configure

Edit `.sdlc/config.yaml`:

```yaml
projectName: "my-service"
techStack:
  language: typescript
  framework: nestjs
  database: postgresql
  testFramework: jest
  containerRuntime: Docker
  orchestrator: Kubernetes
quality:
  coverage:
    overall: 80
    businessLogic: 90
```

### What to commit vs exclude

```gitignore
# Per-developer runtime state — do NOT commit
.sdlc/workflows/*/STATE.md
.sdlc/workflows/*/progress.json

# Commit these (team-shared artifacts)
# .sdlc/CLAUDE.md
# .sdlc/config.yaml
# .sdlc/workflows/*/artifacts/
# .sdlc/codebase/
# .sdlc/ITERATIONS/
```

---

## Commands

### The main interface

| Command | What it does |
|---------|-------------|
| `/sdlc:00-start [idea]` | **Universal entry point.** New project, status check, daily brief, resume — handles everything. |
| `/sdlc:iterate <feature>` | **Add or evolve features.** Scoped mini-lifecycle — runs only the phases the change touches. |
| `/sdlc:fix <what's broken>` | **Fix things.** Bug fixes (default), hotfixes (`--hotfix`), maintenance (`--maintenance`). |
| `/sdlc:release [version]` | **Ship work.** Groups ITER-NNN + FIX-NNN into a versioned release with CHANGELOG.md. |
| `/sdlc:review [area]` | **Quality audit.** 12-dimension review: requirements, data, arch, tests, resilience, security. |

### Codebase navigation

| Command | What it does |
|---------|-------------|
| `/sdlc:explore <question>` | Answer codebase questions: "where is X?", "what calls Y?", "how are errors handled?" |
| `/sdlc:map` | Brownfield setup — 4 parallel agents map architecture, tech stack, conventions, cross-cutting concerns. Run once. |
| `/sdlc:gaps` | 3 gap analysis agents — tech debt, architecture drift, quality/coverage gaps. |

### Daily cheatsheet

```
Morning:    /sdlc:sod
Afternoon:  /sdlc:iterate "add loyalty points"                       ← new feature
            /sdlc:fix "cart total wrong"                             ← bug fix
            /sdlc:iterate --type nfr "upgrade deps, address CVEs"    ← modernise
            /sdlc:iterate --type enhancement "refactor payment domain" ← refactor
Evening:    /sdlc:eod

Ready to ship:    /sdlc:release --minor
Quality check:    /sdlc:review
Production fire:  /sdlc:fix --hotfix "payment gateway down"
```

---

### Advanced / direct phase access

<details>
<summary>Show all phase commands</summary>

**Assessment**
- `/sdlc:feasibility` — Go/No-Go viability assessment
- `/sdlc:assess` — brownfield readiness scoring (codebase quality, test coverage, observability baseline)

**Discovery**
- `/sdlc:research <topic>` — market research, competitive SWOT, best practices
- `/sdlc:voc [topic]` — synthesize customer feedback into prioritized pain points
- `/sdlc:synthesize` — merge research + codebase into unified strategic picture

**Specification**
- `/sdlc:clarify` — guided requirements elicitation → `clarify-brief.md` with FR-IDs and NFR-IDs
- `/sdlc:idea <feature>` — product spec with REQ-IDs, BDD scenarios, NFRs, error handling
- `/sdlc:personas` — JTBD personas, empathy maps, anti-personas
- `/sdlc:journey <persona>` — journey maps, failure paths, screen flows
- `/sdlc:business-process` — back-office processes, swimlanes, RACI, SLAs
- `/sdlc:prototype` — low-fidelity UX flows

**Design**
- `/sdlc:data-model <domain>` — DDD canonical data model, ERDs, invariants, data dictionary + adversarial challenger review
- `/sdlc:design <system>` — C4 architecture, LLD, API spec, ADRs, resilience design + two-position challenger review
- `/sdlc:compare` — generate 2-3 design alternatives → decision in ADR format
- `/sdlc:nfr-analysis` — decompose NFRs into architectural implications *(auto-chain after idea)*
- `/sdlc:threat-model` — STRIDE threat modeling per component and trust boundary *(auto-chain after design)*
- `/sdlc:adr-gen` — validate ADR completeness and traceability *(auto-chain after design)*
- `/sdlc:infra-design` — IaC scaffold (Dockerfile, Helm, Terraform) from architecture *(auto-chain after design)*

**Front-end** *(when project includes a front-end)*
- `/sdlc:fe-setup` — design tokens, component library, screen spec from customer journey
- `/sdlc:fe-screen <screen>` — generate a screen from screen spec

**Execution**
- `/sdlc:plan <feature>` — layered execution plan + task list
- `/sdlc:build <task>` — implement tasks following clean architecture; auto-verify gate runs after each task
- `/sdlc:scaffold <service>` — production service scaffold (clean arch skeleton, Docker, K8s, CI/CD)

**Quality**
- `/sdlc:test-cases <feature>` — 9-layer MECE test cases with TC-IDs
- `/sdlc:test-gen <feature>` — generate automation scripts from test cases (1:1 TC-ID mapping)
- `/sdlc:test-gaps` — test coverage gap analysis *(auto-chain after code)*
- `/sdlc:traceability` — requirements → code → tests traceability matrix *(auto-chain after test-cases)*
- `/sdlc:pii-audit` — cross-check OBS-IDs against PII fields *(auto-chain after code)*
- `/sdlc:audit-deps` — CVE + freshness + necessity audit *(auto-chain after code)*

**Reliability**
- `/sdlc:observability <service>` — structured logging, OTel tracing, Prometheus RED metrics *(auto-chain after plan)*
- `/sdlc:sre <service>` — SLOs, runbooks, incident response, resilience verification *(auto-chain after plan)*
- `/sdlc:ci-verify` — CI pipeline completeness check (hard gate in deploy)

**Ship & Sustain**
- `/sdlc:uat` — stakeholder acceptance testing plan (UAT-NNN scenarios, sign-off record)
- `/sdlc:deploy` — deployment checklist, rollback plan, handoff
- `/sdlc:maintain` — tech debt registry, maintenance planning *(auto-chain after deploy)*
- `/sdlc:retro` — project retrospective

**Session / admin**
- `/sdlc:sod` / `/sdlc:eod` / `/sdlc:checkpoint` / `/sdlc:resume` — daily session management
- `/sdlc:verify [--phase N]` — quality gate for a completed phase
- `/sdlc:status` — live dashboard: phases, gates, implementation progress, stale flags
- `/sdlc:roadmap` — human-effort planning (Design/Review/Sync sessions)
- `/sdlc:debt` — list and export technical debt register (TD-IDs)
- `/sdlc:decide` — always-on decision capture (silently records to `STATE.md`)

</details>

---

## What Gets Produced

Every phase outputs to a canonical artifact. Updated in place — never versioned with `_v2` suffixes, never duplicated.

```
.sdlc/
  workflows/
    <branch>/
      STATE.md
      artifacts/
        feasibility/        feasibility.md
        research/           research.md, gap-analysis.md
        voc/                voc.md
        synthesize/         synthesis.md
        idea/               prd.md
        personas/           personas.md
        journey/            customer-journey.md
        business-process/   business-process.md
        prototype/          prototype-spec.md
        data-model/         data-model.md, data-dictionary.md    ⚠️
        tech-arch/          tech-architecture.md, lld.md, api-spec.md, solution-design.md
        threat-model/       threat-model.md
        infra-design/       Dockerfile, helm/, terraform/
        fe-setup/           design-tokens.md, component-library.md, screen-spec.md
        plan/               implementation-plan.md
        test-cases/         test-cases.md
        test-gen/           test-automation.md, test files
        observability/      observability.md
        sre/                runbooks.md
        verify/             verification-report.md
        uat/                uat-plan.md
        deploy/             deployment-checklist.md
        maintain/           maintenance-plan.md
        retro/              retro.md
  ITERATIONS/
    ITER-001.md             scope, phase map, ID continuity
    ITER-002.md
```

---

## ID System

All IDs follow `PREFIX-NNN` (zero-padded to 3 digits). IDs are permanent — deprecated, never deleted.

| Prefix | Meaning | Assigned in | Flows to |
|--------|---------|------------|---------|
| `REQ-NNN` | Functional Requirement | Product spec | Test cases, tasks, acceptance criteria |
| `BR-NNN` | Business Rule | Product spec | Test cases, data model invariants |
| `NFR-NNN` | Non-Functional Requirement (numeric threshold) | Product spec | ADRs, test cases, SLOs |
| `ADR-NNN` | Architecture Decision Record | Tech architecture | Review triggers |
| `TC-NNN` | Test Case (tagged by layer) | Test cases | Automation scripts |
| `OBS-NNN` | Observability commitment | Observability | Test cases, SRE runbooks |
| `UAT-NNN` | Stakeholder acceptance scenario | UAT | Deploy gate |
| `TD-NNN` | Technical Debt item | Code phase | Debt register |
| `DEC-NNN` | Decision record | Any phase | `STATE.md` |

---

## Standards Encoded

| Area | Standards Applied |
|------|------------------|
| Data modeling | DDD (bounded contexts, aggregates, entities, value objects), ISO 4217, ISO 8601, RFC 4122, E.164, domain-specific (ISO 20022, FHIR, GS1) |
| Architecture | Clean Architecture, Ports & Adapters, C4 Model, OpenAPI 3.x, CQRS, Saga, Outbox Pattern, Event Sourcing |
| Product | SMART NFRs, MoSCoW prioritisation (≤40% Must), JTBD, BDD completeness, anti-personas |
| Testing | MECE, Given/When/Then (BDD), Testing Pyramid, Consumer-Driven Contract Testing (Pact), 9-layer coverage model |
| Observability | OpenTelemetry, W3C TraceContext, Prometheus/OpenMetrics, structured JSON logging, RED metrics |
| Resilience | Circuit Breaker, Retry + Full Jitter Backoff, Bulkhead, Graceful Degradation, Idempotency Keys, Chaos Testing |
| API design | REST conventions, URI versioning, RFC 8594 Sunset headers, cursor pagination, OWASP API Top 10 |
| Deployment | Multi-stage Dockerfile, non-root containers, K8s resource limits/probes/HPA/PDB, Blue-Green/Canary strategies |
| Security | STRIDE threat modeling, secret rotation lifecycle, dependency vulnerability scanning (SBOM/Trivy) |
| Data operations | Zero-downtime migration patterns (expand/contract, dual-write), indexing strategy, caching strategy |
| Frontend | Expo SDK, React Native, Expo Router v3, Tamagui design tokens, TanStack Query v5, WCAG 2.1 AA |
| Documentation | 50-line rule, tables over prose, ID-first formatting, complexity budgets |

---

## Key Design Principles

**Data model first.** Architecture, API shapes, and code all derive from the canonical data model. Change a field and automatic impact analysis shows exactly what breaks downstream before you touch a line of code.

**No code without a plan.** Tasks are atomic, layered (domain → application → infrastructure → delivery), and independently verifiable. The dependency rule is enforced — domain code has zero infrastructure imports.

**Verify at every level.** Auto-verify runs after every code task. Challenger reviews challenge data models and architectures before they're finalised. 11 phase gates block progression on structural gaps. A cross-cutting quality audit gates deployment.

**Tests from requirements, not from code.** Test cases derived from every source document. Nine layers ensure nothing is missed. Every TC-ID traces to a source. Coverage gates fail the CI build.

**Phase scope boundaries are explicit.** Phase 8 implements business logic — nothing more. Resilience patterns are Phase 12. Observability spec is Phase 11. This prevents scope creep and keeps each phase focused.

**Documents are living artifacts.** IDs (REQ, BR, TC) are permanent — only deprecated, never deleted. When requirements change, downstream stale flags are raised automatically.

**Token cost is a design constraint.** Documents are structured to be partially loadable — first 50 lines orient, sections answer one question each. Claude loads what it needs, not everything. Context cost stays flat as the project grows.

---

## License

MIT
