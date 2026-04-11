# AI-SDLC — Enterprise Software Development Lifecycle for Claude Code

> Turn Claude Code into a disciplined engineering team. Go from raw idea to production-ready, fully documented, thoroughly tested software — with process gates, architecture standards, and quality enforced at every step.

---

## The Problem

AI coding assistants are powerful but undisciplined. Left to their own devices they:

- Jump straight to code before requirements are understood
- Build on shaky data models that break everything downstream
- Skip architecture decisions that matter at scale
- Generate tests that verify implementation details instead of requirements
- Ship code with no observability, no resilience patterns, no runbooks
- Produce undocumented decisions that haunt the team six months later

The result is fast-looking progress that collapses under real-world conditions.

---

## The Solution

**AI-SDLC** is a Claude Code plugin that enforces a rigorous, opinionated software development lifecycle. It works the way a senior engineering team works — research before spec, spec before data model, data model before architecture, architecture before code — and it doesn't let you skip steps.

**You only type 9 commands.** The orchestrator handles everything else — 24 phases, 20+ auto-chains, and all quality gates — inline, automatically, with human review pauses only at the decisions that matter.

---

## How to Use

### 1. Start a brand-new project

```
/sdlc:00-start "I want to build a payment processing API"
```

The orchestrator classifies intent, detects complexity (SIMPLE / STANDARD / CRITICAL), and runs the full lifecycle in order — completely inline, no additional commands needed:

```
Research → Synthesize → Product Spec ◉ → Customer Journey →
Data Model ◉⚠️ → Tech Architecture ◉ → Plan ◉⚠️ → Code →
Test Cases ◉⚠️ → Test Gen → Observability → SRE → Review → Verify ◉ → Deploy ◉
```

`◉` = human review pause. `⚠️` = hard gate. Everything else runs automatically.

---

### 2. Add a feature to an existing project

```
/sdlc:iterate "add multi-currency support"
/sdlc:iterate "loyalty points module"
/sdlc:iterate --type enhancement "improve checkout performance"
```

`/sdlc:iterate` determines which phases the change touches and runs only those — in order, with impact propagation. New REQ-IDs, TC-IDs, and ADRs continue the existing sequence.

**On an existing codebase:** `/sdlc:00-start` detects it automatically and maps the codebase inline before proceeding. No separate map command needed.

Every iteration gets a stable ID (`ITER-001`, `ITER-002`, ...) tracked in `.claude/ai-sdlc/ITERATIONS/`.

---

### 3. Fix a bug

```
/sdlc:fix "order total is wrong when a discount is applied"
/sdlc:fix --hotfix "payment gateway returning 500"
```

Lighter path — diagnose, plan, code, regression test, verify. No spec update unless the bug reveals a design gap.

---

### 4. Modernise or refactor

```
/sdlc:iterate --type nfr "upgrade to Node 22 and address security advisories"
/sdlc:iterate --type data "normalise the legacy orders schema"
/sdlc:iterate --type enhancement "extract payment domain into bounded context"
```

| Flag | Use when |
|------|----------|
| `--type nfr` | New SLA target, performance requirement, or security baseline |
| `--type data` | Schema change, migration, data normalisation |
| `--type enhancement` | Extend or improve an existing feature |

---

### Daily rhythm

```
Morning:   /sdlc:sod         ← reads checkpoint, sets goal, delivers brief
During:    /sdlc:checkpoint  ← save state before context fills
Evening:   /sdlc:eod         ← clean stop, commit WIP, write tomorrow's first action

Status:    /sdlc:status      ← phases, active work, gates, stale flags
Resume:    /sdlc:resume      ← restore exactly where you left off after /clear
```

---

## Commands (9 total)

Everything else is automatic. You never need to type a phase command — the orchestrator handles the full lifecycle from `/sdlc:00-start`.

| Command | What it does |
|---------|-------------|
| `/sdlc:00-start <idea>` | **Universal entry point** — new project, new feature, resume, status, brownfield |
| `/sdlc:fix <bug>` | Bug fix / hotfix |
| `/sdlc:iterate <feature>` | Scoped feature iteration |
| `/sdlc:sod` | Start of day — reads checkpoint, plans session, delivers brief |
| `/sdlc:eod` | End of day — commits WIP, saves checkpoint |
| `/sdlc:checkpoint` | Save session state + update institutional memory in CLAUDE.md |
| `/sdlc:resume` | Restore full context from `state.json` after `/clear` or auto-compact |
| `/sdlc:status` | Live dashboard: phases, gates, progress, stale flags |
| `/sdlc:help` | Show all commands and the auto-chain table |

---

## What You Get

### Intent-driven routing

| Intent | Entry | Phase path |
|--------|-------|-----------|
| `new-project` | Research | Full lifecycle |
| `new-feature` | Product spec | idea → data-model → design → plan → code → test-cases → test-gen → verify → deploy |
| `bug-fix` | Plan | plan → code → test-cases → verify |
| `refactor` | Synthesize | synthesize → data-model check → plan → code → test-cases → verify |

```
/sdlc:00-start --intent bug-fix "order total wrong when discount applied"
/sdlc:00-start --intent new-feature "add multi-currency support"
```

---

### Human touchpoints — only where judgment matters

You are paused for review at exactly these points. Everything else runs without interruption.

| Touchpoint | What you decide |
|---|---|
| Product spec `◉` | Confirm requirements, scope, and acceptance criteria before locking |
| NFR review | Approve NFRs before data model begins — NFRs shape schema design |
| Data model `◉` ⚠️ | Challenger review across 6 dimensions + approval before architecture |
| Tech architecture `◉` | Adversarial debate across 6 dimensions + approval before planning |
| Plan `◉` ⚠️ | Approve task breakdown before any code is written |
| Verify `◉` | Quality gate — 0 open CRITICAL findings required before deploy |
| Deploy `◉` | Security gate checklist + sign-off |

---

### Auto-chains — the full pipeline

After each phase completes, associated skills fire silently and log to `state.json`. The complete chain from idea to deploy-ready:

| Trigger | Auto-chain | What it does |
|---|---|---|
| `idea` | `nfr-analysis` | Decomposes NFRs into architectural implications, ADR candidates, test layers |
| `nfr-analysis` | `nfr-slo` | Derives SLO definitions + Prometheus alert skeletons from SLO candidates |
| `research` | `gaps` | Validates gap analysis before synthesize proceeds |
| `data-model` | `pii-audit` | Identifies PII fields before design locks in |
| `data-model` | `migrate-scaffold` | Scaffolds forward + rollback migration stubs per entity |
| `design` | `threat-model` | STRIDE analysis → CRITICAL/HIGH threats auto-create TC-SEC-IDs + plan tasks |
| `design` | `adr-gen` | Validates ADR completeness, creates stubs for undocumented decisions |
| `adr-gen` | `adr-test-coverage` | Ensures every ADR has a covering test case; creates stubs for gaps |
| `design` | `contract-test-scaffold` | Scaffolds consumer-driven contract tests per API endpoint |
| `design` | `infra-design` | Generates Dockerfile, Helm charts, Terraform stubs |
| `design` | `observability` skeleton | Pre-populates observability structure so plan can scope it |
| `design` | `sre` skeleton | Pre-populates runbook structure |
| `customer-journey` | `clarify` | Validates journeys map to requirements (if open questions remain) |
| `plan` | `roadmap` | Generates phase timeline with human session estimates |
| `test-cases` | `bdd-tdd-scaffold` | Generates Gherkin feature files + failing TDD stubs per TC-ID |
| `test-gen` | `test-gaps` | Identifies missing test coverage before build |
| `test-gen` | `traceability` | Verifies every REQ/NFR/endpoint has a covering test |
| `build` | `code-quality` | Static analysis, security scan, complexity check |
| `build` | `debt-log` | CRITICAL/HIGH findings → `state.json` technicalDebts + plan tasks |
| `build` | `audit-deps` | Dependency vulnerability audit |
| `build` | `pii-audit` | Verifies no PII in logs (if observability.md exists) |
| `deploy` | `ci-verify` | Hard gate — blocks deploy if CI pipeline missing |
| `deploy` | `maintain` | Generates initial maintenance plan |

---

### The complete AC → TDD → verify chain

The workflow the user described — and it works end-to-end automatically:

```
Write acceptance criteria (product spec)
  ↓ nfr-analysis decomposes NFRs → SLOs auto-derived
  ↓ [Human: NFR review before data model]
  ↓ data-model → migration stubs scaffolded
  ↓ design → threat model fires → CRITICAL/HIGH threats become TC-SEC + TASK-SEC
           → every ADR gets a covering test case
           → contract tests scaffolded per endpoint
  ↓ test-cases → Gherkin feature files + failing TDD stubs per TC-ID
  ↓ [Human: approve test cases]
  ↓ code: implement against failing stubs
       → lint + format + type-check + unit tests run after every file write
       → TDD stub expected to fail first, passes after implementation
  ↓ build complete → quality findings → debt register + plan tasks
  ↓ [Human: verify gate]
  ↓ deploy → security gate → checklist sign-off
```

---

### Hard-enforced phase gates

| Gate | Upstream requires | Blocks |
|------|-----------------|--------|
| `idea→data-model` ⚠️ | `prd.md` ≥3 REQ-IDs + acceptance criteria + out-of-scope section | data-model, test-cases |
| `data-model→tech-arch` ⚠️ | Mermaid ERD + data dictionary + `id`/timestamps on every entity | tech-arch |
| `tech-arch→plan` | `tech-architecture.md` + `api-spec.md` + `solution-design.md` ≥1 ADR | plan |
| `plan→code` ⚠️ | `implementation-plan.md` ≥3 tasks + file changes + DoD + explicit approval | code |
| `test-cases→test-gen` ⚠️ | `test-cases.md` ≥3 TC-IDs + coverage matrix + no duplicates | test-gen |
| `observability→sre` | `observability.md` with logging spec + trace/span IDs | sre |
| `verify→deploy` | `verification-report.md` — 0 open CRITICAL findings | deploy |

All gates hard-enforced. Bypass with `--force` (reason required, logged to `state.json` gateOverrides).

---

### Self-correcting verification loop

Every code task runs two passes before it can be marked complete:

**After every file write (PostToolUse stack):**

| Check | On failure |
|-------|-----------|
| Lint (eslint / ruff / golangci-lint) | Auto-fix, re-run |
| Format (prettier / ruff format / gofmt) | Auto-format, re-run |
| Type check (tsc / mypy) | Fix manually, re-run |
| Unit tests for changed file | TDD stubs fail first (expected) — fix until green |

**Self-correction gate before marking done:**
1. Contract check — implementation matches API spec
2. Test alignment — key paths traced against TC-IDs
3. Clean architecture — logic in the right layer

Max 2 attempts. Still failing → task marked BLOCKED, surfaced to user.

---

### 9-layer test coverage

| Layer | What's tested |
|-------|--------------|
| Unit | Domain entities, value objects, use cases in isolation |
| Integration | Repository implementations, adapter integrations |
| Contract | API consumer-driven contracts (auto-scaffolded from api-spec.md) |
| E2E | Full user journeys via UI or API |
| Performance | Latency and throughput against NFR thresholds |
| Scalability | Behaviour under peak load multipliers |
| Resilience | Circuit breaker trips, dependency failures, chaos scenarios |
| Observability | Logs emitted, spans created, metrics incremented |
| Security | OWASP API Top 10 + TC-SEC-IDs from threat model |

---

### Security gate at deploy

Before any deployment, a 4-check gate runs:

1. **No hardcoded secrets** — grep for `password =`, `api_key =`, `secret =`. Hard stop if found.
2. **Dependency audit passed** — `audit-deps` must show success in `autoChainLog`.
3. **Threat model addressed** — CRITICAL/HIGH threats must have documented mitigations + TC-SEC-IDs.
4. **PII compliance** — no PII fields in logs per pii-audit results.

Checks 1–2 are hard stops. Checks 3–4 warn and require explicit confirmation.

---

### Subagent roles for complex tasks

Four read-only subagent roles are prescribed for COMPLEX tasks or anything touching auth, payments, or PII:

| Role | Tools | Purpose |
|------|-------|---------|
| `code-architect` | Read, Glob, Grep | Designs implementation before writing — outputs file list + signatures |
| `code-simplifier` | Read, Glob, Grep | Reviews written code for over-engineering and unnecessary abstraction |
| `security-reviewer` | Read, Glob, Grep | Reviews against threat model — auth checks, injection, output encoding |
| `test-validator` | Read, Glob, Grep, Bash | Validates implementation matches TC-IDs, runs tests |

---

### Context management

**PostCompact hook:** after every auto-compact, Claude automatically re-orients from `state.json` — no manual step.

**SessionStart hook:** warns if no checkpoint exists or checkpoint is >24h old.

**`/sdlc:checkpoint`:** saves session state to `state.json` + appends learnings to project `CLAUDE.md`. Knowledge compounds across sessions.

---

### Branch-scoped workspaces

Every git branch has its own isolated workspace. Switching branches switches full context.

```
.claude/ai-sdlc/
  workflows/
    feature--payments/
      state.json           ← phase status, decisions, checkpoint, autoChainLog, technicalDebts
      artifacts/           ← all phase outputs (see full list below)
    main/
  ITERATIONS/              ← ITER-001.md, ITER-002.md, ...
```

---

## The Lifecycle

`◉` = checkpoint (human review pause). `⚠️` = hard gate. All phases run automatically via `/sdlc:00-start`.

### Tier 0 — ASSESS *(optional)*
| # | Phase | What it does |
|---|-------|-------------|
| 0 | **Feasibility** `◉` | Go/No-Go: market size, technical risk, competitive moat, build vs buy |

### Tier 1 — DISCOVER
| # | Phase | What it does |
|---|-------|-------------|
| 1 | **Research** | Market landscape, competitive SWOT, best practices. → auto-chain: gaps |
| 2 | **Synthesize** | Merge research + codebase into unified strategic direction |

### Tier 2 — DEFINE
| # | Phase | What it does |
|---|-------|-------------|
| 3 | **Product Spec** `◉` | REQ-IDs, BR-IDs, numeric NFR thresholds, acceptance criteria, BDD scenarios. → auto-chain: nfr-analysis → nfr-slo |
| 4 | **Customer Journey** *(optional)* | Journey maps, failure paths, screen flows. → auto-chain: clarify |

### Tier 3 — BUILD
| # | Phase | What it does |
|---|-------|-------------|
| 5 | **Data Model** `◉` ⚠️ | DDD canonical model — bounded contexts, ERDs, invariants, data dictionary. Challenger review. → auto-chains: pii-audit, migrate-scaffold |
| 6 | **Tech Architecture** `◉` | C4 diagrams, clean architecture, API spec, ADRs. Challenger review. → auto-chains: threat-model, adr-gen, adr-test-coverage, contract-test-scaffold, infra-design, observability skeleton, sre skeleton |
| 7 | **Plan** `◉` ⚠️ | Atomic tasks ordered by clean architecture layer. → auto-chain: roadmap |
| 8 | **Code** | Implement tasks. PostToolUse verification stack on every write. → auto-chains: code-quality, debt-log, audit-deps, pii-audit |

### Tier 4 — VERIFY
| # | Phase | What it does |
|---|-------|-------------|
| 9 | **Test Cases** `◉` ⚠️ | MECE Given/When/Then across 9 layers. → auto-chain: bdd-tdd-scaffold (Gherkin + TDD stubs) |
| 10 | **Test Generation** *(auto)* | Automation scripts, 1:1 TC-ID mapping, coverage gate. → auto-chains: test-gaps, traceability |
| 11 | **Observability** | Structured logging spec, OTel tracing, Prometheus RED metrics, OBS-IDs |
| 12 | **SRE** | SLOs, runbooks per critical failure scenario, incident response, resilience verification |
| 13 | **Verify** `◉` | Cross-cutting quality audit — 0 open CRITICAL findings required |

### Tier 5 — SHIP
| # | Phase | What it does |
|---|-------|-------------|
| 14 | **Deploy** `◉` | Security gate, deployment checklist, rollback plan. → auto-chains: ci-verify (hard gate), maintain |

---

## What Gets Produced

Every phase outputs to a canonical artifact. Updated in place — never `_v2` suffixes.

```
.claude/ai-sdlc/workflows/<branch>/
  state.json                      ← phase status, checkpoint, decisions, autoChainLog, technicalDebts
  artifacts/
    feasibility/                  feasibility.md
    research/                     research.md, gap-analysis.md
    nfr-analysis/                 nfr-analysis.md, slo-definitions.md
    voc/                          voc.md
    synthesize/                   synthesis.md
    idea/                         prd.md
    personas/                     personas.md
    journey/                      customer-journey.md
    business-process/             business-process.md
    prototype/                    prototype-spec.md
    data-model/                   data-model.md, data-dictionary.md ⚠️
                                  migrations/001_create_*.sql, ...
    design/                       tech-architecture.md, lld.md, api-spec.md,
                                  solution-design.md (ADRs), threat-model.md,
                                  contract-tests.md, adr-test-coverage.md,
                                  adr-validation-report.md
    infra-design/                 Dockerfile, helm/, terraform/
    fe-setup/                     design-tokens.md, component-library.md, screen-spec.md
    plan/                         implementation-plan.md
    code-quality/                 quality-report.md
    debt/                         technical-debt.md
    test-cases/                   test-cases.md, bdd-features.md, tdd-stubs.md
    test-gen/                     test-automation.md, test files
    observability/                observability.md
    sre/                          runbooks.md
    verify/                       verification-report.md
    uat/                          uat-plan.md
    deploy/                       deployment-checklist.md
    maintain/                     maintenance-plan.md
    retro/                        retro.md
.claude/ai-sdlc/ITERATIONS/       ITER-001.md, ITER-002.md, ...
```

---

## Installation

### New machine (30 seconds)

```bash
git clone https://github.com/seanieb9/ai-sdlc.git ~/sdlc
cd ~/sdlc && bash install.sh
```

`install.sh` merges two Claude Code hooks into `~/.claude/settings.json`:
- **SessionStart** — warns if no checkpoint or checkpoint is >24h old
- **PostCompact** — auto-injects resume instruction after every context compaction

Safe to re-run — skips hooks already installed.

### Install commands and workflows

```bash
cp -r ~/sdlc/commands/sdlc ~/.claude/commands/
cp -r ~/sdlc/workflows ~/sdlc/references ~/sdlc/templates ~/.claude/sdlc/
```

Open any project in Claude Code and run `/sdlc:00-start "your idea"`.

### Configure

On first run the system creates `.claude/ai-sdlc.config.yaml`. Edit to set your stack:

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
