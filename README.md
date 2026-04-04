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

Each **checkpoint phase** (product spec, data model, architecture, plan, deploy) pauses for your review before proceeding. After confirming, the next phase begins. A combined review presents all outputs before you move on.

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

Every iteration gets a stable ID (`ITER-001`, `ITER-002`, ...) tracked in `.sdlc/ITERATIONS/`. The scope manifest records which phases ran, which document sections changed, and every new ID introduced.

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

Lighter path — no spec update unless the bug reveals a design gap. The workflow:

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

Use this when you need to upgrade dependencies, replace deprecated patterns, improve performance, or bring old code in line with current standards — without changing behaviour.

**Step 1 — Understand what you're working with:**
```
/sdlc:map          # build codebase index (if not done)
/sdlc:gaps         # surface tech debt, architecture drift, quality gaps
```

**Step 2 — Run the modernisation as a typed iteration:**
```
/sdlc:iterate --type nfr "upgrade to Node 22 and address security advisories"
/sdlc:iterate --type nfr "migrate from REST polling to WebSockets"
/sdlc:iterate --type data "normalise the legacy orders schema"
```

Iteration types for modernisation:

| Type flag | Use when |
|-----------|----------|
| `--type nfr` | New SLA target, performance requirement, or security baseline |
| `--type data` | Schema change, migration, data normalisation |
| `--type enhancement` | Extend or improve an existing feature |

The iteration model ensures every change — even "just an upgrade" — has a plan, passes tests, and doesn't silently break downstream dependencies.

**For targeted debt work:**
```
/sdlc:maintain     # tech debt registry, maintenance planning, scheduled operations
```

---

### 5. Refactor

Use this when code structure needs to change but observable behaviour must stay the same.

**Step 1 — Map and analyse:**
```
/sdlc:map          # if not already done
/sdlc:gaps         # identify architecture drift and quality gaps
```

**Step 2 — Synthesise findings:**
```
/sdlc:synthesize   # merge codebase analysis into a strategic direction
```

**Step 3 — Run the refactor as an iteration:**
```
/sdlc:iterate --type enhancement "extract payment domain into bounded context"
/sdlc:iterate --type enhancement "move infrastructure dependencies behind port interfaces"
```

Refactors always go through the plan phase — tasks are atomic, ordered by clean architecture layer (domain → application → infrastructure → delivery), and independently verifiable. The dependency rule (no infrastructure imports in domain or application) is enforced throughout.

**After a large refactor, verify nothing broke:**
```
/sdlc:review       # 12-dimension cross-cutting audit
/sdlc:verify       # quality gate: 0 open CRITICAL findings required
```

---

### Daily rhythm

```
Morning:   /sdlc:sod              ← reads checkpoint, sets goal, delivers brief
During:    /sdlc:checkpoint       ← save session state mid-session (or /loop 15m /sdlc:checkpoint)
Evening:   /sdlc:eod              ← clean stop, commit WIP, write tomorrow's first action
```

**Check current status at any time:**
```
/sdlc:status                      ← phases complete, active work, todos, next action
/sdlc:00-start                    ← same, with routing to recommended next command
```

**Verify a phase before moving on:**
```
/sdlc:verify                      ← verify last completed phase
/sdlc:verify --phase 5            ← verify a specific phase
```

**After a data model or spec change — check what's now stale:**
```
/sdlc:docs                        ← audit doc health, find stale docs, missing sections
/sdlc:13-review                   ← cross-cutting quality audit
```

**Resume after a break or `/clear`:**
```
/sdlc:resume                      ← reads NEXT_ACTION.md, picks up exactly where you left off
```

**Ship completed work:**
```
/sdlc:release                     ← groups ITER-NNN + FIX-NNN into a versioned release,
                                     generates CHANGELOG.md, recommends git tag
```

---

## What You Get

### Intent-driven routing — only the phases that matter

The orchestrator classifies your input and runs only the phases that apply.

| Intent | Entry point | Phase path |
|--------|------------|-----------|
| `new-project` | Research | Full lifecycle |
| `new-feature` | Product spec | idea → data-model → design → plan → code → test-cases → test-gen → verify → deploy |
| `bug-fix` | Plan | plan → code → test-cases → verify → deploy |
| `refactor` | Synthesize | synthesize → data-model check → plan → code → test-cases → verify |
| `modernise` | Synthesize / Plan | gaps → synthesize → plan → code → test-cases → verify |

Supply the intent explicitly or let the orchestrator classify from your description:

```bash
/sdlc:start --intent bug-fix "order total wrong when discount applied"
/sdlc:start --intent new-feature "add multi-currency support"
```

### Branch-scoped workspaces

Every git branch has its own isolated workspace. State, progress, and artifacts are stored at `.sdlc/workflows/<branch>/`. Switching branches switches full context.

```
.sdlc/
  workflows/
    feature--payments/       ← feature/payments branch
      STATE.md               ← phase status, mode, decisions, gate overrides
      artifacts/             ← all phase outputs
    main/                    ← main branch workspace
  ITERATIONS/                ← ITER-001.md, ITER-002.md, ...
  codebase/                  ← brownfield map (shared across branches)
```

### Stale cascade — know exactly what needs revisiting

When you re-run a phase, all downstream phases are automatically flagged stale. The artifact still exists and is readable — but the dashboard warns before you proceed.

```
✅ data-model   — completed 2026-03-25
⚠️ tech-arch    — stale (data-model re-run)
⚠️ plan         — stale (data-model re-run)
⏳ code         — pending
```

### Requirements that actually drive the work

Every requirement gets a `REQ-ID`. Every business rule gets a `BR-ID`. Every NFR gets a **numeric threshold** — not "fast" but "p95 < 200ms at 1000 RPS". These IDs flow all the way through to test cases and automation. When a requirement changes, you know exactly what breaks.

### A data model that's the single source of truth

The canonical data model is designed before architecture and code. Everything derives from it — API shapes, domain entities, test factories, database migrations. Change a field and automatic impact analysis tells you exactly what breaks downstream before you touch a line of code.

### Clean architecture that stays clean

Code is implemented in strict layer order: domain → application → infrastructure → delivery. The dependency rule is enforced. Every external integration goes through a port interface. No God objects, no magic numbers, no spaghetti.

### Tests anchored to requirements, not vibes

Test cases are derived from every source: requirements, API spec, data model invariants, architecture decisions, observability commitments. Nine test layers — unit, integration, contract, E2E, performance, scalability, resilience, observability, security, plus smoke/synthetic monitoring — all with TC-IDs that trace back to a source document. Coverage gates fail the CI build.

### Observability as a first-class deliverable

Structured JSON logging with mandatory `trace_id` and `span_id` fields. OpenTelemetry distributed tracing with W3C context propagation. Prometheus RED metrics at every service boundary. Health endpoints that actually check dependencies.

### Resilience built in, not bolted on

Every external dependency is classified (CRITICAL / DEGRADABLE / OPTIONAL) with explicit timeouts, circuit breakers, fallbacks, and retry logic. Chaos tests verify it all actually works.

### Production-ready microservice scaffolding

```bash
/sdlc:scaffold "payment-service"
```

Generates: clean architecture skeleton, multi-stage Dockerfile (non-root, layer caching), docker-compose dev stack, Kubernetes manifests (Deployment, Service, ConfigMap, HPA, PDB), Kustomize overlays, GitHub Actions CI/CD with Trivy CVE scanning, graceful shutdown handler.

### Decisions captured automatically

Every architectural and product decision made in conversation is silently recorded by the always-on `/sdlc:decide` skill. The moment you say "we'll use Postgres" or "dropping bulk import from v1" — it's written down with the reason.

### Context management across sessions

**End of day — `/sdlc:eod`:** reaches a clean stop, commits WIP, saves a precise snapshot of where you are, and tells you exactly what to run first tomorrow.

**During the day — `/loop 15m /sdlc:checkpoint`:** auto-saves state every 15 minutes. If Claude auto-compacts, nothing is lost.

**Start of day — `/sdlc:sod`:** reads yesterday's checkpoint, flags stale decisions, sets a realistic goal, delivers a structured brief.

```
Morning:  /sdlc:sod
During:   /loop 15m /sdlc:checkpoint
Evening:  /sdlc:eod
```

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

All 11 gates are hard-enforced. Bypass with `--force` (reason required, logged to `STATE.md`).

| Gate | Upstream requires | Blocks | Key structural checks |
|------|-----------------|--------|----------------------|
| `research→synthesize` | `research.md` with ≥2 named competitors + `gap-analysis.md` | synthesize | Market Landscape section, ≥1 gap |
| `synthesize→idea` | `synthesis.md` with synthesis language | idea | No `{{placeholder}}` or `[TBD]` |
| `idea→data-model` ⚠️ | `prd.md` with ≥3 REQ-IDs + ≥3 acceptance criteria + out-of-scope section | data-model, test-cases | No placeholders |
| `data-model→tech-arch` ⚠️ | `data-model.md` with ≥1 bounded context + Mermaid ERD + `data-dictionary.md` for every entity | tech-arch | id/created_at/updated_at on every entity |
| `data-model→test-cases` ⚠️ | `data-model.md` + `data-dictionary.md` + ≥1 entity with invariants | test-cases | — |
| `tech-arch→plan` | `tech-architecture.md` + `lld.md` + `api-spec.md` + `solution-design.md` with ≥1 ADR | plan | No placeholders |
| `plan→code` ⚠️ | `implementation-plan.md` with ≥3 tasks + file changes + DoD + explicit approval | code | — |
| `code→verify` | ≥1 source file modified + ≥1 task done | verify | — |
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

Open any project in Claude Code and run `/sdlc:00-start "your idea"` to start a new project, or `/sdlc:00-start` (no args) to see the status of an existing one.

On first run, the system automatically:
1. Detects your git branch and creates a branch-scoped workspace at `.sdlc/workflows/<branch>/`
2. Creates `.sdlc/CLAUDE.md` (framework reference)
3. Asks setup questions → generates `.sdlc/config.yaml`
4. Offers to add `.gitignore` entries

### Configure

Edit `.sdlc/config.yaml`. Critical fields:

```yaml
projectName: "my-service"      # required
techStack:
  language: typescript         # required
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
| `/sdlc:iterate <feature>` | **Add or evolve features.** Scoped mini-lifecycle — updates only the docs and phases the change touches. |
| `/sdlc:fix <what's broken>` | **Fix things.** Bug fixes (default), hotfixes (`--hotfix` for production incidents), maintenance (`--maintenance` for debt/upgrades). |
| `/sdlc:release [version]` | **Ship work.** Groups ITER-NNN + FIX-NNN into a versioned release. Generates CHANGELOG.md, git tag recommendation. |
| `/sdlc:review [area]` | **Quality audit.** 12-dimension cross-cutting review: requirements, data, arch, tests, resilience, deployment, security. |

### Codebase navigation

| Command | What it does |
|---------|-------------|
| `/sdlc:explore <question>` | Answer codebase questions: "where is X?", "what calls Y?", "how are errors handled?" |
| `/sdlc:map` | Brownfield setup — 4 parallel agents map architecture, tech stack, conventions, and cross-cutting concerns. Run once. |
| `/sdlc:gaps` | 3 gap analysis agents — tech debt, architecture drift, quality/coverage gaps. Run after `/sdlc:map`. |

### Daily cheatsheet

```
Morning:    /sdlc:sod
Afternoon:  /sdlc:iterate "add loyalty points"   ← new feature
            /sdlc:fix "cart total wrong"          ← bug fix
            /sdlc:iterate --type nfr "upgrade deps, address CVEs"  ← modernise
            /sdlc:iterate --type enhancement "refactor payment domain"  ← refactor
Evening:    /sdlc:eod

Ready to ship:    /sdlc:release --minor
Quality check:    /sdlc:review
Production fire:  /sdlc:fix --hotfix "payment gateway down"
```

---

### Advanced / direct phase access

The commands below are invoked automatically by the workflows above. Available if you need to jump to a specific phase.

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

Every phase outputs to a canonical artifact in the branch-scoped workspace. Artifacts are **updated in place** — never versioned with `_v2` suffixes, never duplicated.

```
.sdlc/
  workflows/
    <branch>/
      STATE.md                         Phase status, mode, decisions, gate log
      artifacts/
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
| `DEC-NNN` | Decision record | Any phase | `STATE.md` |

---

## Standards Encoded

| Area | Standards Applied |
|------|------------------|
| Data modeling | DDD (bounded contexts, aggregates, entities, value objects), ISO 4217, ISO 8601, RFC 4122, E.164 |
| Architecture | Clean Architecture, Ports & Adapters, C4 Model, OpenAPI 3.x, CQRS, Saga, Outbox Pattern, Event Sourcing |
| Product | SMART NFRs, MoSCoW prioritisation (≤40% Must), JTBD, BDD completeness, anti-personas |
| Testing | MECE, Given/When/Then (BDD), Testing Pyramid, Consumer-Driven Contract Testing (Pact), 9-layer coverage model |
| Observability | OpenTelemetry, W3C TraceContext, Prometheus/OpenMetrics, structured JSON logging, RED metrics |
| Resilience | Circuit Breaker, Retry + Full Jitter Backoff, Bulkhead, Graceful Degradation, Idempotency Keys, Chaos Testing |
| API design | REST conventions, URI versioning, RFC 8594 Sunset headers, cursor pagination, idempotency keys, OWASP API Top 10 |
| Deployment | Multi-stage Dockerfile, non-root containers, K8s resource limits/probes/HPA/PDB, Blue-Green/Canary strategies |
| Security | STRIDE threat modeling, secret rotation lifecycle, dependency vulnerability scanning (SBOM/Trivy) |
| Data operations | Zero-downtime migration patterns (expand/contract, dual-write), database indexing strategy, caching strategy |
| Frontend | Expo SDK, React Native, Expo Router v3, Tamagui design tokens, TanStack Query v5, WCAG 2.1 AA |
| Documentation | 50-line rule, tables over prose, ID-first formatting, complexity budgets |

---

## Key Design Principles

**Data model first.** Architecture, API shapes, and code all derive from the canonical data model. Any change to an existing entity triggers automatic impact analysis showing exactly what breaks downstream.

**No code without a plan.** Tasks are atomic, layered (domain → application → infrastructure → delivery), and independently verifiable. The clean architecture dependency rule is enforced.

**Phase scope boundaries are explicit.** Phase 8 implements business logic — nothing more. Resilience patterns are Phase 12. Observability spec is Phase 11. This keeps each phase focused.

**Tests from requirements, not from code.** Test cases are derived from every source document. Nine test layers ensure nothing is missed. Every TC-ID traces to a source.

**Verify before you proceed.** Each phase has an independent verification step that checks completeness, internal consistency, and cross-phase references.

**Documents are living artifacts.** IDs (REQ, BR, TC) are permanent — only deprecated, never deleted. When requirements change, the document is updated and downstream stale flags are raised automatically.

**Token cost is a design constraint.** Documents are structured to be partially loadable — first 50 lines orient, sections answer one question each. Claude loads what it needs, not everything.

---

## License

MIT
