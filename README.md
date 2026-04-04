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

---

## How to Use

Four scenarios. One command pattern for each.

---

### 1. Start a brand-new project

```
/sdlc:00-start "I want to build a payment processing API"
```

That's it. The orchestrator reads your description, classifies intent, detects complexity tier (SIMPLE / STANDARD / CRITICAL), and walks you through the full lifecycle in order:

```
Research → Synthesize → Product Spec → Data Model → Tech Architecture
→ Plan → Code → Test Cases → Test Automation → Observability → SRE → Review
```

Phase gates are enforced automatically. No coding without a plan. No plan without a data model. You confirm the decisions that matter (tech stack, database, SLA targets); everything else runs.

---

### 2. Add a feature to an existing (brownfield) project

**Step 1 — Map the codebase (once, first time only):**
```
/sdlc:map
```
Four parallel agents read the codebase and write a persistent index. Subsequent sessions load the index instead of re-scanning.

**Step 2 — Start the iteration:**
```
/sdlc:iterate "add multi-currency support"
```

`/sdlc:iterate` determines which phases the change actually touches and runs only those — in the correct order, with impact propagation. New REQ-IDs, TC-IDs, and ADRs continue the existing sequence; they never restart. Every iteration gets a stable ID (`ITER-001`, `ITER-002`, ...) tracked in `.sdlc/ITERATIONS/`.

**To explore the codebase before starting:**
```
/sdlc:explore "where is payment processing handled?"
/sdlc:explore "what calls OrderService?"
```

---

### 3. Fix a bug

```
/sdlc:fix "order total is wrong when a discount is applied"
```

Lighter path — no spec update unless the bug reveals a design gap. The workflow:

1. **Diagnose** — root cause, which data or behavior is wrong
2. **Check data model** — does this reveal a model gap? If yes, fix model first
3. **Plan** — what exactly changes, how it will be verified
4. **Code** — implement the fix in clean architecture
5. **Regression test** — new TC-ID added, automated
6. **Verify** — did the fix introduce any new issues?

For production incidents:
```
/sdlc:fix --hotfix "payment gateway returning 500"
```

---

### 4. Keep everything aligned and in sync

**Daily rhythm:**
```
Morning:   /sdlc:sod              ← reads checkpoint, sets goal, delivers brief
During:    /sdlc:checkpoint       ← save session state mid-session (or use /loop 15m /sdlc:checkpoint)
Evening:   /sdlc:eod              ← clean stop, commit WIP, write tomorrow's first action
```

**Check current status at any time:**
```
/sdlc:status                      ← phases complete, active work, todos, next action
/sdlc:00-start                    ← same, with routing to recommended next command
```

**Verify a phase is complete before moving on:**
```
/sdlc:verify                      ← verifies last completed phase
/sdlc:verify --phase 5            ← verify a specific phase
```

**After a data model or spec change — check what's now stale:**
```
/sdlc:docs                        ← audit doc health, find stale docs, missing sections
/sdlc:13-review                   ← cross-cutting quality audit: requirements traceability,
                                     data model integrity, test coverage, architecture compliance
```

**Resume after a break or `/clear`:**
```
/sdlc:resume                      ← reads NEXT_ACTION.md, delivers a structured brief,
                                     picks up exactly where you left off
```

**Ship completed work:**
```
/sdlc:release                     ← groups ITER-NNN + FIX-NNN into a versioned release,
                                     generates CHANGELOG.md, recommends git tag
```

---

## What You Get

### Phases that execute, not phases you navigate

Default behavior: each **checkpoint phase** (product spec, data model, architecture, test strategy, deploy) pauses for developer review before the next begins. After confirming, auto-chain skills run silently — then a combined review presents everything at once.

```bash
/sdlc:start "add loyalty points"              # interactive (default)
/sdlc:start "add loyalty points" --auto       # fully autonomous, no pauses
/sdlc:start "add loyalty points" --lightweight # skip data-model / arch phases
/sdlc:start --emergency "payment gateway down" # incident mode: plan → code → verify → deploy → retro
```

### Intent-driven routing — only the phases that matter

The orchestrator classifies your input into one of five intents, then runs only the phases that apply. No forcing yourself through research and synthesis when you're fixing a bug.

| Intent | Entry point | Phase path |
|--------|------------|-----------|
| `new-project` | Research | Full 20-phase lifecycle |
| `new-feature` | Product spec | idea → data-model → design → plan → code → test-cases → test-gen → verify → deploy |
| `bug-fix` | Plan | plan → code → test-cases → verify → deploy |
| `refactor` | Synthesize | synthesize → data-model check → plan → code → test-cases → verify |
| `documentation` | Product spec | idea only |

Supply the intent explicitly or let the orchestrator classify from your description:

```bash
/sdlc:start --intent bug-fix "order total wrong when discount applied"
/sdlc:start --intent new-feature "add multi-currency support"
```

### Auto-chain execution — compound phases without compound commands

After each checkpoint phase completes, related skills run automatically. You confirm the checkpoint; everything else happens behind it.

After **design**: threat modeling, ADR validation, and infrastructure design run in sequence.
After **code**: security scan, dependency audit, test gap analysis, and PII audit run in sequence.
After **deploy**: release notes and maintenance plan run in sequence.

All auto-chain results appear in a single combined review pause per checkpoint:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[DESIGN] complete. Artifact: artifacts/tech-arch/tech-architecture.md
Three-tier clean architecture with PostgreSQL datastore.

Auto-chained:
  ✅ threat-model — 2 HIGH findings (auth bypass, SQL injection) [artifacts/threat-model/]
  ✅ adr-gen — 4 ADRs validated, 1 missing rationale [artifacts/tech-arch/solution-design.md]
  ✅ infra-design — Dockerfile + Helm chart scaffolded [artifacts/infra-design/]

Quality gate for PLAN: PASS

→ "continue"    — proceed to plan
→ "new session" — save checkpoint here
→ "deep review" — run full traceability analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Branch-scoped workspaces

Every git branch has its own isolated workspace. State, progress, and artifacts are stored at `.claude/ai-sdlc/workflows/<branch>/` — sanitized from the branch name. Switching branches switches full context. History of previous runs is archived to `.claude/ai-sdlc/history/`.

```
.claude/ai-sdlc/
  workflows/
    feature--payments/       ← feature/payments branch
      state.json             ← phase status, decisions, gate overrides
      progress.json          ← task tracking
      artifacts/             ← all phase outputs
    main/                    ← main branch workspace
  history/                   ← archived past runs
  codebase/                  ← codebase map (shared across branches)
  CLAUDE.md                  ← framework reference
```

### Stale cascade — know exactly what needs revisiting

When you re-run a phase, the system automatically marks all downstream phases as stale. The artifact still exists and is readable — but the dashboard flags it, and the next phase's gate warns before proceeding.

```
✅ data-model   — completed 2026-03-25
⚠️ tech-arch    — stale (data-model re-run)
⚠️ plan         — stale (data-model re-run)
⏳ code         — pending
```

When you hit a stale phase: `"refresh"` (regenerate), `"continue as-is"` (accept staleness), or `"view"` (inspect before deciding).

### Requirements that actually drive the work
Every requirement gets a `REQ-ID`. Every business rule gets a `BR-ID`. Every NFR gets a **numeric threshold** — not "fast" but "p95 < 200ms at 1000 RPS". These IDs flow all the way through to test cases and automation. When a requirement changes, you know exactly what breaks.

### A data model that's the single source of truth
The canonical data model is designed before architecture and code. Everything derives from it — API shapes, domain entities, test factories, database migrations. Change a field in the data model and automatic impact analysis tells you exactly what breaks downstream before you touch a line of code.

### Operational processes mapped before the data model locks in

For projects with back-office operations, `/sdlc:business-process` maps every operational process between customer journeys and the data model — not after the fact, when changing the model is expensive.

Every process gets a **BP-ID** and is documented with: a Mermaid swimlane sequence diagram showing actor interactions and branching; a **RACI table** per step; **SLA breakdowns** with breach actions; and full **exception paths** (what fails, who is notified, how recovery works).

The key output is `## Data Model Implications Summary` — a consolidated table of every new entity, state machine field, and relationship the processes require. Phase 5 reads this table before modelling begins, so entities like `ApprovalRecord`, `EscalationLog`, and `JobExecution` are designed in rather than bolted on. Process-driven fields like `status`, `assigned_to`, and `sla_deadline` are first-class model citizens, not afterthoughts.

### Clean architecture that stays clean
Code is implemented in strict layer order: domain → application → infrastructure → delivery. The dependency rule (no infrastructure imports in domain or application layers) is enforced. Every external integration goes through a port interface. No God objects, no magic numbers, no spaghetti.

### Cross-platform screens generated from journey maps

When a project includes a front-end, one command turns the customer journey into a complete screen specification:

```bash
/sdlc:fe-setup         # after Phase 6 — configures tokens, derives screen spec
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

The `[fe]` task tag in `implementation-plan.md` is the discriminator — Phase 8 detects it and switches to the FE workflow automatically.

### Tests anchored to requirements, not vibes
Test cases are derived from every source: requirements, API spec, data model invariants, architecture decisions, observability commitments. Nine test layers — unit, integration, contract, E2E, performance, scalability, resilience, observability, security, plus smoke/synthetic monitoring — all with TC-IDs that trace back to a source document. NFR-IDs trace forward through ADRs to TC-IDs to SLOs, closing the full traceability chain. No orphaned tests. No uncovered requirements. Coverage gates fail the CI build.

Test gen (Phase 10) is a separate checkpoint from test cases (Phase 9) — the developer confirms the test strategy before automation code is generated.

### Resilience built in, not bolted on
Every external dependency is classified (CRITICAL / DEGRADABLE / OPTIONAL) with explicit timeouts, circuit breakers, fallbacks, and retry logic. The system checks that your CRITICAL dependencies have circuit breakers, your DEGRADABLE dependencies have fallbacks, and every client has explicit connect and read timeouts. Chaos tests verify it all actually works.

### Observability as a first-class deliverable
Structured JSON logging with mandatory `trace_id` and `span_id` fields. OpenTelemetry distributed tracing with W3C context propagation. Prometheus RED metrics at every service boundary. Health endpoints (`/health/live`, `/health/ready`, `/health/startup`) that actually check dependencies. All committed to `observability.md` with `OBS-IDs` that test cases verify.

### Production-ready microservice scaffolding in one command
```bash
/sdlc:scaffold "payment-service"
```
Generates: clean architecture skeleton, multi-stage Dockerfile (non-root user, layer caching), docker-compose local dev stack, Kubernetes manifests (Deployment, Service, ConfigMap, HPA, PDB), Kustomize overlays for staging/production, GitHub Actions CI/CD pipeline with Trivy CVE scanning, graceful shutdown handler, all three health probes.

### A planning construct built for agentic development

Story points measure coding effort. In agentic development, coding is largely automated — the scarce resource is **human judgment and attention**. AI-SDLC uses a different planning unit: the **Human Session**.

```bash
/sdlc:roadmap   # generates artifacts/roadmap/roadmap.md
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

Every architectural and product decision made in conversation is silently recorded to `state.json` by the always-on `/sdlc:decide` skill. No command to run. No reminder needed. The moment you say "we'll use Postgres", "JWT not sessions", or "dropping bulk import from v1" — it's written down with the reason and a flag for any downstream documents that may now be stale.

### Documents structured for both human and AI reading

Every document produced by AI-SDLC follows a strict writing standard that serves two goals simultaneously: readable by a human in under 5 minutes, and answerable by Claude using the minimum possible tokens.

The **50-line rule**: every document's first 50 lines contain a TL;DR and a contents index — so Claude can orient and jump to the relevant section without loading the whole file. **Tables over prose**: structured data (requirements, fields, decisions, error codes) always in tables at ~40% fewer tokens. **IDs at line start**: every REQ-ID, BR-ID, TC-ID, ADR-ID begins its line so any reference is a single grep away. **Complexity budgets**: hard limits per document type that trigger sharding before a file becomes a monolith Claude loads in full every time.

The result: as your project grows to dozens of documents, token cost stays flat because Claude loads what it needs — not everything.

### An independent quality gate between every phase
```bash
/sdlc:verify              # auto-runs after every phase
/sdlc:verify --phase 5    # explicitly check phase 5
/sdlc:verify --all        # full audit across all phases
```
Verification goes beyond "does the file exist?" — it checks completeness (no placeholders, all required sections), internal consistency (every entity has timestamps and invariants), and cross-phase consistency (every NFR in the spec has an architectural decision that addresses it, every API endpoint has a contract test).

Eleven gates enforce specific structural requirements before each phase transition. The most critical: the DATA-MODEL gate blocks both tech-arch and test-cases — no exceptions.

### Brownfield codebase understanding without heavy tooling

AI-SDLC uses a persistent, version-controlled index that lives right in the repo:

```bash
/sdlc:map      # spawns 4 parallel read-only agents → writes codebase/ documents
/sdlc:gaps     # spawns 3 gap analysis agents: tech debt, arch drift, quality coverage
```

Four specialised read-only agents run in parallel: architecture mapper (layer structure, components, data flow), tech stack mapper (dependencies, toolchain), conventions mapper (naming, file organisation, patterns), and cross-cutting concerns mapper (auth, logging, error handling, caching).

```bash
/sdlc:explore "where is payment processing handled?"
/sdlc:explore "what calls OrderService?"
/sdlc:explore "if I change the user_id field, what breaks?"
/sdlc:explore "show me all API endpoints"
```

The map is consumed automatically by `/sdlc:synthesize` (no re-scanning the whole codebase) and by the orchestrator on startup (context-aware routing from the first command). When `/sdlc:explore` discovers something the map missed, it updates the map — so it gets better over time.

### Iterative development — keep adding features without starting over

The initial lifecycle gets you to a production-ready v1. Everything after that flows through the **iteration model**:

```bash
/sdlc:iterate "add multi-currency support"
/sdlc:iterate "loyalty points module"
/sdlc:iterate --type enhancement "improve checkout performance"
/sdlc:iterate --voc  # customer feedback triggered a spec change
```

Each iteration is a **scoped mini-lifecycle**. Instead of re-running all phases, `/sdlc:iterate` determines which phases are actually affected by the change and executes only those — in the correct order, with impact propagation between them.

Every iteration gets a stable ID (`ITER-001`, `ITER-002`, ...) and a scope manifest that tracks:
- Which phases are in scope and their status
- Which sections of each document were changed
- Every new ID introduced (REQ, BR, TC, ADR, NFR) — continuing the existing sequence, never restarting
- Breaking changes (require explicit confirmation before proceeding)
- Propagation flags (e.g. "new NFR added → Phase 6 needs ADR, Phase 11 needs SLO")

**Iteration types** cover every kind of change:

| Type | Command | Phases touched |
|------|---------|---------------|
| New feature/module | `/sdlc:iterate "feature name"` | 3 → 5 → 6 → 7 → 8 → 9 → 10 |
| Extend existing feature | `/sdlc:iterate --type enhancement "..."` | 3 → 5? → 6? → 7 → 8 → 9 → 10 |
| New NFR/SLA target | `/sdlc:iterate --type nfr "..."` | 3 → 6 → 9 → 11 → 12 |
| Schema-only change | `/sdlc:iterate --type data "..."` | 5 → 6 → 7 → 8 → 9 → 10 |
| UX/journey update | `/sdlc:iterate --type ux "..."` | 4 → 6b? → 7 → 8 → 9 → 10 |
| Customer feedback gap | `/sdlc:iterate --voc` | 1b → 3 → then per impact |

**Upstream documents stay continuously fresh** — VOC, research, and personas can be updated standalone at any time. When they surface a product gap, they recommend an iteration. When they confirm existing requirements, no iteration is needed.

The orchestrator (`/sdlc:start`) is iteration-aware: it surfaces any active in-progress iteration at startup and recommends `/sdlc:iterate` rather than re-running phases when an established project is detected.

### Context management that actually works across sessions
One of the hardest problems with AI-assisted development is losing context — mid-session when Claude auto-compacts, or the next morning when you start fresh. AI-SDLC solves this with a structured daily loop:

**End of day — `/sdlc:eod`**
Reaches a clean stopping point, commits work in progress with a descriptive message, saves a precise snapshot of where you are (phase, step, open decisions, anything said verbally that isn't in the docs), and tells you exactly what to run first tomorrow.

**During the day — `/loop 15m /sdlc:checkpoint`**
Auto-saves your session state every 15 minutes. If context fills and Claude auto-compacts, nothing is lost. `/clear` followed by `/sdlc:restore` restores full context in under a minute.

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

Phases are organized in six tiers. `◉` = checkpoint phase (pauses for developer review). ⚠️ = hard gate.

### Tier 0 — ASSESS *(optional)*
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 0 | **Feasibility** `◉` | `/sdlc:feasibility` | Go/No-Go viability: market size, technical risk, competitive moat, build vs buy | `feasibility/feasibility.md` |

### Tier 1 — DISCOVER
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 1 | **Research** | `/sdlc:research` | Market landscape, competitive SWOT, best practices, emerging trends | `research/research.md`, `gap-analysis.md` |
| 1b | **Voice of Customer** *(optional)* | `/sdlc:voc` | Synthesize interviews, support tickets, NPS data into prioritized, evidence-backed pain points | `voc/voc.md` |
| 2 | **Synthesize** | `/sdlc:synthesize` | Merge research + codebase analysis into unified strategic direction | `synthesize/synthesis.md` |

### Tier 2 — DEFINE
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 3 | **Product Spec** `◉` | `/sdlc:idea` | REQ-IDs, BR-IDs, numeric NFR-IDs, acceptance criteria, BDD scenarios, error handling table | `idea/prd.md` |
| 3b | **Personas** *(optional)* | `/sdlc:personas` | JTBD personas, empathy maps, anti-personas | `personas/personas.md` |
| 4 | **Customer Journey** *(optional)* | `/sdlc:journey` | Journey maps, failure paths, emotional states, screen flows | `journey/customer-journey.md` |
| 4b | **Business Process** *(optional)* | `/sdlc:business-process` | Back-office process maps — swimlanes, RACI, SLAs, exception paths. Flags new entities and state machines for Phase 5. | `business-process/business-process.md` |
| 4c | **Prototype** `◉` *(optional)* | `/sdlc:prototype` | Low-fidelity UX flows — validates interaction model before the data model locks in | `prototype/prototype-spec.md` |

### Tier 3 — BUILD
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 5 | **Data Model** `◉` ⚠️ | `/sdlc:data-model` | Canonical DDD model — bounded contexts, aggregates, ERDs, invariants, data dictionary. Hard gate for tech-arch, plan, and test-cases. | `data-model/data-model.md`, `data-dictionary.md` |
| 6 | **Tech Architecture** `◉` | `/sdlc:design` | C4 diagrams, clean architecture layers, LLD, API spec, ADRs, security design, resilience strategy. Auto-chains: threat-model, adr-gen, infra-design. | `tech-arch/tech-architecture.md`, `lld.md`, `api-spec.md`, `solution-design.md` |
| 6b | **FE Setup** *(optional)* | `/sdlc:fe-setup` | Design tokens (3 levels), component library, derive screen spec from customer journey. Run after Phase 6 when project has a front-end. | `fe-setup/design-tokens.md`, `screen-spec.md` |
| 7 | **Plan** `◉` ⚠️ | `/sdlc:plan` | Atomic tasks ordered by clean architecture layer: domain → application → infrastructure → delivery. Auto-chains: observability, sre, roadmap. | `plan/implementation-plan.md` |
| 8 | **Code** `◉` | `/sdlc:build` | Execute implementation tasks against plan. Auto-chains: test-gaps, security, audit-deps, pii-audit. | Source files |

### Tier 4 — VERIFY
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 9 | **Test Cases** `◉` ⚠️ | `/sdlc:test-cases` | MECE Given/When/Then across 9 layers + Smoke/Synthetic, anchored to every source document. **Runs twice:** after Phase 8 (7 layers); re-run after Phase 12 adds Observability + Resilience. Auto-chains: traceability. | `test-cases/test-cases.md` |
| 10 | **Test Generation** `◉` | `/sdlc:test-gen` | Generate automation scripts from test cases — 1:1 TC-ID mapping, coverage gate enforcement, drift detection. Developer confirms test strategy before code is generated. | `test-gen/test-automation.md`, test files |
| 11 | **Observability** | `/sdlc:observability` | Structured logging spec, OTel tracing, Prometheus RED metrics — OBS-IDs committed before SRE phase | `observability/observability.md` |
| 12 | **SRE** | `/sdlc:sre` | SLOs, runbooks per critical failure scenario, incident response, resilience pattern verification | `sre/runbooks.md` |
| 13 | **Verify** `◉` | `/sdlc:verify` | Cross-cutting quality audit — 0 open CRITICAL findings required to proceed to deploy | `verify/verification-report.md` |
| 13b | **UAT** `◉` *(optional)* | `/sdlc:uat` | Stakeholder acceptance testing plan — UAT-NNN scenarios, entry/exit criteria, sign-off record | `uat/uat-plan.md` |

### Tier 5 — SHIP
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 14 | **Deploy** `◉` | `/sdlc:deploy` | Deployment checklist, rollback plan, handoff. CI/CD gate: pipeline must be verified before release. Auto-chains: release-notes, maintain. | `deploy/deployment-checklist.md` |

### Tier 6 — SUSTAIN *(optional)*
| # | Phase | Command | What it does | Artifact |
|---|-------|---------|-------------|---------|
| 15 | **Maintain** | `/sdlc:maintain` | Tech debt registry, maintenance planning, scheduled operations | `maintain/maintenance-plan.md` |
| 16 | **Retro** `◉` | `/sdlc:retro` | Project retrospective — timeline, contributing factors, action items with owners | `retro/retro.md` |

---

## Phase Gates

All 11 gates are hard-enforced. Bypass with `--force` (reason required, logged to `state.json`).

| Gate | Upstream requires | Blocks | Key structural checks |
|------|-----------------|--------|----------------------|
| `research→synthesize` | `research.md` with ≥2 named competitors + `gap-analysis.md` | synthesize | Market Landscape section, ≥1 gap |
| `synthesize→idea` | `synthesis.md` with synthesis language | idea | No `{{placeholder}}` or `[TBD]` |
| `idea→data-model` ⚠️ | `prd.md` with ≥3 REQ-IDs + ≥3 acceptance criteria + out-of-scope section | data-model, test-cases | No placeholders |
| `data-model→tech-arch` ⚠️ | `data-model.md` with ≥1 bounded context + Mermaid ERD + `data-dictionary.md` for every entity | tech-arch | id/created_at/updated_at on every entity |
| `data-model→test-cases` ⚠️ | `data-model.md` + `data-dictionary.md` + ≥1 entity with invariants | test-cases | — |
| `tech-arch→plan` | `tech-architecture.md` + `lld.md` + `api-spec.md` + `solution-design.md` with ≥1 ADR | plan | No placeholders |
| `plan→code` ⚠️ | `implementation-plan.md` with ≥3 tasks + file changes + DoD + explicit approval | code | — |
| `code→verify` | ≥1 source file modified + ≥1 task done in `progress.json` | verify | — |
| `test-cases→test-gen` ⚠️ | `test-cases.md` with ≥3 TC-IDs + coverage matrix + no duplicate IDs | test-gen | Pyramid shape check, AC-to-TC audit, NFR coverage |
| `observability→sre` | `observability.md` with logging spec + `trace_id`/`span_id` mandatory + RED metrics | sre | — |
| `verify→deploy` | `verification-report.md` with 0 open CRITICAL findings | deploy | — |

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

Open any project in Claude Code and run `/sdlc:start "your idea"` to start a new project, or `/sdlc:start` (no args) to see the status of an existing one.

On first run, the system automatically:
1. Detects your git branch and creates a branch-scoped workspace at `.claude/ai-sdlc/workflows/<branch>/`
2. Creates `.claude/ai-sdlc/CLAUDE.md` (framework reference)
3. Asks 5 setup questions → generates `.claude/ai-sdlc.config.yaml`
4. Offers to add `.gitignore` entries

### Configure

Edit `.claude/ai-sdlc.config.yaml`. Critical fields:

```yaml
version: 2.0.0
projectName: "my-service"      # required
techStack:
  language: typescript         # required
  framework: nestjs
  database: postgresql
  testFramework: jest
  containerRuntime: Docker      # drives deployment checklist
  orchestrator: Kubernetes
quality:
  coverage:
    overall: 80
    businessLogic: 90
```

### What to commit vs exclude

```gitignore
# Per-developer runtime state — do NOT commit
.claude/ai-sdlc/workflows/*/state.json
.claude/ai-sdlc/workflows/*/progress.json
.claude/ai-sdlc/history/

# Commit these (team-shared artifacts)
# .claude/ai-sdlc/CLAUDE.md
# .claude/ai-sdlc.config.yaml
# .claude/ai-sdlc/workflows/*/artifacts/
# .claude/ai-sdlc/codebase/
```

---

## Commands

These are the commands you need to know. Everything else runs internally.

### The main interface

| Command | What it does |
|---------|-------------|
| `/sdlc:start [idea]` | **Universal entry point.** New project, status check, daily brief, resume — handles everything. Also accepts natural language: `morning`, `done`, `save`, `roadmap`, `verify`, `help`. |
| `/sdlc:iterate <feature>` | **Add or evolve features.** Scoped mini-lifecycle — updates only the docs and phases the change actually touches. |
| `/sdlc:fix <what's broken>` | **Fix things.** Bug fixes (default), hotfixes (`--hotfix` for production incidents), maintenance (`--maintenance` for debt/upgrades). Lighter path — no spec update unless a design gap is discovered. |
| `/sdlc:release [version]` | **Ship work.** Groups completed ITER-NNN + FIX-NNN into a versioned release. Generates CHANGELOG.md entry, release summary, git tag recommendation. |
| `/sdlc:review [area]` | **Quality audit.** 12-dimension cross-cutting review: requirements, data, arch, tests, resilience, deployment, security. |

### Codebase navigation

| Command | What it does |
|---------|-------------|
| `/sdlc:explore <question>` | Answer codebase questions: "where is X?", "what calls Y?", "how are errors handled?". **Auto-triggers** on location/caller/convention questions. |
| `/sdlc:map` | Brownfield setup — 4 parallel read-only agents map architecture, tech stack, conventions, and cross-cutting concerns into `.claude/ai-sdlc/codebase/`. Run once on an existing project before anything else. |
| `/sdlc:gaps` | 3 gap analysis agents — tech debt prioritization, architecture drift, quality/coverage gaps. Run after `/sdlc:map`. |

---

### Daily workflow cheatsheet

```
Morning:    /sdlc:start morning
Afternoon:  /sdlc:iterate "add loyalty points"   ← new feature
            /sdlc:fix "cart total wrong"          ← bug
Evening:    /sdlc:start done                     ← saves checkpoint, commits WIP

Ready to ship:  /sdlc:release --minor
Quality check:  /sdlc:review

Production fire:  /sdlc:fix --hotfix "payment gateway down"
```

---

### Advanced / direct phase access

The commands below are invoked automatically by the workflows above. You don't need to call them directly — but they're available if you need to jump to a specific phase.

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
- `/sdlc:data-model <domain>` — DDD canonical data model, ERDs, invariants, data dictionary
- `/sdlc:design <system>` — C4 architecture, LLD, API spec, ADRs, resilience design
- `/sdlc:compare` — generate 2-3 design alternatives → decision in ADR format
- `/sdlc:nfr-analysis` — decompose NFRs into architectural implications *(auto-chain after idea)*
- `/sdlc:threat-model` — STRIDE threat modeling per component and trust boundary *(auto-chain after design)*
- `/sdlc:adr-gen` — validate ADR completeness and traceability *(auto-chain after design)*
- `/sdlc:infra-design` — IaC scaffold (Dockerfile, Helm, Terraform) from architecture *(auto-chain after design)*

**Front-end** *(when project includes a front-end)*
- `/sdlc:fe-setup` — design tokens, component library, derive screen spec from customer journey
- `/sdlc:fe-screen <screen>` — generate a screen from screen spec

**Execution**
- `/sdlc:plan <feature>` — layered execution plan + task list
- `/sdlc:build <task>` — implement tasks following clean architecture
- `/sdlc:scaffold <service>` — production service scaffold (clean arch skeleton, Docker, K8s, CI/CD)
- `/sdlc:dep-design` — dependency vetting before code

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

**Session / admin** *(handled by `/sdlc:start` but also directly invokable)*
- `/sdlc:sod` / `/sdlc:eod` / `/sdlc:checkpoint` / `/sdlc:restore` — daily session management
- `/sdlc:verify [--phase N]` — quality gate for a completed phase
- `/sdlc:status` — live dashboard: phases, gates, implementation progress, stale flags
- `/sdlc:progress` — implementation task checklist with native task panel integration
- `/sdlc:roadmap` — human-effort planning (Design/Review/Sync sessions)
- `/sdlc:squad` — team dashboard: all active branch workflows across the project
- `/sdlc:debt` — list and export technical debt register (TD-IDs)
- `/sdlc:decide` — always-on decision capture (silently records to `state.json`)

</details>

---

## What Gets Produced

Every phase outputs to a canonical artifact in the branch-scoped workspace. Artifacts are **updated in place** — never versioned with `_v2` suffixes, never duplicated.

Every artifact starts with a header on line 1:
```
<!-- ai-sdlc | phase: data-model | branch: feature--payments | generated: 2026-03-28T14:32:00Z | version: 2.0.0 -->
```

```
.claude/ai-sdlc/
  CLAUDE.md                        Framework reference           ← commit
  ai-sdlc.config.yaml              Project configuration         ← commit
  codebase/                        Brownfield map (shared)       ← commit
    architecture.md
    tech-stack.md
    conventions.md
    concerns.md

  workflows/
    <branch>/                      Branch-scoped workspace
      state.json                   Phase status, decisions, gate log   ← DO NOT COMMIT
      progress.json                Implementation task tracking        ← DO NOT COMMIT
      artifacts/                                                        ← commit
        feasibility/               feasibility.md
        research/                  research.md, gap-analysis.md
        voc/                       voc.md
        synthesize/                synthesis.md
        idea/                      prd.md
        personas/                  personas.md
        journey/                   customer-journey.md
        business-process/          business-process.md
        prototype/                 prototype-spec.md
        data-model/                data-model.md, data-dictionary.md    ⚠️
        tech-arch/                 tech-architecture.md, lld.md, api-spec.md, solution-design.md
        threat-model/              threat-model.md
        infra-design/              Dockerfile, helm/, terraform/
        fe-setup/                  design-tokens.md, component-library.md, screen-spec.md
        plan/                      implementation-plan.md
        test-cases/                test-cases.md
        test-gen/                  test-automation.md, test files
        observability/             observability.md
        sre/                       runbooks.md
        verify/                    verification-report.md
        uat/                       uat-plan.md
        deploy/                    deployment-checklist.md
        maintain/                  maintenance-plan.md
        retro/                     retro.md

  history/                         Archived past runs             ← DO NOT COMMIT
    20260328-1430-new-feature-feature--payments/
      state.json
      artifacts/

  ITERATIONS/
    ITER-001.md                    Iteration manifest: scope, phase map, ID continuity
    ITER-002.md
```

---

## ID System

All IDs follow `PREFIX-NNN` (zero-padded to 3 digits minimum). IDs are permanent — deprecated, never deleted.

| Prefix | Meaning | Assigned in | Flows to |
|--------|---------|------------|---------|
| `REQ-NNN` | Functional Requirement | Product spec | Test cases, tasks, acceptance criteria |
| `BR-NNN` | Business Rule | Product spec | Test cases, data model invariants |
| `NFR-NNN` | Non-Functional Requirement (numeric threshold) | Product spec / Clarify | ADRs, test cases, SLOs |
| `ADR-NNN` | Architecture Decision Record | Tech architecture | Review triggers |
| `TC-NNN` | Test Case (tagged by layer) | Test cases | Automation scripts |
| `OBS-NNN` | Observability commitment | Observability | Test cases, SRE runbooks |
| `UAT-NNN` | Stakeholder acceptance scenario | UAT | Deploy gate |
| `TD-NNN` | Technical Debt item | Code phase | Debt register |
| `DEC-NNN` | Decision record | Any phase | `state.json` |

---

## Standards Encoded

This system encodes industry standards so you don't have to look them up or remember to apply them.

| Area | Standards Applied |
|------|------------------|
| Data modeling | DDD (bounded contexts, aggregates, entities, value objects), ISO 4217, ISO 8601, RFC 4122, E.164, domain-specific (ISO 20022, FHIR, GS1, etc.) |
| Architecture | Clean Architecture, Ports & Adapters, C4 Model, OpenAPI 3.x, CQRS, Saga, Outbox Pattern, Event Sourcing, Multi-tenancy patterns (RLS/schema/silo) |
| Product | SMART NFRs, MoSCoW prioritisation (≤40% Must), JTBD (functional/emotional/social), BDD completeness, anti-personas |
| Testing | MECE, Given/When/Then (BDD), Testing Pyramid, Consumer-Driven Contract Testing (Pact), Property-Based Testing, 9-layer coverage model (Unit, Integration, Contract, E2E, Performance, Scalability, Resilience, Observability, Security) + Smoke/Synthetic |
| Observability | OpenTelemetry, W3C TraceContext, Prometheus/OpenMetrics, structured JSON logging, RED metrics, Audit logging (compliance trail), NFR→SLO reconciliation |
| Resilience | Circuit Breaker (NFR-derived thresholds), Retry + Full Jitter Backoff, Bulkhead, Graceful Degradation, Load Shedding, Idempotency Keys, Chaos Testing |
| API design | REST conventions, URI versioning, RFC 8594 Sunset headers, RFC 9745 Deprecation headers, cursor pagination, idempotency keys, OWASP API Top 10 |
| Deployment | Multi-stage Dockerfile, non-root containers, K8s resource limits/probes/HPA/PDB, graceful shutdown, Blue-Green/Canary/Feature-flag strategies, Argo Rollouts |
| Security | STRIDE threat modeling, secret rotation lifecycle (dual-credential pattern), dependency vulnerability scanning (SBOM/Trivy), zero-downtime credential rotation |
| Data operations | Zero-downtime migration patterns (expand/contract, dual-write, CONCURRENTLY), database indexing strategy (B-tree/partial/covering), caching strategy (cache-aside/write-through/invalidation/stampede prevention) |
| Developer experience | Conventional Commits, Keep a Changelog, contribution guidelines, PR review SLA, background job patterns (outbox, DLQ, effectively-once), testID naming convention for E2E |
| Frontend | Expo SDK, React Native, Expo Router v3 (cross-platform: iOS/Android/Web), Tamagui design tokens, TanStack Query v5, Zustand, WCAG 2.1 AA, Maestro E2E, testID manifest |
| Documentation | 50-line rule, tables over prose, ID-first formatting, complexity budgets, shard-for-partial-loading |

---

## Key Design Principles

**Data model first.** Architecture, API shapes, and code all derive from the canonical data model — not the other way around. Any change to an existing entity triggers automatic impact analysis showing exactly what breaks downstream.

**No code without a plan.** Tasks are atomic, layered (domain → application → infrastructure → delivery), and independently verifiable. The clean architecture dependency rule is enforced — domain code has zero infrastructure dependencies.

**Phase scope boundaries are explicit.** Phase 8 implements business logic and application-layer error handling — nothing more. Resilience patterns (circuit breakers, bulkheads, timeouts, graceful degradation) are Phase 12 work. Observability spec is Phase 11 work. This keeps each phase focused and prevents developers from guessing what belongs where.

**Tests from requirements, not from code.** Test cases are derived from every source document: requirements, API spec, data model invariants, architecture decisions, observability contracts. Nine test layers ensure nothing is missed. Every TC-ID traces to a source.

**Verify before you proceed.** Each phase has an independent verification step that checks completeness, internal consistency, and cross-phase references. The orchestrator warns if you skip it.

**Documents are living artifacts.** When requirements change, update `prd.md`. When the data model evolves, update `data-model.md` with a change history entry. IDs (REQ, BR, TC) are permanent — only deprecated, never deleted.

**Token cost is a design constraint.** Documents are structured to be partially loadable — first 50 lines orient, sections answer one question each, shards are independently readable. Claude loads what it needs, not everything. This keeps context cost flat as the project grows.

---

## License

MIT
