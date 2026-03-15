# SDLC — Enterprise Software Development Lifecycle for Claude Code

An intent-based SDLC orchestration system built as Claude Code custom commands. Covers the full lifecycle from raw idea to production-ready code — with process gates, canonical documents, and quality enforced at every step.

---

## Quick Start

```bash
# Start anything new here — the orchestrator figures out the rest
/sdlc:00-start "I want to add payment processing to the checkout flow"

# Check where you are at any time
/sdlc:status

# Get help on any command
/sdlc:help
/sdlc:help data-model
```

---

## The Lifecycle

Every project and feature flows through these phases in order. The orchestrator enforces gates — you cannot skip ahead without explicit override.

```
IDEA
 │
 ▼
RESEARCH          /sdlc:01-research        Market, competitive, customer voice
 │
 ▼
VOICE OF CUSTOMER /sdlc:01b-voc           Primary data synthesis (interviews, tickets, NPS)
 │
 ▼
SYNTHESIZE        /sdlc:02-synthesize      Research + existing codebase → unified picture
 │
 ▼
PRODUCT SPEC      /sdlc:03-product-spec    Requirements, BDD, business rules, exceptions
 │
 ▼
PERSONAS          /sdlc:03b-personas       JTBD, empathy maps, anti-personas
 │
 ▼
CUSTOMER JOURNEY  /sdlc:04-customer-journey  Personas, journey maps, screen flows
 │
 ▼
DATA MODEL  ⚠️    /sdlc:05-data-model      Canonical model — EVERYTHING derives from here
 │
 ▼
TECH ARCH         /sdlc:06-tech-arch       Clean architecture, C4, API spec, ADRs
 │
 ▼
PLAN              /sdlc:07-plan            Phased task breakdown with dependencies
 │
 ▼
CODE              /sdlc:08-code            Implement tasks (clean arch, no vibe)
 │
 ▼
TEST CASES        /sdlc:09-test-cases      MECE Given/When/Then, full traceability
 │
 ▼
TEST AUTOMATION   /sdlc:10-test-automation Scripts from test cases (TC-ID mapped)
 │
 ▼
OBSERVABILITY     /sdlc:11-observability   OTel tracing, structured logging, metrics
 │
 ▼
SRE               /sdlc:12-sre             SLOs, runbooks, incident response
 │
 ▼
REVIEW            /sdlc:13-review          Cross-cutting quality audit
```

---

## Phase Gates

These are hard-enforced by the orchestrator. Bypass with `--force <phase>` (reason logged to STATE.md).

| Gate | Blocks | Requires |
|------|--------|---------|
| DATA-MODEL | `tech-arch`, `plan`, `code` | `docs/data/DATA_MODEL.md` AND `docs/data/DATA_DICTIONARY.md` both exist |
| TECH-ARCH | `plan`, `code` | `TECH_ARCHITECTURE.md` AND `API_SPEC.md` AND `SOLUTION_DESIGN.md` all exist |
| PRODUCT-SPEC | `data-model`, `test-cases` | `docs/product/PRODUCT_SPEC.md` exists |
| PLAN | `code` | `.sdlc/PLAN.md` exists with tasks |
| TEST-CASES | `test-automation` | `docs/qa/TEST_CASES.md` exists |
| OBSERVABILITY | `sre` | `docs/sre/OBSERVABILITY.md` exists |

**Verification gate:** Run `/sdlc:verify --phase N` after completing each phase. The orchestrator soft-warns if you start Phase N+1 without verifying Phase N. Verification checks completeness, consistency, and cross-references — not just file existence.

**The data model is the most critical gate.** Architecture, APIs, and code all derive from it — not the other way around. Any change to an existing entity triggers automatic impact analysis.

---

## Commands

### Orchestration
| Command | Description |
|---------|-------------|
| `/sdlc:00-start <idea>` | **Always start here.** Reads state, classifies intent, enforces gates, routes to correct phase |
| `/sdlc:verify [--phase N\|--last\|--all]` | **Run after every phase.** Independent quality gate — checks completeness, consistency, and cross-references |
| `/sdlc:status` | Dashboard — phases, todos, doc health, recommended next action |
| `/sdlc:help [command]` | System guide, or detailed help for a specific command |

### Discovery
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:01-research <topic>` | `--deep` `--competitive-only` `--customer-only` | Market, competitive, and customer voice research |
| `/sdlc:02-synthesize [area]` | `--codebase-only` `--research-only` | Merge research findings with codebase analysis |

### Customer Understanding
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:01b-voc [topic]` | `--interviews` `--tickets` `--nps` `--guided` | Synthesize primary customer data into evidence-backed findings |
| `/sdlc:03b-personas [name]` | `--new` `--update` `--validate` `--anti-persona` | JTBD personas, empathy maps, anti-personas |

### Specification
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:03-product-spec <feature>` | `--new-section` `--update <section>` | Requirements, BDD scenarios, business rules, exceptions, NFRs |
| `/sdlc:04-customer-journey <persona>` | `--new-persona` `--update-flow` | Personas, journey maps, failure paths, screen flows |

### Design
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:05-data-model <domain>` | `--review` `--impact-analysis` `--new-domain` | Canonical data model — DDD, ERDs, standards validation |
| `/sdlc:06-tech-arch <system>` | `--c4` `--api-spec` `--solution-design` `--patterns` | Clean architecture, C4 diagrams, API spec, ADRs |

### Execution
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:07-plan <feature>` | `--breakdown` `--estimate` `--dependencies` | Phased execution plan + TODO list |
| `/sdlc:08-code <task>` | `--task <id>` `--layer <layer>` `--dry-run` | Implement tasks following clean architecture |
| `/sdlc:microservices <service-name>` | `--scaffold-only` `--k8s-only` `--ci-only` | Scaffold service: skeleton, Dockerfile, docker-compose, K8s manifests, CI/CD |

### Quality
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:09-test-cases <feature>` | `--layer` `--coverage-check` `--mece-check` | MECE GWT test cases with requirement traceability |
| `/sdlc:10-test-automation <feature>` | `--framework` `--layer` `--update-only` | Automation scripts mapped 1:1 to test case IDs |
| `/sdlc:13-review [area]` | `--full` `--arch` `--data` `--test` `--obs` `--code` | Cross-cutting quality audit across all artifacts |

### Reliability
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:11-observability <service>` | `--logging` `--tracing` `--metrics` `--config` `--audit` | Enterprise observability: OTel, structured logs, Prometheus |
| `/sdlc:12-sre <service>` | `--runbook` `--slo` `--incident` `--reliability-review` | SLOs, runbooks, incident response, reliability patterns |

### Maintenance
| Command | Flags | Description |
|---------|-------|-------------|
| `/sdlc:docs` | `--audit` `--index` `--clean` `--status` | Document health, audit, cleanup, index rebuild |

---

## Document Registry

These are the **only** documents created. Documents are updated — never recreated, never versioned with `_v2` suffixes.

```
docs/
  research/
    RESEARCH.md              Market landscape, competitive analysis, technology trends
    GAP_ANALYSIS.md          Customer pain points, unmet needs, ranked opportunities
    VOC.md                   Primary customer data: interview themes, ticket patterns, NPS insights
    SYNTHESIS.md             Research + codebase combined: gaps, reuse, risks

  product/
    PERSONAS.md              ⚠️  Rigorous personas (JTBD, empathy maps, anti-personas, validation)
    PRODUCT_SPEC.md          Requirements (MoSCoW), BDD, business rules, exceptions, NFRs
    CUSTOMER_JOURNEY.md      Personas, journey maps, screen flows, business processes

  data/
    DATA_MODEL.md            ⚠️  Canonical data model: bounded contexts, aggregates, ERDs
    DATA_DICTIONARY.md       Every field: type, constraints, business meaning, standard ref

  architecture/
    TECH_ARCHITECTURE.md     C4 diagrams, clean architecture layers, patterns used
    API_SPEC.md              Full OpenAPI 3.x specification
    SOLUTION_DESIGN.md       Architecture Decision Records (ADRs)

  qa/
    TEST_CASES.md            MECE Given/When/Then test cases with coverage matrix
    TEST_AUTOMATION.md       Automation index, framework guide, TC-ID coverage

  sre/
    OBSERVABILITY.md         Logging standard, tracing setup, metrics catalog, alerting
    RUNBOOKS.md              Operational runbooks for every critical procedure
    SLO.md                   Service Level Objectives and error budgets
    INCIDENT_RESPONSE.md     Severity classification, response process, post-mortem template

  review/
    REVIEW_REPORT.md         Quality review findings with severity and remediation tasks

.sdlc/
  STATE.md                   Project state, phase progress, document index, decisions
  TODO.md                    Active task list: [ ] pending, [~] in progress, [x] done
  PLAN.md                    Execution plan: phases, tasks, dependencies, risk register
  DECISIONS.md               Overflow ADRs and key decisions
```

**Sharding** is allowed when a single-domain section exceeds ~400 lines: `PRODUCT_SPEC_[DOMAIN].md`, `DATA_MODEL_[CONTEXT].md`, etc. The parent document is always the index.

**IDs are permanent.** REQ-IDs, TC-IDs, BR-IDs are never renumbered. Only deprecated (with reason and date, never deleted).

---

## Key Design Principles

### 1. Data Model First
The canonical data model is the foundation. Architecture, API shapes, and code all derive from it. Running `/sdlc:06-tech-arch` or `/sdlc:08-code` without an approved data model is blocked.

### 2. No Code Without a Plan
`/sdlc:08-code` requires `.sdlc/PLAN.md` to exist. Tasks are atomic, layered (domain → application → infrastructure → delivery), and independently verifiable.

### 3. Clean Architecture
All implementation follows the dependency rule: domain → application → infrastructure → delivery. Domain code has zero infrastructure dependencies. All external integrations go through port interfaces.

### 4. MECE Test Design
Test cases are designed from requirements, journeys, API specs, and code — not from the implementation alone. Every requirement traces to at least one test. No duplicate test cases. MECE check runs before finalizing.

### 5. Enterprise Observability Built In
Observability is designed alongside code, not bolted on after. Mandatory structured JSON logging with trace IDs, OpenTelemetry distributed tracing with W3C context propagation, and Prometheus RED metrics at every service boundary.

### 6. Documents Are Living, Not Versioned
When requirements change: update `PRODUCT_SPEC.md`. When the data model evolves: update `DATA_MODEL.md` with a change history entry. Never create parallel documents.

---

## System Structure

```
~/.claude/
  commands/sdlc/          18 slash commands (/sdlc:*)
  sdlc/
    workflows/            18 detailed workflow instruction files
    references/           6 standards reference files
    templates/            6 document starter templates
  agents/
    sdlc-researcher.md        Market and customer research
    sdlc-data-architect.md    DDD data modeling and impact analysis
    sdlc-solution-architect.md  Clean architecture and API design
    sdlc-test-designer.md     MECE test case design
    sdlc-reviewer.md          Cross-cutting quality review
```

---

## Examples

### New Project
```
/sdlc:00-start "Build a SaaS invoicing platform for freelancers"
```
Orchestrator initializes STATE.md, asks clarifying questions, then routes to research.

### New Feature on Existing Project
```
/sdlc:00-start "Add recurring invoice support"
```
Orchestrator reads existing state, identifies completed phases, routes to the correct next step.

### Check Status
```
/sdlc:status
```

### Jump to a Specific Phase (with gate check)
```
/sdlc:05-data-model "Invoice and Payment entities"
/sdlc:09-test-cases "recurring billing flow"
/sdlc:11-observability "invoice-service"
```

### Override a Gate (use with documented reason)
```
/sdlc:00-start "quick bug fix" --force plan
```

---

## Standards Encoded

| Area | Standards Applied |
|------|------------------|
| Data modeling | DDD (bounded contexts, aggregates), ISO 4217, ISO 8601, RFC 4122, E.164, domain-specific (ISO 20022, FHIR, etc.) |
| Architecture | Clean Architecture, Ports & Adapters, C4 Model, OpenAPI 3.x |
| Testing | MECE, Given/When/Then (BDD), Testing Pyramid, Contract Testing |
| Observability | OpenTelemetry, W3C TraceContext, Prometheus/OpenMetrics, structured JSON logging |
| API design | REST conventions, HTTP status codes, cursor pagination, versioning strategy |
| Reliability | RED metrics, SLOs + error budgets, Circuit Breaker, Retry + Backoff, Bulkhead |
