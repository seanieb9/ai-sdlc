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

Every iteration gets a stable ID (`ITER-001`, `ITER-002`, ...) tracked in `.claude/ai-sdlc/ITERATIONS/`.

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

/sdlc:iterate --type nfr "upgrade to Node 22 and address security advisories"
/sdlc:iterate --type data "normalise the legacy orders schema"
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
/sdlc:iterate --type enhancement "extract payment domain into bounded context"
/sdlc:iterate --type enhancement "move infrastructure dependencies behind port interfaces"
/sdlc:13-review    # 12-dimension quality audit after completion
```

Refactors go through the plan phase — tasks ordered by clean architecture layer (domain → application → infrastructure → delivery), independently verifiable, dependency rule enforced throughout.

---

### Daily rhythm

```
Morning:   /sdlc:sod              ← reads checkpoint, sets goal, delivers brief
During:    /sdlc:checkpoint       ← save session state before context gets full
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

```bash
/sdlc:00-start --intent bug-fix "order total wrong when discount applied"
/sdlc:00-start --intent new-feature "add multi-currency support"
```

---

### Hard-enforced phase gates

11 gates that block progression when structural requirements aren't met. Cannot be implicitly skipped — bypass requires `--force` with a logged justification.

| Gate | Upstream requires | Blocks |
|------|-----------------|--------|
| `idea→data-model` ⚠️ | `prd.md` ≥3 REQ-IDs, ≥3 acceptance criteria, out-of-scope section | data-model, test-cases |
| `data-model→tech-arch` ⚠️ | Mermaid ERD, data dictionary for every entity, `id`/`created_at`/`updated_at` on every entity | tech-arch |
| `plan→code` ⚠️ | ≥3 tasks with file changes, DoD, explicit approval | code |
| `test-cases→test-gen` ⚠️ | ≥3 TC-IDs, coverage matrix, no duplicate IDs, pyramid shape check | test-gen |
| `verify→deploy` | 0 open CRITICAL findings | deploy |
| + 6 more | research, synthesize, tech-arch, observability, security gates | — |

---

### Auto-chains — quality checks that fire automatically

After each phase completes, associated skills run silently and log results to `state.json`. No manual triggering required.

| Trigger phase | Auto-chain skills |
|---|---|
| `idea` | `nfr-analysis` — NFRs decomposed into architectural implications before design begins |
| `research` | `gaps` — validates gap analysis before synthesize proceeds |
| `design` | `threat-model`, `adr-gen`, `infra-design`, `observability` (skeleton), `sre` (skeleton) |
| `data-model` | `pii-audit` — identifies PII fields at data layer before design locks in |
| `customer-journey` | `clarify` — validates journeys map to requirements (if open questions remain) |
| `plan` | `roadmap` — generates phase timeline with actuals from plan |
| `test-gen` | `test-gaps`, `traceability` |
| `build` | `code-quality`, `audit-deps`, `pii-audit` (if observability.md exists) |
| `deploy` | `ci-verify` (hard gate), `maintain` |

---

### Self-correcting verification loop

Every code task runs two verification passes before it can be marked complete:

**Auto-Verify Gate** — runs tooling after implementation:

| Check | Auto-fix on failure |
|-------|-------------------|
| Lint (`eslint` / `ruff` / `golangci-lint` / `rubocop`) | Auto-fix, re-run |
| Format (`prettier` / `ruff format` / `gofmt`) | Auto-format, re-run |
| Type check (`tsc --noEmit` / `mypy`) | Fix manually, re-run |
| Unit tests + coverage gate | Diagnose, fix, re-run |

**Self-Correction Gate** — runs before marking done:
1. Syntax check — obvious errors fixed inline
2. Contract check — implementation matches API spec / interface
3. Test alignment — key paths mentally traced against test cases
4. Clean architecture — logic in the right layer

Max 2 self-correction attempts. If still failing: task marked BLOCKED and surfaced to user with specific failure description.

---

### Data model challenger review

After the data model is written but before it's finalised, an adversarial review takes an active attack posture against the design across six dimensions: missing entities, aggregate boundaries, missing invariants, primitive obsession, wrong cardinality, and naming/ubiquitous language.

Findings are classified BLOCKING (must fix before proceeding) or WARN (can proceed with a recorded decision).

---

### Architecture challenger review

Before moving to planning, the architecture is reviewed from two explicit positions — a structured adversarial debate across six dimensions: over-engineering, NFR gaps, security surface, data model/API mismatch, operational survivability, and irreversible decisions.

Both positions are presented side-by-side. Options: address now, or accept risk with a statement recorded in an ADR.

---

### Requirements that actually drive the work

Every requirement gets a `REQ-ID`. Every business rule gets a `BR-ID`. Every NFR gets a **numeric threshold** — not "fast" but "p95 < 200ms at 1000 RPS". These IDs flow through to test cases, automation scripts, and SLOs. When a requirement changes, the full impact is traceable.

---

### End-to-end requirements traceability

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

Traceability matrix generated automatically after test-gen phase. No orphaned tests. No uncovered requirements.

---

### 9-layer test coverage

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

---

### Security gate at deploy

Before any deployment, a 4-check security gate runs:

1. **No hardcoded secrets** — grep for `password =`, `api_key =`, `secret =` as string literals. Hard stop if found.
2. **Dependency audit passed** — `audit-deps` must show success in `autoChainLog`. Runs inline if not.
3. **Threat model addressed** — high-severity findings from threat-model must have documented mitigations.
4. **PII compliance** — no PII fields exposed in logs per pii-audit results.

Checks 1–2 are hard stops. Checks 3–4 warn and require explicit confirmation.

---

### Institutional memory across sessions

`/sdlc:checkpoint` now captures session learnings and appends them to the project's `CLAUDE.md` — non-obvious patterns, user preferences, surprises, decisions made verbally. Max 5 learnings per session. Knowledge compounds across context windows.

---

### Context management

**End of day — `/sdlc:eod`:** reaches a clean stop, commits WIP, saves a precise snapshot, tells you exactly what to run first tomorrow.

**After auto-compact:** a `PostCompact` hook automatically injects a resume instruction so Claude re-orients without any manual step.

**Session start:** a `SessionStart` hook warns if no checkpoint exists or the checkpoint is over 24h old.

**Start of day — `/sdlc:sod`:** reads yesterday's checkpoint, flags stale decisions, sets a realistic goal, delivers a structured brief.

---

### Branch-scoped workspaces

Every git branch has its own isolated workspace at `.claude/ai-sdlc/workflows/<branch>/`. Switching branches switches full context.

```
.claude/ai-sdlc/
  workflows/
    feature--payments/
      state.json          ← phase status, decisions, checkpoint, autoChainLog
      artifacts/          ← all phase outputs
    main/
  ITERATIONS/             ← ITER-001.md, ITER-002.md, ...
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

## The Lifecycle

Phases are organised in six tiers. `◉` = checkpoint phase (pauses for developer review). ⚠️ = hard gate.

### Tier 0 — ASSESS *(optional)*
| # | Phase | Command | What it does |
|---|-------|---------|-------------|
| 0 | **Feasibility** `◉` | `/sdlc:00-start` | Go/No-Go viability: market size, technical risk, competitive moat, build vs buy |

### Tier 1 — DISCOVER
| # | Phase | Command | What it does |
|---|-------|---------|-------------|
| 1 | **Research** | `/sdlc:01-research` | Market landscape, competitive SWOT, best practices, emerging trends. Auto-chain: gaps. |
| 2 | **Synthesize** | `/sdlc:02-synthesize` | Merge research + codebase analysis into unified strategic direction |

### Tier 2 — DEFINE
| # | Phase | Command | What it does |
|---|-------|---------|-------------|
| 3 | **Product Spec** `◉` | `/sdlc:03-product-spec` | REQ-IDs, BR-IDs, numeric NFR-IDs, acceptance criteria, BDD scenarios. Auto-chain: nfr-analysis. |
| 4 | **Customer Journey** *(optional)* | `/sdlc:04-customer-journey` | Journey maps, failure paths, emotional states, screen flows. Auto-chain: clarify. |

### Tier 3 — BUILD
| # | Phase | Command | What it does |
|---|-------|---------|-------------|
| 5 | **Data Model** `◉` ⚠️ | `/sdlc:05-data-model` | DDD canonical model — bounded contexts, aggregates, ERDs, invariants, data dictionary. Challenger review. Auto-chain: pii-audit. |
| 6 | **Tech Architecture** `◉` | `/sdlc:06-tech-arch` | C4 diagrams, clean architecture, LLD, API spec, ADRs. Challenger review. Auto-chains: threat-model, adr-gen, infra-design, observability skeleton, sre skeleton. |
| 7 | **Plan** `◉` ⚠️ | `/sdlc:07-plan` | Atomic tasks ordered by clean architecture layer. Auto-chain: roadmap. |
| 8 | **Code** `◉` | `/sdlc:08-code` | Implement tasks. Auto-verify gate + self-correction gate per task. Auto-chains: code-quality, audit-deps, pii-audit. |

### Tier 4 — VERIFY
| # | Phase | Command | What it does |
|---|-------|---------|-------------|
| 9 | **Test Cases** `◉` ⚠️ | `/sdlc:09-test-cases` | MECE Given/When/Then across 9 layers, anchored to every source document |
| 10 | **Test Generation** | *(auto, after test-cases)* | Automation scripts — 1:1 TC-ID mapping, coverage gate, drift detection. Auto-chains: test-gaps, traceability. |
| 11 | **Observability** | `/sdlc:11-observability` | Structured logging spec, OTel tracing, Prometheus RED metrics — OBS-IDs committed before SRE |
| 12 | **SRE** | `/sdlc:12-sre` | SLOs, runbooks per critical failure scenario, incident response, resilience verification |
| 13 | **Verify** `◉` | `/sdlc:verify` | Cross-cutting quality audit — 0 open CRITICAL findings required to proceed |

### Tier 5 — SHIP
| # | Phase | Command | What it does |
|---|-------|---------|-------------|
| 14 | **Deploy** `◉` | `/sdlc:deploy` | Security gate, deployment checklist, rollback plan, handoff. Auto-chains: ci-verify (hard gate), maintain. |

---

## Phase Gates

All gates are hard-enforced. Bypass with `--force` (reason required, logged to `state.json`).

| Gate | Upstream requires | Blocks |
|------|-----------------|--------|
| `research→synthesize` | `research.md` ≥2 named competitors + `gap-analysis.md` | synthesize |
| `synthesize→idea` | `synthesis.md` with synthesis language, no `[TBD]` | idea |
| `idea→data-model` ⚠️ | `prd.md` ≥3 REQ-IDs + ≥3 acceptance criteria + out-of-scope section | data-model, test-cases |
| `data-model→tech-arch` ⚠️ | `data-model.md` ≥1 bounded context + Mermaid ERD + `data-dictionary.md` | tech-arch |
| `tech-arch→plan` | `tech-architecture.md` + `api-spec.md` + `solution-design.md` ≥1 ADR | plan |
| `plan→code` ⚠️ | `implementation-plan.md` ≥3 tasks + file changes + DoD + explicit approval | code |
| `test-cases→test-gen` ⚠️ | `test-cases.md` ≥3 TC-IDs + coverage matrix + no duplicate IDs | test-gen |
| `observability→sre` | `observability.md` with logging spec + `trace_id`/`span_id` mandatory | sre |
| `verify→deploy` | `verification-report.md` 0 open CRITICAL findings | deploy |

---

## Installation

### New machine setup (30 seconds)

```bash
git clone https://github.com/seanieb9/ai-sdlc.git ~/sdlc
cd ~/sdlc && bash install.sh
```

`install.sh` merges two Claude Code hooks into `~/.claude/settings.json` without touching any existing settings:
- **SessionStart** — warns if no checkpoint or checkpoint is >24h old
- **PostCompact** — auto-injects `/sdlc:resume` after every context compaction

Safe to re-run — skips hooks already installed.

### Install the commands

```bash
# Install commands globally (available in all projects)
cp -r ~/sdlc/commands/sdlc ~/.claude/commands/

# Install workflow engine, references, and templates
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

---

## Commands (28 total)

### Session
| Command | What it does |
|---------|-------------|
| `/sdlc:00-start [idea]` | **Universal entry point** — new project, status check, daily brief, resume |
| `/sdlc:sod` | Start of day — reads checkpoint, sets goal, delivers brief |
| `/sdlc:eod` | End of day — clean stop, commit WIP, save checkpoint |
| `/sdlc:checkpoint` | Save session state + update institutional memory in CLAUDE.md |
| `/sdlc:resume` | Restore full context after `/clear` or auto-compact |
| `/sdlc:status` | Live dashboard: phases, gates, progress, stale flags |
| `/sdlc:help` | Show all commands |
| `/sdlc:verify` | Quality gate — run after each phase |

### Lifecycle phases
| Command | Phase |
|---------|-------|
| `/sdlc:01-research` | Market, competitive & gap research |
| `/sdlc:02-synthesize` | Combine research + codebase |
| `/sdlc:03-product-spec` | Requirements, BDD, business rules |
| `/sdlc:04-customer-journey` | Journey maps & screen flows |
| `/sdlc:05-data-model` ⚠️ | Canonical data model — must run before design |
| `/sdlc:06-tech-arch` | Clean arch, C4 model, API specs |
| `/sdlc:07-plan` | Phased execution plan + TODO list |
| `/sdlc:08-code` | Implement tasks |
| `/sdlc:09-test-cases` | MECE GWT test cases |
| `/sdlc:11-observability` | Logging, tracing, metrics |
| `/sdlc:12-sre` | SLOs, runbooks, incident response |
| `/sdlc:13-review` | Cross-cutting quality review |

### Iteration & release
| Command | What it does |
|---------|-------------|
| `/sdlc:iterate <feature>` | Scoped feature iteration |
| `/sdlc:fix <bug>` | Bug fix / hotfix |
| `/sdlc:release [version]` | Group iterations into a versioned release |
| `/sdlc:deploy` | Deploy with security gate, checklist, rollback plan |

### Brownfield
| Command | What it does |
|---------|-------------|
| `/sdlc:map` | Map codebase → persistent index |
| `/sdlc:explore <question>` | Answer codebase questions |

### Project management
| Command | What it does |
|---------|-------------|
| `/sdlc:roadmap` | Human session plan for the project |
| `/sdlc:decide` | Record an architectural decision |
| `/sdlc:docs` | Audit & organise SDLC documents |

> All specialist workflows (threat-model, pii-audit, test-gaps, traceability, retro, prr, etc.) run automatically via auto-chains — no manual invocation needed.

---

## What Gets Produced

Every phase outputs to a canonical artifact. Updated in place — never versioned with `_v2` suffixes.

```
.claude/ai-sdlc/
  workflows/
    <branch>/
      state.json                    ← phase status, checkpoint, autoChainLog, decisions
      artifacts/
        feasibility/                feasibility.md
        research/                   research.md, gap-analysis.md
        voc/                        voc.md
        synthesize/                 synthesis.md
        idea/                       prd.md
        personas/                   personas.md
        journey/                    customer-journey.md
        business-process/           business-process.md
        prototype/                  prototype-spec.md
        data-model/                 data-model.md, data-dictionary.md  ⚠️
        tech-arch/                  tech-architecture.md, lld.md, api-spec.md, solution-design.md
        threat-model/               threat-model.md
        infra-design/               Dockerfile, helm/, terraform/
        fe-setup/                   design-tokens.md, component-library.md, screen-spec.md
        plan/                       implementation-plan.md
        test-cases/                 test-cases.md
        test-gen/                   test-automation.md, test files
        observability/              observability.md
        sre/                        runbooks.md
        verify/                     verification-report.md
        uat/                        uat-plan.md
        deploy/                     deployment-checklist.md
        maintain/                   maintenance-plan.md
        retro/                      retro.md
  ITERATIONS/                       ITER-001.md, ITER-002.md, ...
```
