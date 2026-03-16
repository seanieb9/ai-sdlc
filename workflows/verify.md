# Verify Phase Workflow

Independent quality gate between SDLC phases. Inspects artifacts produced by a completed phase and confirms they are complete, internally consistent, and ready for the next phase to consume. This is not a re-run of the phase — it is an independent audit of outputs.

**Run after every phase. Never skip.**

---

## Step 1: Determine Phase(s) to Verify

- `--phase <N>` → verify Phase N only
- `--last` → read STATE.md, verify the most recently completed phase
- `--all` → verify every phase marked complete in STATE.md in sequence
- No flag → read STATE.md, find the most recently completed phase (same as `--last`)

Read `.sdlc/STATE.md` to confirm which phases are marked complete before starting.

---

## Step 2: Run Phase Verification

Read all output documents for the phase(s) in parallel, then run the checks below.

---

### Phase 1: Research

**Read:** `docs/research/RESEARCH.md`, `docs/research/GAP_ANALYSIS.md`

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

**Read:** `docs/research/VOC.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | VOC.md exists and is not empty | CRITICAL |
| 2 | Contains: themes from actual customer data (quotes or ticket patterns) | HIGH |
| 3 | Contains: prioritized pain points with evidence count | HIGH |
| 4 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 2: Synthesize

**Read:** `docs/research/SYNTHESIS.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | SYNTHESIS.md exists | CRITICAL |
| 2 | Contains: integrated findings section (not just copy of RESEARCH.md) | HIGH |
| 3 | Contains: existing codebase assessment (if codebase exists) | MEDIUM |
| 4 | Contains: recommended tech direction with justification | HIGH |
| 5 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 3: Product Spec

**Read:** `docs/product/PRODUCT_SPEC.md`

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

**Read:** `docs/product/PERSONAS.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | PERSONAS.md exists | CRITICAL |
| 2 | ≥ 1 primary persona with Jobs-to-be-Done | HIGH |
| 3 | Anti-persona section present | MEDIUM |
| 4 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 4: Customer Journey

**Read:** `docs/product/CUSTOMER_JOURNEY.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | CUSTOMER_JOURNEY.md exists | CRITICAL |
| 2 | ≥ 1 complete journey with happy path steps | HIGH |
| 3 | ≥ 1 failure path journey | HIGH |
| 4 | No `{{placeholder}}` strings | MEDIUM |

---

### Phase 5: Data Model

**Read:** `docs/data/DATA_MODEL.md`, `docs/data/DATA_DICTIONARY.md`, `docs/product/PRODUCT_SPEC.md`

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

**Cross-checks (DATA_MODEL.md → PRODUCT_SPEC.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 12 | Every core noun in PRODUCT_SPEC.md requirements has a corresponding entity or value object | HIGH |
| 13 | Every entity lifecycle state (if any) maps to a business state in PRODUCT_SPEC.md | MEDIUM |

---

### Phase 6: Tech Architecture

**Read:** `docs/architecture/TECH_ARCHITECTURE.md`, `docs/architecture/API_SPEC.md`, `docs/architecture/SOLUTION_DESIGN.md`, `docs/data/DATA_MODEL.md`, `docs/product/PRODUCT_SPEC.md`

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

**Cross-checks (TECH_ARCHITECTURE.md → DATA_MODEL.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 16 | Every entity in DATA_MODEL.md is referenced in component design | MEDIUM |
| 17 | Every entity's DB table/collection is mapped to a repository component | MEDIUM |

**Cross-checks (TECH_ARCHITECTURE.md → PRODUCT_SPEC.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 18 | Every NFR from PRODUCT_SPEC.md appears in the NFR coverage section | HIGH |
| 19 | Every external service referenced in requirements is in the dependency classification table | HIGH |

---

### Phase 7: Plan

**Read:** `.sdlc/PLAN.md`, `.sdlc/TODO.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | PLAN.md exists | CRITICAL |
| 2 | TODO.md exists with ≥ 1 unchecked task | HIGH |
| 3 | Tasks follow layer order: domain → application → infrastructure → delivery | MEDIUM |
| 4 | Every task has a priority (P0 / P1 / P2) | MEDIUM |
| 5 | No task is overly vague (no tasks like "implement the feature") | MEDIUM |
| 6 | All P0 tasks are in the first phase | MEDIUM |

---

### Phase 8: Code

**Read:** Source files in `src/`, cross-reference with `.sdlc/TODO.md`, `docs/architecture/TECH_ARCHITECTURE.md`, `docs/data/DATA_MODEL.md`

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
| 9 | All P0 TODO items are marked complete | HIGH |

**Cross-checks:**
| # | Check | Severity if fails |
|---|-------|------------------|
| 10 | Every entity in DATA_MODEL.md has a corresponding domain class | HIGH |
| 11 | Every API endpoint in API_SPEC.md has a corresponding controller method | HIGH |
| 12 | Every port interface in TECH_ARCHITECTURE.md has an implementation | MEDIUM |

---

### Phase 9: Test Cases

**Read:** `docs/qa/TEST_CASES.md`, `docs/product/PRODUCT_SPEC.md`, `docs/architecture/API_SPEC.md`, `docs/architecture/TECH_ARCHITECTURE.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | TEST_CASES.md exists | CRITICAL |
| 2 | Coverage matrix section present | HIGH |
| 3 | Test cases for all 8 layers present: Unit, Integration, Contract, E2E, Performance, Resilience, Observability, Security | HIGH |
| 4 | No TC-ID in coverage matrix without a corresponding written test case | HIGH |
| 5 | No duplicate TC-IDs | HIGH |
| 6 | No `{{placeholder}}` strings | MEDIUM |

**Cross-checks (TEST_CASES.md → PRODUCT_SPEC.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 7 | Every REQ-ID from PRODUCT_SPEC.md appears in coverage matrix | HIGH |
| 8 | Every BR-ID from PRODUCT_SPEC.md has a unit test case | HIGH |
| 9 | Every NFR with a numeric threshold has a performance test case | HIGH |

**Cross-checks (TEST_CASES.md → API_SPEC.md):**
| # | Check | Severity if fails |
|---|-------|------------------|
| 10 | Every API endpoint has ≥ 1 contract test case | HIGH |
| 11 | Each contract test covers the 401 (unauth) case | HIGH |

**Cross-checks (TEST_CASES.md → TECH_ARCHITECTURE.md):**
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

**Read:** `docs/qa/TEST_AUTOMATION.md`, `docs/qa/TEST_CASES.md`, test files in `tests/`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | TEST_AUTOMATION.md exists | CRITICAL |
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

**Read:** `docs/sre/OBSERVABILITY.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | OBSERVABILITY.md exists | CRITICAL |
| 2 | Structured logging spec present (mandatory fields listed) | HIGH |
| 3 | trace_id and span_id listed as mandatory log fields | HIGH |
| 4 | Trace propagation spec: W3C TraceContext header named | HIGH |
| 5 | RED metrics defined per endpoint (rate, errors, duration) | HIGH |
| 6 | OBS-IDs assigned to logging, tracing, and metric commitments | MEDIUM |
| 7 | Health endpoint response shape documented | MEDIUM |
| 8 | No PII fields listed in any log line example | HIGH |

---

### Phase 12: SRE

**Read:** `docs/sre/RUNBOOKS.md`, `docs/sre/OBSERVABILITY.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | RUNBOOKS.md exists | CRITICAL |
| 2 | ≥ 1 runbook per CRITICAL dependency failure scenario | HIGH |
| 3 | SLO targets defined (availability % and latency p95 target) | HIGH |
| 4 | Alert → runbook mapping documented | HIGH |
| 5 | Incident severity classification table present | MEDIUM |

---

### Phase 13: Review

**Read:** `docs/review/REVIEW_REPORT.md`, `.sdlc/TODO.md`

| # | Check | Severity if fails |
|---|-------|------------------|
| 1 | REVIEW_REPORT.md exists | CRITICAL |
| 2 | Summary section has counts (Critical / High / Medium / Low) | HIGH |
| 3 | Every HIGH finding has a TASK-NNN in TODO.md | HIGH |
| 4 | Every CRITICAL finding has a TASK-NNN in TODO.md | CRITICAL |
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

## Step 5: Update STATE.md

Append to the `## Verification Log` section of STATE.md:

```
[date] VERIFY Phase [N] ([name]): [PASS | PASS WITH WARNINGS | FAIL] — [N failures, N warnings]
  Failures: [list or "none"]
  Warnings: [list or "none"]
```

If FAIL: update the phase status back to 🔄 In Progress in STATE.md.

If the `## Verification Log` section does not exist in STATE.md, add it.

---

## Step 6: Update ROADMAP.md Phase Log

If `.sdlc/ROADMAP.md` exists, update the Phase Log row for the verified phase:

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
