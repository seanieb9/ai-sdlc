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

**AI-SDLC** is a set of Claude Code custom commands (`/sdlc:*`) that enforce a rigorous, opinionated software development lifecycle. It works the way a senior engineering team works — research before spec, spec before data model, data model before architecture, architecture before code — and it doesn't let you skip steps.

Every phase produces a canonical document. Every document is verified before the next phase starts. Every requirement traces forward to a test case. Every test case maps to an automation script. Every architectural decision is recorded as an ADR with a review trigger. Nothing falls through the cracks.

**One command to start anything:**
```bash
/sdlc:00-start "I want to build a payment processing integration"
```
The orchestrator reads your project state, figures out where you are, enforces what gates need to pass, and routes you to exactly the right next step.

---

## What You Get

### Requirements that actually drive the work
Every requirement gets a `REQ-ID`. Every business rule gets a `BR-ID`. Every NFR gets a **numeric threshold** — not "fast" but "p95 < 200ms at 1000 RPS". These IDs flow all the way through to test cases and automation. When a requirement changes, you know exactly what breaks.

### A data model that's the single source of truth
The canonical data model is designed before architecture and code. Everything derives from it — API shapes, domain entities, test factories, database migrations. Change a field in the data model and automatic impact analysis tells you exactly what breaks downstream before you touch a line of code.

### Clean architecture that stays clean
Code is implemented in strict layer order: domain → application → infrastructure → delivery. The dependency rule (no infrastructure imports in domain or application layers) is enforced. Every external integration goes through a port interface. No God objects, no magic numbers, no spaghetti.

### Cross-platform screens generated from journey maps

When a project includes a front-end, one command turns the customer journey into a complete screen specification:

```bash
/sdlc:fe-setup   # after Phase 6 — configures tokens, derives SCREEN_SPEC.md
/sdlc:fe-screen LoginScreen   # during Phase 8 — generates the screen
```

**`/sdlc:fe-setup`** asks one question (design system level: none / brand color / full ingest), then:
- Builds a full design token set — 12-step color palette, semantic colors, typography scale, spacing, shadow, motion
- Configures the component library (Tamagui by default for cross-platform performance)
- Walks the customer journey and derives a screen inventory: every interactive step becomes a screen, each assigned a template type, API endpoints mapped, and all four states documented (loading → skeleton, empty, error + retry, success)

**`/sdlc:fe-screen`** generates a single screen from that spec:
- Reads the screen's data requirements and wires API calls as typed TanStack Query hooks
- Applies tokens via the component library — no hardcoded colors, no magic numbers
- Implements all four states and extracts any component that appears in 2+ screens to `components/ui/`
- Enforces WCAG 2.1 AA: 44×44pt touch targets, contrast ratios, screen reader labels, focus management

The stack is Expo + React Native + Expo Router v3 — one codebase for iOS, Android, and Web. Clean architecture applies to the FE layer too: business logic stays in hooks and services, screens are pure view layer.

The `[fe]` task tag in `TODO.md` is the discriminator — Phase 8 (`/sdlc:08-code`) detects it and switches to the FE workflow automatically. The rest of the BE path is unchanged.

### Tests anchored to requirements, not vibes
Test cases are derived from every source: requirements, API spec, data model invariants, architecture decisions, observability commitments. Eight test layers — unit, integration, contract, E2E, performance, resilience, observability, security — all with TC-IDs that trace back to a source document. No orphaned tests. No uncovered requirements. Coverage gates fail the CI build.

### Resilience built in, not bolted on
Every external dependency is classified (CRITICAL / DEGRADABLE / OPTIONAL) with explicit timeouts, circuit breakers, fallbacks, and retry logic. The system checks that your CRITICAL dependencies have circuit breakers, your DEGRADABLE dependencies have fallbacks, and every client has explicit connect and read timeouts. Chaos tests verify it all actually works.

### Observability as a first-class deliverable
Structured JSON logging with mandatory `trace_id` and `span_id` fields. OpenTelemetry distributed tracing with W3C context propagation. Prometheus RED metrics at every service boundary. Health endpoints (`/health/live`, `/health/ready`, `/health/startup`) that actually check dependencies. All committed to `OBSERVABILITY.md` with `OBS-IDs` that test cases verify.

### Production-ready microservice scaffolding in one command
```bash
/sdlc:microservices "payment-service"
```
Generates: clean architecture skeleton, multi-stage Dockerfile (non-root user, layer caching), docker-compose local dev stack, Kubernetes manifests (Deployment, Service, ConfigMap, HPA, PDB), Kustomize overlays for staging/production, GitHub Actions CI/CD pipeline with Trivy CVE scanning, graceful shutdown handler, all three health probes.

### A planning construct built for agentic development

Story points measure coding effort. In agentic development, coding is largely automated — the scarce resource is **human judgment and attention**. AI-SDLC uses a different planning unit: the **Human Session**.

```bash
/sdlc:roadmap   # generates .sdlc/ROADMAP.md
```

Three session types map to where humans are actually needed:

| Type | Symbol | When |
|------|--------|------|
| **Design (D)** | ✍ | Human drives — product spec, data model, architecture, review. Judgment-heavy. |
| **Review (R)** | 👁 | AI ran, human validates — research output, test cases, plan. Async-friendly. |
| **Sync (S)** | 👥 | Microsquad alignment — phase handoffs, gate decisions. 30 min. |

Every phase gets an **AI autonomy level** — from 🤖 Autonomous (code, test automation: human not needed) to ✍ Collaborative (product spec, data model: human must drive). This tells a microsquad who needs to be present and when.

The roadmap surfaces the critical path clearly: **Product Spec → Data Model → Tech Architecture → Code**. The data model is the highest-risk gate — extra design sessions here pay for themselves many times over. The code phase is fully autonomous.

For a typical new service: **~16 Design Sessions + ~3 Review Sessions** of human effort. The rest is AI. Optional for individual developers — skip it and work phase by phase if you prefer.

### Decisions captured automatically — never lost to context

Every architectural and product decision made in conversation is silently recorded to `.sdlc/STATE.md` by an always-on background skill. No command to run. No reminder needed. The moment you say "we'll use Postgres", "JWT not sessions", or "dropping bulk import from v1" — it's written down with the reason and a flag for any downstream documents that may now be stale.

### Documents structured for both human and AI reading

Every document produced by AI-SDLC follows a strict writing standard that serves two goals simultaneously: readable by a human in under 5 minutes, and answerable by Claude using the minimum possible tokens.

The **50-line rule**: every document's first 50 lines contain a TL;DR and a contents index — so Claude can orient and jump to the relevant section without loading the whole file. **Tables over prose**: structured data (requirements, fields, decisions, error codes) always in tables at ~40% fewer tokens. **IDs at line start**: every REQ-ID, BR-ID, TC-ID, ADR-ID begins its line so any reference is a single grep away. **Complexity budgets**: hard limits per document type that trigger sharding before a file becomes a monolith Claude loads in full every time.

The result: as your project grows to dozens of documents, token cost stays flat because Claude loads what it needs — not everything.

### An independent quality gate between every phase
```bash
/sdlc:verify --phase 5   # after data model
/sdlc:verify --all       # full audit
```
Verification goes beyond "does the file exist?" — it checks completeness (no placeholders, all required sections), internal consistency (every entity has timestamps and invariants), and cross-phase consistency (every NFR in the spec has an architectural decision that addresses it, every API endpoint has a contract test).

### Brownfield codebase understanding without heavy tooling

Industrial solutions for navigating existing codebases — code indexers, dependency graphs, knowledge graphs, semantic search — are powerful but heavy. They need setup, maintenance, and compute. AI-SDLC takes a different approach: a persistent, version-controlled index that lives right in the repo.

```bash
/sdlc:map      # analyse the codebase, write .sdlc/CODEBASE_MAP.md
```

The map contains everything needed for intelligent navigation: tech stack, architecture pattern, annotated directory tree, domain concept → file mappings, all API routes, data access patterns, cross-cutting concerns (auth, logging, error handling), dependency hotspots, test structure, tech debt notes, and project-specific grep recipes. It takes minutes to generate and lives in `.sdlc/` alongside STATE.md.

Once the map exists, `/sdlc:explore` answers codebase questions with a read-the-map-first strategy:

```bash
/sdlc:explore "where is payment processing handled?"
/sdlc:explore "what calls OrderService?"
/sdlc:explore "if I change the user_id field, what breaks?"
/sdlc:explore "show me all API endpoints"
/sdlc:explore "how are errors handled here?"
```

The map is also consumed automatically by `/sdlc:02-synthesize` (no re-scanning the whole codebase) and by the orchestrator on startup (context-aware routing from the first command). When `/sdlc:explore` discovers something the map missed, it updates the map — so it gets better over time.

### Context management that actually works across sessions
One of the hardest problems with AI-assisted development is losing context — mid-session when Claude auto-compacts, or the next morning when you start fresh. AI-SDLC solves this with a structured daily loop:

**End of day — `/sdlc:eod`**
Reaches a clean stopping point, commits work in progress with a descriptive message, saves a precise snapshot of where you are (phase, step, open decisions, anything said verbally that isn't in the docs), and tells you exactly what to run first tomorrow.

**During the day — `/loop 15m /sdlc:checkpoint`**
Auto-saves your session state every 15 minutes. If context fills and Claude auto-compacts, nothing is lost. `/clear` followed by `/sdlc:resume` restores full context in under a minute.

**Start of day — `/sdlc:sod`**
Reads yesterday's checkpoint, flags any stale decisions or unverified phases, sets a realistic goal for the day, and delivers a structured brief — before executing a single thing. One "go" and you're working again.

```
Morning:  /sdlc:sod
During:   /loop 15m /sdlc:checkpoint
Evening:  /sdlc:eod
```

No more "where was I?". No more re-explaining context to a fresh Claude. No more lost decisions. The project state lives in files — and the daily ritual keeps those files exactly current.

---

## The Lifecycle

Each phase must be verified with `/sdlc:verify` before the next begins. Hard gates are marked ⚠️.

| # | Phase | Command | What it does | Output |
|---|-------|---------|-------------|--------|
| 1 | **Research** | `/sdlc:01-research` | Deep competitive intelligence, SWOT analysis, best practices, emerging trends | `RESEARCH.md`, `GAP_ANALYSIS.md` |
| 1b | **Voice of Customer** | `/sdlc:01b-voc` | Synthesizes interviews, support tickets, NPS data into prioritized, evidence-backed pain points | `VOC.md` |
| 2 | **Synthesize** | `/sdlc:02-synthesize` | Merges research findings with existing codebase analysis into a unified strategic picture | `SYNTHESIS.md` |
| 3 | **Product Spec** | `/sdlc:03-product-spec` | Defines REQ-IDs, BR-IDs, numeric NFRs, BDD scenarios, error handling table, acceptance criteria | `PRODUCT_SPEC.md` |
| 3b | **Personas** | `/sdlc:03b-personas` | Rigorous persona definitions using Jobs-to-be-Done, empathy maps, and anti-personas. Optional — if skipped, Phase 4 creates a minimal `PERSONAS.md` from inline definitions so downstream phases always have it. | `PERSONAS.md` |
| 4 | **Customer Journey** | `/sdlc:04-customer-journey` | Journey maps for every persona — happy paths, failure paths, emotional states, screen flows | `CUSTOMER_JOURNEY.md` |
| 4b | **Business Process** *(optional)* | `/sdlc:04b-business-process` | Map back-office and operational processes — approvals, fulfillment, exception handling, compliance, escalation paths. Produces BP-IDs, swimlane diagrams, RACI, SLAs. Flags new entities and state machines for the data model. | `BUSINESS_PROCESS.md` |
| 5 | **Data Model** ⚠️ | `/sdlc:05-data-model` | Canonical DDD data model — bounded contexts, aggregates, ERDs, invariants, data dictionary. Everything downstream derives from this. | `DATA_MODEL.md`, `DATA_DICTIONARY.md` |
| 6 | **Tech Architecture** ⚠️ | `/sdlc:06-tech-arch` | C4 diagrams, clean architecture layers, security design, dependency classification, resilience strategy, ADRs | `TECH_ARCHITECTURE.md`, `API_SPEC.md`, `SOLUTION_DESIGN.md` |
| 6b | **FE Setup** *(optional)* | `/sdlc:fe-setup` | Configure design tokens (3 levels), set up component library, derive `SCREEN_SPEC.md` from customer journey. Run when the project has a front-end. | `DESIGN_TOKENS.md`, `COMPONENT_LIBRARY.md`, `SCREEN_SPEC.md` |
| 7 | **Plan** | `/sdlc:07-plan` | Breaks work into atomic tasks ordered by clean architecture layer: domain → application → infrastructure → delivery | `PLAN.md`, `TODO.md` |
| 8 | **Code** | `/sdlc:08-code` | Implements tasks following strict clean architecture — no shortcuts, no vibe coding | Source code |
| 9 | **Test Cases** | `/sdlc:09-test-cases` | MECE Given/When/Then test cases across 8 layers, anchored to every source document with full traceability. **Runs twice:** first pass after Phase 8 covers 6 layers; re-run after Phase 12 adds Observability and Resilience layers once those specs exist. | `TEST_CASES.md` |
| 10 | **Test Automation** | `/sdlc:10-test-automation` | Automation scripts with 1:1 TC-ID mapping, coverage gate enforcement, and drift detection | `TEST_AUTOMATION.md`, test files |
| 11 | **Observability** | `/sdlc:11-observability` | Structured logging spec, OpenTelemetry tracing, Prometheus RED metrics — designed in, not bolted on | `OBSERVABILITY.md` |
| 12 | **SRE** | `/sdlc:12-sre` | SLOs, operational runbooks per critical failure scenario, incident response, resilience pattern verification | `RUNBOOKS.md`, `SLO.md` |
| 13 | **Review** | `/sdlc:13-review` | Cross-cutting quality audit across 12 dimensions: requirements, data, architecture, tests, resilience, deployment, and more | `REVIEW_REPORT.md` |

---

## Phase Gates

Hard-enforced by the orchestrator. Bypass with `--force <phase>` (reason logged to STATE.md).

| Gate | Blocks | Requires |
|------|--------|---------|
| PRODUCT-SPEC | `data-model`, `test-cases` | `docs/product/PRODUCT_SPEC.md` |
| DATA-MODEL ⚠️ | `tech-arch`, `plan`, `code` | `DATA_MODEL.md` **and** `DATA_DICTIONARY.md` |
| TECH-ARCH | `plan`, `code` | `TECH_ARCHITECTURE.md` **and** `API_SPEC.md` **and** `SOLUTION_DESIGN.md` |
| PLAN | `code` | `.sdlc/PLAN.md` with tasks |
| TEST-CASES | `test-automation` | `docs/qa/TEST_CASES.md` |
| OBSERVABILITY | `sre` | `docs/sre/OBSERVABILITY.md` |

After every phase, `/sdlc:verify --phase N` independently checks that outputs are complete, consistent, and cross-reference correctly before the next phase starts.

---

## Installation

```bash
# Clone the repo
git clone https://github.com/seanieb9/ai-sdlc.git

# Copy commands into Claude Code's custom commands directory
cp -r ai-sdlc/commands/sdlc ~/.claude/commands/

# Copy the workflow engine, references, and templates
cp -r ai-sdlc/workflows ai-sdlc/references ai-sdlc/templates ~/.claude/sdlc/
```

That's it. Open any project in Claude Code and run `/sdlc:00-start`.

> **Note:** The `@file` references inside each command point to `~/.claude/sdlc/`. If you install to a different path, update the `<execution_context>` blocks in `commands/sdlc/*.md`.

---

## Commands

### Orchestration
| Command | Description |
|---------|-------------|
| `/sdlc:00-start <idea>` | **Always start here.** Reads state, enforces gates, routes to the right phase |
| `/sdlc:sod` | **Start of day.** Reads yesterday's checkpoint, surfaces blockers, plans today's session, delivers a brief — waits for "go" before executing |
| `/sdlc:eod` | **End of day.** Reaches a clean stopping point, commits work, saves checkpoint, prints tomorrow's first action |
| `/sdlc:checkpoint` | **Mid-session save.** Writes phase/step, next action, open decisions, and verbal context to `.sdlc/NEXT_ACTION.md`. Use with `/loop 15m /sdlc:checkpoint` |
| `/sdlc:resume` | **Resume after `/clear`.** Reads checkpoint, delivers brief, waits for confirmation |
| `/sdlc:verify [--phase N\|--last\|--all]` | **Run after every phase.** Independent quality gate with per-phase checklists |
| `/sdlc:status` | Live dashboard — phases, todos, doc health, recommended next action. **Auto-triggers** when you ask "what's next?" or "where are we?" |
| `/sdlc:decide` | **Always-on.** Silently records decisions to STATE.md and flags downstream impact. Never needs to be called. |
| `/sdlc:help [command]` | System guide, or detailed help for a specific command |

### Planning (optional)
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:roadmap` | `--update` `--skip-voc` `--solo` `--simple` `--thorough` | Human session roadmap — Design/Review/Sync plan, ownership, critical path, calendar estimate. **Auto-triggers** on "how long will this take?" or "how should we plan this?" |

### Discovery
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:01-research <topic>` | `--deep` `--competitive-only` `--customer-only` | Market landscape, competitive SWOT, best practices, emerging trends |
| `/sdlc:01b-voc [topic]` | `--interviews` `--tickets` `--nps` `--guided` | Synthesize raw customer data into prioritized, evidence-backed pain points |
| `/sdlc:02-synthesize [area]` | `--codebase-only` `--research-only` | Merge research + existing codebase into a unified strategic picture |

### Specification
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:03-product-spec <feature>` | `--new-section` `--update <section>` | Requirements, BDD scenarios, business rules, NFRs, error handling |
| `/sdlc:03b-personas [name]` | `--new` `--update` `--validate` `--anti-persona` | JTBD personas, empathy maps, anti-personas |
| `/sdlc:04-customer-journey <persona>` | `--new-persona` `--update-flow` | Journey maps, failure paths, screen flows, emotional states |
| `/sdlc:04b-business-process [area]` | `--new` `--update <BP-ID>` `--inventory-only` | Back-office process maps — swimlane diagrams, RACI, SLA breakdowns, exception paths, data model flags |

### Design
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:05-data-model <domain>` | `--review` `--impact-analysis` `--new-domain` | DDD canonical data model — aggregates, ERDs, invariants, industry standards |
| `/sdlc:06-tech-arch <system>` | `--c4` `--api-spec` `--solution-design` `--patterns` | C4 architecture, clean layers, security, resilience design, ADRs |

### Front-end *(optional — when project includes a front-end)*
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:fe-setup` | `--level none\|brand\|full` `--base tamagui\|nativewind` | Configure design tokens, set up component library, derive `SCREEN_SPEC.md` from the customer journey. Run after Phase 6. |
| `/sdlc:fe-screen <screen-name-or-route>` | | Generate a screen from `SCREEN_SPEC.md`: design tokens applied, TanStack Query hooks wired to API spec, all 4 states implemented, WCAG 2.1 AA enforced, shared components extracted. Run during Phase 8 for each `[fe]` task. |

### Execution
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:07-plan <feature>` | `--breakdown` `--estimate` `--dependencies` | Layered execution plan + TODO list |
| `/sdlc:08-code <task>` | `--task <id>` `--layer <layer>` `--dry-run` | Implement tasks following strict clean architecture |
| `/sdlc:microservices <service>` | `--scaffold-only` `--k8s-only` `--ci-only` | Full production service scaffold: code + Docker + K8s + CI/CD |

### Quality
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:09-test-cases <feature>` | `--layer` `--coverage-check` `--mece-check` | 8-layer MECE test cases anchored to every source document |
| `/sdlc:10-test-automation <feature>` | `--framework` `--layer` `--update-only` | Automation scripts with TC-ID mapping, drift detection, coverage gates |
| `/sdlc:13-review [area]` | `--full` `--arch` `--data` `--test` `--obs` `--code` | 12-dimension quality audit: requirements, data, arch, tests, resilience, deployment |

### Reliability
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:11-observability <service>` | `--logging` `--tracing` `--metrics` `--config` `--audit` | OTel distributed tracing, structured logging, Prometheus RED metrics |
| `/sdlc:12-sre <service>` | `--runbook` `--slo` `--incident` `--reliability-review` | SLOs, runbooks, incident response, resilience pattern implementation |

### Brownfield
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:map` | `--refresh` `--focus <area>` | Map the existing codebase into `.sdlc/CODEBASE_MAP.md` — tech stack, architecture, domain concepts, API routes, hotspots, search recipes |
| `/sdlc:explore <question>` | | Answer codebase questions: location, callers, dependencies, conventions, change impact. **Auto-triggers** on "where is X?", "what calls X?", "how does X work?". Updates the map when new knowledge is found |

### Maintenance
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:docs` | `--audit` `--index` `--clean` `--status` | Document health audit, stale doc detection, index rebuild |

---

## What Gets Produced

Every phase outputs to a canonical document. Documents are **updated in place** — never versioned with `_v2` suffixes, never duplicated.

```
docs/
  research/
    RESEARCH.md              Market landscape, competitive intelligence, SWOT, best practices
    GAP_ANALYSIS.md          Customer pain points, unmet needs, ranked opportunities
    VOC.md                   Interview themes, ticket patterns, NPS insights — evidence-backed
    SYNTHESIS.md             Research + codebase → unified gaps, reuse opportunities, risks

  product/
    PERSONAS.md              JTBD personas, empathy maps, anti-personas
    PRODUCT_SPEC.md          REQ-IDs, BR-IDs, NFRs, BDD scenarios, error codes, acceptance criteria
    CUSTOMER_JOURNEY.md      Journey maps, failure paths, emotional states, screen flows
    BUSINESS_PROCESS.md      BP-IDs, swimlane diagrams, RACI, SLA breakdowns, exception paths, data model flags

  data/
    DATA_MODEL.md            ⚠️  Canonical: bounded contexts, aggregates, ERDs, domain events, invariants
    DATA_DICTIONARY.md       Every field: type, constraints, business meaning, standard references

  architecture/
    TECH_ARCHITECTURE.md     C4 diagrams, clean architecture layers, security, dependency classification
    API_SPEC.md              Full OpenAPI 3.x specification
    SOLUTION_DESIGN.md       Architecture Decision Records — context, decision, rationale, review trigger

  qa/
    TEST_CASES.md            MECE Given/When/Then across 8 layers with full coverage matrix
    TEST_AUTOMATION.md       TC-ID to file map, coverage gates, automation completeness audit

  frontend/                  ← only when project includes a front-end (created by /sdlc:fe-setup)
    DESIGN_TOKENS.md         Color (12-step palette + semantic), typography, spacing, radius, shadow, motion + platform config
    COMPONENT_LIBRARY.md     Component base, token mapping, available components, custom components
    SCREEN_SPEC.md           Screen inventory from customer journey — data requirements, navigation, 4 states per screen

  sre/
    OBSERVABILITY.md         Structured log spec (OBS-IDs), trace propagation, metrics catalog
    RUNBOOKS.md              Runbook per critical failure scenario
    SLO.md                   Service Level Objectives and error budgets
    INCIDENT_RESPONSE.md     Severity classification, response process, post-mortem template

  review/
    REVIEW_REPORT.md         Findings by severity across all 12 review dimensions + remediation tasks

.sdlc/
  STATE.md                   Phase progress, document index, decisions, verification log
  TODO.md                    Active task list with priority and phase
  PLAN.md                    Execution plan: phases, tasks, dependencies, risk register
  CODEBASE_MAP.md            Brownfield codebase index: tech stack, architecture, domain concepts, search recipes
  NEXT_ACTION.md             Session checkpoint: exact next action, open decisions, do-not-lose context
  ROADMAP.md                 Human session plan: phase ownership, Design/Review/Sync estimates, critical path
```

---

## Standards Encoded

This system encodes industry standards so you don't have to look them up or remember to apply them.

| Area | Standards Applied |
|------|------------------|
| Data modeling | DDD (bounded contexts, aggregates, entities, value objects), ISO 4217, ISO 8601, RFC 4122, E.164, domain-specific (ISO 20022, FHIR, GS1, etc.) |
| Architecture | Clean Architecture, Ports & Adapters, C4 Model, OpenAPI 3.x, CQRS, Saga, Outbox Pattern |
| Product | SMART NFRs, MoSCoW prioritisation (≤40% Must), JTBD (functional/emotional/social), BDD completeness, anti-personas |
| Testing | MECE, Given/When/Then (BDD), Testing Pyramid, Contract Testing (Pact), 8-layer coverage model |
| Observability | OpenTelemetry, W3C TraceContext, Prometheus/OpenMetrics, structured JSON logging, RED metrics |
| Resilience | Circuit Breaker, Retry + Full Jitter Backoff, Bulkhead, Graceful Degradation, Load Shedding, Chaos Testing |
| API design | REST conventions, versioning strategy, cursor pagination, idempotency keys, OWASP API Top 10 |
| Deployment | Multi-stage Dockerfile, non-root containers, K8s resource limits/probes/HPA/PDB, graceful shutdown |
| Frontend | Expo SDK, React Native, Expo Router v3 (cross-platform: iOS/Android/Web), Tamagui design tokens, TanStack Query v5, Zustand, WCAG 2.1 AA, Maestro E2E |
| Documentation | 50-line rule, tables over prose, ID-first formatting, complexity budgets, shard-for-partial-loading |

---

## Key Design Principles

**Data model first.** Architecture, API shapes, and code all derive from the canonical data model — not the other way around. Any change to an existing entity triggers automatic impact analysis showing exactly what breaks downstream.

**No code without a plan.** Tasks are atomic, layered (domain → application → infrastructure → delivery), and independently verifiable. The clean architecture dependency rule is enforced — domain code has zero infrastructure dependencies.

**Phase scope boundaries are explicit.** Phase 8 implements business logic and application-layer error handling — nothing more. Resilience patterns (circuit breakers, bulkheads, timeouts, graceful degradation) are Phase 12 work. Observability spec is Phase 11 work. This keeps each phase focused and prevents developers from guessing what belongs where.

**Tests from requirements, not from code.** Test cases are derived from every source document: requirements, API spec, data model invariants, architecture decisions, observability contracts. Eight test layers ensure nothing is missed. Every TC-ID traces to a source.

**Verify before you proceed.** Each phase has an independent verification step that checks completeness, internal consistency, and cross-phase references. The orchestrator warns if you skip it.

**Documents are living artifacts.** When requirements change, update `PRODUCT_SPEC.md`. When the data model evolves, update `DATA_MODEL.md` with a change history entry. IDs (REQ, BR, TC) are permanent — only deprecated, never deleted.

**Token cost is a design constraint.** Documents are structured to be partially loadable — first 50 lines orient, sections answer one question each, shards are independently readable. Claude loads what it needs, not everything. This keeps context cost flat as the project grows.

---

## License

MIT
