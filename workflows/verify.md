# Verify Phase Workflow

Independent quality gate between SDLC phases. Inspects artifacts produced by a completed phase and confirms they are complete, internally consistent, and ready for the next phase to consume. This is not a re-run of the phase — it is an independent audit of outputs.

**Run after every phase. Never skip.**

---

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

## Step 1: Determine Phase(s) to Verify

- `--phase <N>` → verify Phase N only
- `--last` → read $STATE, verify the most recently completed phase
- `--all` → verify every phase marked complete in $STATE in sequence
- No flag → read $STATE, find the most recently completed phase (same as `--last`)

Read `$STATE` to confirm which phases are marked complete before starting.

---

## Step 2: Run Phase Verification

Read all output documents for the phase(s) in parallel, then run the checks below.

---

### Phase 1: Research

**Read:** `$ARTIFACTS/research/research.md`, `$ARTIFACTS/research/gap-analysis.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | RESEARCH.md exists and is not empty | CRITICAL |
| 2 | Contains: Market Landscape section | HIGH |
| 3 | Contains: Competitive Analysis section (≥ 2 named competitors) | HIGH |
| 4 | Contains: Best Practices section | MEDIUM |
| 5 | Contains: Emerging trends or technology signals section | MEDIUM |
| 6 | GAP_ANALYSIS.md exists with ≥ 1 identified gap | HIGH |
| 7 | No `{{placeholder}}`, `[TBD]`, or `[TODO]` strings remaining | MEDIUM |
| 8 | Competitors include feature comparison (table or list) not just names | MEDIUM |

---

### Phase 1b: Voice of Customer

**Read:** `$ARTIFACTS/research/voc.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | VOC.md exists and is not empty | CRITICAL |
| 2 | Contains: themes from actual customer data (quotes or ticket patterns) | HIGH |
| 3 | Contains: prioritized pain points with evidence count | HIGH |
| 4 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 2: Synthesize

**Read:** `$ARTIFACTS/research/synthesis.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | SYNTHESIS.md exists | CRITICAL |
| 2 | Contains: integrated findings section (not just copy of RESEARCH.md) | HIGH |
| 3 | Contains: existing codebase assessment (if codebase exists) | MEDIUM |
| 4 | Contains: recommended tech direction with justification | HIGH |
| 5 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 3: Product Spec

**Read:** `$ARTIFACTS/idea/prd.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | PRODUCT_SPEC.md exists | CRITICAL |
| 2 | ≥ 3 requirements with REQ-XXX IDs | HIGH |
| 3 | ≥ 1 business rule with BR-XXX ID | HIGH |
| 4 | ≥ 1 NFR with a numeric threshold (ms, rps, %, not just words) | HIGH |
| 5 | Error handling table present (≥ 3 error codes with HTTP status) | HIGH |
| 6 | BDD scenarios (Given/When/Then) present for primary use case | HIGH |
| 7 | No `{{placeholder}}` or `[TBD]` strings | MEDIUM |
| 8 | No two REQ-IDs with identical business meaning (duplicate check) | MEDIUM |
| 9 | Exception handling section covers: not found, unauthorized, validation failure | MEDIUM |

---

### Phase 3b: Personas

**Read:** `$ARTIFACTS/personas/personas.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | PERSONAS.md exists | CRITICAL |
| 2 | ≥ 1 primary persona with Jobs-to-be-Done | HIGH |
| 3 | Anti-persona section present | MEDIUM |
| 4 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 4: Customer Journey

**Read:** `$ARTIFACTS/journey/customer-journey.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | CUSTOMER_JOURNEY.md exists | CRITICAL |
| 2 | ≥ 1 complete journey with happy path steps | HIGH |
| 3 | ≥ 1 failure path journey | HIGH |
| 4 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 4b: Business Process (only if business-process.md exists)

**Read:** `$ARTIFACTS/business-process/business-process.md`, `$ARTIFACTS/journey/customer-journey.md`, `$ARTIFACTS/idea/prd.md`

If business-process.md does not exist (Phase 4b was skipped): skip this check entirely (silent pass).

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | BUSINESS_PROCESS.md exists and is not empty | CRITICAL |
| 2 | Process inventory table present with BP-IDs | HIGH |
| 3 | ≥ 1 process has a swimlane/sequence diagram or step list | HIGH |
| 4 | Every process defines a Process Owner | HIGH |
| 5 | Every process defines an SLA | HIGH |
| 6 | Every human-in-loop process has an SLA breach action | HIGH |
| 7 | Every process has ≥ 1 exception path documented | HIGH |
| 8 | Every exception path states who is notified | MEDIUM |
| 9 | `## Data Model Implications Summary` section present | HIGH |
| 10 | No `{{placeholder}}` or `[TBD]` strings | MEDIUM |

**Cross-checks (business-process.md → customer-journey.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 11 | Every process named in customer-journey.md `## Business Processes` section has a BP-ID in business-process.md | HIGH |

**Cross-checks (business-process.md → prd.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 12 | Every BR-ID that implies a multi-step approval or compliance process is linked to a BP-ID | MEDIUM |

---

### Phase 5: Data Model

**Read:** `$ARTIFACTS/data-model/data-model.md`, `$ARTIFACTS/data-model/data-dictionary.md`, `$ARTIFACTS/idea/prd.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | DATA_MODEL.md exists | CRITICAL |
| 2 | DATA_DICTIONARY.md exists and is not empty | HIGH |
| 3 | ≥ 1 bounded context defined | HIGH |
| 4 | ≥ 1 entity with a Mermaid ERD diagram | HIGH |
| 5 | Every entity has: id (UUID PK), created_at, updated_at | HIGH |
| 6 | Every entity has ≥ 1 invariant documented | HIGH |
| 7 | Domain events section present (can be empty, but must be stated explicitly) | MEDIUM |
| 8 | DATA_DICTIONARY.md has an entry for every entity in DATA_MODEL.md | HIGH |
| 9 | Every DATA_DICTIONARY.md field has: Type, Nullable, Business Meaning columns | MEDIUM |
| 10 | No circular aggregate dependencies | HIGH |
| 11 | No `{{placeholder}}` strings | MEDIUM |

**Cross-checks (data-model.md → prd.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 12 | Every core noun in prd.md requirements has a corresponding entity or value object | HIGH |
| 13 | Every entity lifecycle state (if any) maps to a business state in prd.md | MEDIUM |

---

### Phase 6: Tech Architecture

**Read:** `$ARTIFACTS/design/tech-architecture.md`, `$ARTIFACTS/design/api-spec.md`, `$ARTIFACTS/design/solution-design.md`, `$ARTIFACTS/data-model/data-model.md`, `$ARTIFACTS/idea/prd.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | TECH_ARCHITECTURE.md exists | CRITICAL |
| 2 | API_SPEC.md exists | CRITICAL |
| 3 | SOLUTION_DESIGN.md exists | CRITICAL |
| 4 | Deployment topology decision documented (monolith / microservices / hybrid) | HIGH |
| 5 | Clean architecture layers documented (domain / app / infra / delivery) | HIGH |
| 6 | Security section present: auth strategy AND authz model named | HIGH |
| 7 | Dependency classification table present (CRITICAL/DEGRADABLE/OPTIONAL) | HIGH |
| 8 | Every classified dependency has timeout and fallback documented | HIGH |
| 9 | `/health/live` and `/health/ready` endpoints defined | HIGH |
| 10 | SOLUTION_DESIGN.md has ≥ 3 ADRs with Context + Decision + Rationale + Consequences | HIGH |
| 11 | ADR-001 covers the topology decision | HIGH |
| 12 | API_SPEC.md has ≥ 1 endpoint per primary use case in PRODUCT_SPEC.md | HIGH |
| 13 | Every API endpoint documents authentication requirement | HIGH |
| 14 | Every API endpoint documents all response status codes | MEDIUM |
| 15 | No `{{placeholder}}` strings | MEDIUM |

**Cross-checks (tech-architecture.md → data-model.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 16 | Every entity in data-model.md is referenced in component design | MEDIUM |
| 17 | Every entity's DB table/collection is mapped to a repository component | MEDIUM |

**Cross-checks (tech-architecture.md → prd.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 18 | Every NFR from prd.md appears in the NFR coverage section | HIGH |
| 19 | Every external service referenced in requirements is in the dependency classification table | HIGH |

---

### Phase 7: Plan

**Read:** `$ARTIFACTS/plan/implementation-plan.md`, tasks from `$STATE`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | implementation-plan.md exists | CRITICAL |
| 2 | $STATE has ≥ 1 task with status "pending" | HIGH |
| 3 | Tasks follow layer order: domain → application → infrastructure → delivery | MEDIUM |
| 4 | Every task has a priority (P0 / P1 / P2) | MEDIUM |
| 5 | No task is overly vague (no tasks like "implement the feature") | MEDIUM |
| 6 | All P0 tasks are in the first phase | MEDIUM |

---

### Phase 8: Code

**Read:** Source files in `src/`, cross-reference with tasks in `$STATE`, `$ARTIFACTS/design/tech-architecture.md`, `$ARTIFACTS/data-model/data-model.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | `src/domain/` directory exists with entity files | HIGH |
| 2 | `src/application/` directory exists with use case files | HIGH |
| 3 | `src/infrastructure/` directory exists | HIGH |
| 4 | `src/delivery/` directory exists | HIGH |
| 5 | No import from infrastructure packages in domain files (grep check) | HIGH |
| 6 | No raw DB client calls in use case files | HIGH |
| 7 | Health endpoint handler exists | HIGH |
| 8 | SIGTERM handler exists | HIGH |
| 9 | All P0 tasks in $STATE are marked "done" | HIGH |

**Cross-checks:**
| # | Check | Severity if fails |
|---|-------|------------------|
| 10 | Every entity in data-model.md has a corresponding domain class | HIGH |
| 11 | Every API endpoint in api-spec.md has a corresponding controller method | HIGH |
| 12 | Every port interface in TECH_ARCHITECTURE.md has an implementation | MEDIUM |

---

### Engineering Verification Checklist

These gates enforce engineering rigor at the transition into and out of Phase 8 (Build). They are checked automatically as part of Phase 7 and Phase 8 verification.

---

#### Pre-Build Gate (verified as part of Phase 7 verification — before Phase 8 starts)

Before starting implementation, verify:
- [ ] Implementation plan exists and has tasks defined
- [ ] All tasks have clear done criteria
- [ ] Architecture decisions (ADRs) are documented
- [ ] API contracts are specified (OpenAPI spec exists)
- [ ] Data model is finalized (no pending breaking changes)
- [ ] Test strategy is defined (which layers, which frameworks)
- [ ] Development environment setup is documented

| # | Check | Severity if fails |
|---|-------|------------------|
| E1 | Implementation plan has ≥ 1 task with done criteria | HIGH |
| E2 | ≥ 1 ADR documented in SOLUTION_DESIGN.md | HIGH |
| E3 | API_SPEC.md exists and is not empty | HIGH |
| E4 | DATA_MODEL.md is finalized (no `[TBD]` in entity definitions) | HIGH |
| E5 | Test strategy section present in TECH_ARCHITECTURE.md or a separate test-strategy document | MEDIUM |
| E6 | Development environment setup steps documented in README or equivalent | MEDIUM |

---

#### Post-Build Gate (verified as part of Phase 8 verification — before Phase 9 starts)

After implementation, verify:

**Code Quality:**
- [ ] Lint: 0 errors (run lint command from config)
- [ ] Types: 0 type errors
- [ ] Format: all files pass format check
- [ ] Complexity: no function exceeds cyclomatic complexity 10

**Testing:**
- [ ] Unit test coverage >= [threshold from config] for domain/application layers
- [ ] All new business logic has unit tests
- [ ] All new API endpoints have integration tests
- [ ] No tests are skipped/commented out without explanation

**Security:**
- [ ] Dependency scan: 0 CRITICAL, 0 HIGH vulnerabilities
- [ ] Secrets scan: 0 secrets detected
- [ ] OWASP API Top 10: each applicable item has documented mitigation

**Architecture:**
- [ ] Dependency rule respected (no domain → infrastructure imports)
- [ ] New code follows the patterns established in ADRs
- [ ] No direct database access from delivery layer
- [ ] No business logic in delivery layer (thin controllers only)

| # | Check | Severity if fails |
|---|-------|------------------|
| E7 | Lint command exits 0 (0 errors) | HIGH |
| E8 | Type check command exits 0 (0 type errors) | HIGH |
| E9 | No domain file imports from infrastructure packages | HIGH |
| E10 | No raw DB client calls in use case files | HIGH |
| E11 | No business logic in delivery layer controllers | HIGH |
| E12 | Dependency vulnerability scan: 0 CRITICAL findings | HIGH |
| E13 | Secrets scan: 0 secrets detected in committed files | CRITICAL |
| E14 | No tests skipped (`xit`, `it.skip`, `@Disabled`) without explanation comment | MEDIUM |
| E15 | Unit test coverage for domain/application layer meets or exceeds configured threshold | HIGH |

If any item FAILS: mark verification as FAILED, list the failures, block advancement to next phase.

---

### Phase 9: Test Cases

**Read:** `$ARTIFACTS/test-cases/test-cases.md`, `$ARTIFACTS/idea/prd.md`, `$ARTIFACTS/design/api-spec.md`, `$ARTIFACTS/design/tech-architecture.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | test-cases.md exists | CRITICAL |
| 2 | Coverage matrix section present | HIGH |
| 3 | Test cases for all 8 layers present: Unit, Integration, Contract, E2E, Performance, Resilience, Observability, Security | HIGH |
| 4 | No TC-ID in coverage matrix without a corresponding written test case | HIGH |
| 5 | No duplicate TC-IDs | HIGH |
| 6 | No `{{placeholder}}` strings | MEDIUM |

**Cross-checks (test-cases.md → prd.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 7 | Every REQ-ID from prd.md appears in coverage matrix | HIGH |
| 8 | Every BR-ID from prd.md has a unit test case | HIGH |
| 9 | Every NFR with a numeric threshold has a performance test case | HIGH |

**Cross-checks (test-cases.md → api-spec.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 10 | Every API endpoint has ≥ 1 contract test case | HIGH |
| 11 | Each contract test covers the 401 (unauth) case | HIGH |

**Cross-checks (test-cases.md → tech-architecture.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 12 | Every CRITICAL dependency has a resilience test (circuit open + 503 response) | HIGH |
| 13 | Every DEGRADABLE dependency has a resilience test (fallback returned) | HIGH |
| 14 | Every ADR has a corresponding integration or resilience test | MEDIUM |

---

### Phase 6b: FE Setup (only if TECH_ARCHITECTURE.md has a ## Frontend Architecture section)

**Read:** `docs/frontend/DESIGN_TOKENS.md`, `docs/frontend/COMPONENT_LIBRARY.md`, `docs/frontend/SCREEN_SPEC.md`

If FE stack not present in TECH_ARCHITECTURE.md: skip this check entirely (silent pass).

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | DESIGN_TOKENS.md exists | CRITICAL |
| 2 | All token categories present: color, typography, spacing, radius, shadow, motion | HIGH |
| 3 | Primary palette has 12 steps defined | HIGH |
| 4 | Semantic colors defined (success/warning/error/info) | HIGH |
| 5 | Interactive base color contrast ≥ 4.5:1 on background | HIGH |
| 6 | Component base library documented with version | HIGH |
| 7 | SCREEN_SPEC.md exists | CRITICAL |
| 8 | Screen inventory table present with ≥ 1 screen | HIGH |
| 9 | Every screen in inventory has a corresponding screen section | HIGH |
| 10 | Every screen section defines all 4 states (loading/empty/error/success) | MEDIUM |
| 11 | Every screen section has data requirements mapped to API_SPEC.md endpoints | HIGH |
| 12 | Shared component registry present | MEDIUM |

**Cross-checks (SCREEN_SPEC.md → CUSTOMER_JOURNEY.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 13 | Every journey step that involves user interaction maps to ≥ 1 screen in SCREEN_SPEC.md | HIGH |

---

### Phase 10: Test Automation

**Read:** `$ARTIFACTS/test-gen/test-automation.md`, `$ARTIFACTS/test-cases/test-cases.md`, test files in `tests/`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | test-automation.md exists | CRITICAL |
| 2 | TC-ID to automation file mapping table present | HIGH |
| 3 | Coverage gates documented | HIGH |
| 4 | Drift detection rules documented | MEDIUM |

**Cross-checks (automation files → TEST_CASES.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 5 | Every P0 TC-ID has an automation file reference | HIGH |
| 6 | No automation file has a test with no TC-ID comment | MEDIUM |
| 7 | `tests/performance/` directory has ≥ 1 k6 script per NFR | HIGH |
| 8 | `tests/resilience/` directory has ≥ 1 test per CRITICAL dependency | HIGH |

---

### Phase 11: Observability

**Read:** `$ARTIFACTS/observability/observability.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | observability.md exists | CRITICAL |
| 2 | Structured logging spec present (mandatory fields listed) | HIGH |
| 3 | trace_id and span_id listed as mandatory log fields | HIGH |
| 4 | Trace propagation spec: W3C TraceContext header named | HIGH |
| 5 | RED metrics defined per endpoint (rate, errors, duration) | HIGH |
| 6 | OBS-IDs assigned to logging, tracing, and metric commitments | MEDIUM |
| 7 | Health endpoint response shape documented | MEDIUM |
| 8 | No PII fields listed in any log line example | HIGH |

---

### Phase 12: SRE

**Read:** `$ARTIFACTS/sre/runbooks.md`, `$ARTIFACTS/observability/observability.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | runbooks.md exists | CRITICAL |
| 2 | ≥ 1 runbook per CRITICAL dependency failure scenario | HIGH |
| 3 | SLO targets defined (availability % and latency p95 target) | HIGH |
| 4 | Alert → runbook mapping documented | HIGH |
| 5 | Incident severity classification table present | MEDIUM |

---

### Phase 13: Review

**Read:** `$ARTIFACTS/review/review-report.md`, tasks from `$STATE`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | review-report.md exists | CRITICAL |
| 2 | Summary section has counts (Critical / High / Medium / Low) | HIGH |
| 3 | Every HIGH finding has a TASK-NNN in $STATE tasks | HIGH |
| 4 | Every CRITICAL finding has a TASK-NNN in $STATE tasks | CRITICAL |
| 5 | No open CRITICAL findings (must be resolved or accepted before sign-off) | CRITICAL |
| 6 | All 8 review dimensions were checked (not just code quality) | HIGH |

---

## Step 3: Evaluate Results

For each check that fails, classify:
- **CRITICAL** → phase fails verification, next phase MUST NOT start
- **HIGH** → phase fails verification, next phase should not start without explicit override
- **MEDIUM** → phase passes with warning, document in STATE.md, next phase can proceed
- **LOW** → phase passes, note for improvement

**Pass conditions:**
- ✅ PASS: Zero CRITICAL or HIGH failures
- ⚠️ PASS WITH WARNINGS: Zero CRITICAL/HIGH failures, one or more MEDIUM failures
- ❌ FAIL: One or more CRITICAL or HIGH failures

---

## Step 4: Write Verification Output

Print the verification result:

```
PHASE [N] VERIFICATION: [Phase Name]
Date: [date]
Status: ✅ PASS | ⚠️ PASS WITH WARNINGS | ❌ FAIL

Checks:  [N passed] / [N total]

Failures (must fix before proceeding):
  ❌ [Check description] → Severity: [CRITICAL/HIGH] → Fix: [Exact action]

Warnings (can proceed, but address soon):
  ⚠️ [Check description] → Severity: MEDIUM → Fix: [Exact action]

Gate: UNLOCKED — proceed to Phase [N+1] | LOCKED — fix failures first
```

If `--all` flag: show one block per phase, then a final summary.

---

## Step 5: Update $STATE

Append to the `verification_log` array in $STATE:

```json
{"date": "[date]", "phase": [N], "phase_name": "[name]", "result": "PASS | PASS WITH WARNINGS | FAIL", "failures": [], "warnings": []}
```

If FAIL: update the phase status back to "in_progress" in $STATE.

---

## Step 6: Update ROADMAP.md Phase Log

If a ROADMAP.md exists in the project root or `.sdlc/ROADMAP.md`, update the Phase Log row for the verified phase:

**On PASS or PASS WITH WARNINGS:**
Find the matching row in the `## Phase Log` table and update:
```
| [N]. [Phase name] | ✅ Complete | [sessions used if known, else "—"] | [ISO date] | [one-line note if warnings] |
```

**On FAIL:**
```
| [N]. [Phase name] | 🔄 In Progress | — | — | Verify failed — [top failure reason] |
```

**Sessions used:** if the user mentioned how many sessions this phase took during the work, record it. Otherwise leave `—`. The roadmap estimate vs actual comparison is valuable over time but never block on it.

If ROADMAP.md does not exist (solo developer skipped roadmap): skip this step silently.
