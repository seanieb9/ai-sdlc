# Review Workflow

Run a holistic quality review across all SDLC artifacts. Surface gaps, violations, and remediation actions. Be thorough and specific — vague findings are useless.

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

## Step 1: Load All Artifacts

Read in parallel (read everything relevant):
- All files under $ARTIFACTS/idea/, $ARTIFACTS/research/, $ARTIFACTS/journey/
- All files under $ARTIFACTS/data-model/, $ARTIFACTS/design/
- All files under $ARTIFACTS/test-cases/, $ARTIFACTS/test-gen/
- All files under $ARTIFACTS/observability/, $ARTIFACTS/sre/
- $STATE (JSON — tasks, phases, decisions)
- $ARTIFACTS/plan/implementation-plan.md
- Relevant source code (spot-check critical paths)
- Recent git changes (if git repo: `git log --oneline -20` and `git diff HEAD~5`)

## Step 2: Requirements Traceability Review

**Check 1: Requirement → Test coverage**
- List all requirement IDs from PRODUCT_SPEC.md
- List all REQ references in TEST_CASES.md
- Flag: any requirement with no test case → FINDING: GAP

**Check 2: Test → Requirement linkage**
- List all test cases in TEST_CASES.md
- Flag: any test case with no requirement reference → FINDING: ORPHANED

**Check 3: Test → Automation coverage**
- All P0 tests should have automation scripts
- Flag: P0 tests with no automation → FINDING: GAP

Severity: HIGH for P0 gaps, MEDIUM for P1 gaps, LOW for P2 gaps

## Step 3: Data Model Integrity Review

**Check: Entity completeness**
- Every entity has id, created_at, updated_at → flag missing
- Every entity in DATA_MODEL.md has DATA_DICTIONARY entries → flag missing

**Check: Consistency**
- Fields referenced in API_SPEC.md match DATA_MODEL.md field names/types
- Fields referenced in TEST_CASES.md match DATA_MODEL.md
- No entity in code/schema that isn't in DATA_MODEL.md

**Check: Invariants**
- Each invariant in DATA_MODEL.md has a corresponding unit test in TEST_CASES.md

Severity: HIGH for type mismatches/missing entities, MEDIUM for dictionary gaps

## Step 4: Architecture Compliance Review

**Check: Clean Architecture dependency rule**
- Scan imports/requires in domain layer files → flag any infrastructure imports
- Scan imports/requires in application layer → flag any infrastructure imports
- Pattern: look for DB clients, HTTP clients, framework-specific code in domain/application

**Check: Port/Adapter pattern**
- Every external integration should go through an interface in application layer
- Flag: direct instantiation of infrastructure in use cases

**Check: Single Responsibility**
- Flag: classes/modules with more than one reason to change
- Flag: files > 300 lines (likely violating SRP)
- Flag: methods/functions > 30 lines (likely doing too much)

**Check: Pattern correctness**
- Repository pattern: no raw DB queries in use cases
- Factory pattern: complex object creation not in constructors
- No anti-patterns: God objects, service locator, anemic domain model

Severity: HIGH for dependency rule violations, MEDIUM for SRP violations

## Step 5: Test Coverage Review

**Check: Coverage gates**
- Run or check existing coverage report
- Flag: critical paths below 90% line coverage
- Flag: error handling paths below 80% branch coverage

**Check: MECE**
- Identify test cases with identical Given/When/Then → flag as duplicates
- Identify requirements with no corresponding tests → flag as gaps
- Check: are boundary conditions tested? (min/max values, null/empty, concurrent)

**Check: Test quality**
- Tests with no assertions → flag
- Tests that test implementation details (not behavior) → flag
- Tests that depend on other tests → flag (test isolation violation)

Severity: HIGH for gaps on critical paths, MEDIUM for duplicates, LOW for style issues

## Accessibility Review (WCAG 2.1 AA)

Read from $STATE projectAssumptions.accessibility. If "not-applicable", skip this section and note skipped.

For each UI component/screen in the deliverable:
- [ ] All images have descriptive alt text (or empty alt="" if decorative)
- [ ] All interactive elements are keyboard-accessible (Tab, Enter, Space, Arrow keys)
- [ ] All interactive elements have accessible names (aria-label or visible label)
- [ ] Color is not the only means of conveying information
- [ ] Text contrast ratio meets 4.5:1 (normal) / 3:1 (large text) — use browser devtools
- [ ] All form inputs have associated <label> elements
- [ ] Error messages are programmatically associated with their input (aria-describedby)
- [ ] Modal dialogs trap focus and restore on close
- [ ] Page has a skip-to-main-content link
- [ ] Document language is set (lang attribute on <html>)
- [ ] Reading order makes sense without CSS (test by disabling CSS)
- [ ] All videos have captions (if applicable)
- [ ] No content flashes more than 3 times/second

Automated check: run axe-core or Lighthouse a11y audit. Score must be >= 90 for wcag-aa.

Findings classified as: CRITICAL (blocks user access) / HIGH (degrades experience) / MEDIUM / LOW

---

## Performance Review

- [ ] Key API endpoint response times measured and documented (p50, p95, p99)
- [ ] Database query explain plans reviewed for queries touching > 10k rows
- [ ] No N+1 queries detected (use query logging to verify)
- [ ] Large payload responses paginated (no endpoint returning > 100 records unbounded)
- [ ] Images optimized (next/image, lazy loading, appropriate format)
- [ ] JavaScript bundle size measured (if web app) — document and compare to previous
- [ ] Memory usage stable under sustained load (no memory leaks in profiling)
- [ ] Startup time acceptable (record time-to-ready from health check)

For each NFR with a latency/throughput target (from product spec):
| NFR | Target | Measured | Pass/Fail |
|-----|--------|----------|-----------|
| [e.g., API p95] | < 200ms | [measured] | ✅/❌ |

---

## Security Review

### Authentication & Authorization
- [ ] All non-public endpoints require authentication
- [ ] Authorization checked at use-case level (not just middleware)
- [ ] JWT tokens expire and refresh correctly
- [ ] No sensitive data in JWT payload (no passwords, full card numbers)
- [ ] Refresh token rotation implemented (old token invalidated on refresh)

### Input Handling
- [ ] All user input validated at delivery layer (schema + type)
- [ ] No SQL injection risk: all DB queries use parameterized statements / ORM
- [ ] No XSS risk: all HTML output escaped, Content-Security-Policy header set
- [ ] File uploads: type validated, size limited, virus-scanned, stored outside web root
- [ ] URL parameters validated before use in queries or file paths

### HTTP Security Headers
- [ ] Strict-Transport-Security (HSTS)
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY or SAMEORIGIN
- [ ] Content-Security-Policy defined (not just "unsafe-inline")
- [ ] Referrer-Policy: strict-origin-when-cross-origin
- [ ] Permissions-Policy configured

### Secrets & Configuration
- [ ] No secrets in source code, config files, or logs
- [ ] All secrets loaded from environment variables or vault
- [ ] .env file in .gitignore
- [ ] Secrets scanning (gitleaks) shows no findings

### API Security
- [ ] Rate limiting on all public endpoints (stricter on auth endpoints)
- [ ] CORS configured with explicit allowlist (no wildcard * for credentialed requests)
- [ ] Error responses don't leak stack traces or internal details to callers
- [ ] API versioning in place (existing consumers won't break on API changes)

### Dependency Security
- [ ] npm audit / pip-audit / govulncheck: 0 CRITICAL, 0 HIGH vulnerabilities
- [ ] No dependencies with GPL license used in commercial product without legal review
- [ ] All direct dependencies pinned to specific versions in lock file

---

## ADR Review

For each ADR in $ARTIFACTS/design/solution-design.md:
- [ ] ADR status is "Accepted" (not "Proposed" or "Deprecated")
- [ ] ADR consequences are reflected in the implementation
- [ ] Any ADRs marked for review trigger (from their "Review trigger" field) — check if those conditions have been reached
- [ ] New patterns used in code but not in ADRs → create new ADRs before sign-off

---

## Operations Readiness Review

- [ ] All runbooks in $ARTIFACTS/sre/runbooks.md cover this new feature's failure modes
- [ ] SLO targets are achievable based on measured performance
- [ ] Health check endpoints (/health/live, /health/ready) updated if new dependencies added
- [ ] Monitoring dashboards updated to include new service/feature metrics
- [ ] On-call team briefed on new feature's failure modes (if team with on-call)
- [ ] Database backup verified: new tables/data included in backup scope
- [ ] Rollback procedure tested or verified in staging

---

## Step 6: Observability Review

**Check: Logging**
- Scan code for log statements
- Flag: any log statement missing trace_id/correlation_id
- Flag: any log with hardcoded PII patterns (email regex, SSN pattern, etc.)
- Flag: any error swallowed without logging

**Check: Tracing**
- All use case boundaries have custom spans
- All external calls are wrapped in spans
- Trace context propagated in all outbound HTTP calls

**Check: Metrics**
- All endpoints have RED metrics
- All critical business operations have business metrics

**Check: Health endpoints**
- /health/live, /health/ready exist and return correct shapes

Severity: HIGH for missing traces on critical paths, MEDIUM for incomplete metrics

## Step 7: Resilience Review

**Check: Dependency classification**
- Scan TECH_ARCHITECTURE.md — every external dependency should have a CRITICAL/DEGRADABLE/OPTIONAL classification
- Flag: any dependency with no classification → FINDING: HIGH

**Check: Timeouts**
- Grep for HTTP client instantiation, DB client config, queue client config
- Flag: any client with no explicit connectTimeout AND readTimeout set → FINDING: HIGH
- Flag: any DB query with no queryTimeout → FINDING: HIGH

**Check: Circuit breakers**
- Grep for circuit breaker usage patterns
- Cross-reference with dependency list from TECH_ARCHITECTURE.md
- Flag: any CRITICAL or DEGRADABLE dependency with no circuit breaker → FINDING: HIGH
- Flag: circuit breaker wrapping retry (correct) vs retry wrapping circuit breaker (wrong) → FINDING: HIGH if wrong

**Check: Retry logic**
- Grep for retry implementations
- Flag: retry applied to non-idempotent POST operations without idempotency key → FINDING: HIGH
- Flag: no jitter on backoff delays → FINDING: MEDIUM
- Flag: unlimited or excessive max retry attempts → FINDING: MEDIUM

**Check: Bulkhead / connection pool**
- Grep for DB pool configuration
- Flag: no acquireTimeout on DB pool (pool exhaustion will hang) → FINDING: HIGH
- Flag: no maxConnections set → FINDING: MEDIUM

**Check: Graceful degradation**
- For every DEGRADABLE dependency: verify a fallback value is returned on failure (not an error propagated)
- Flag: DEGRADABLE dependency with no fallback — failure propagates to caller → FINDING: HIGH

**Check: Graceful shutdown**
- Grep for SIGTERM handler
- Flag: no SIGTERM handler → FINDING: HIGH
- Flag: SIGTERM handler that does not close DB pool or broker connections → FINDING: MEDIUM
- Flag: force-exit timeout is >= terminationGracePeriodSeconds → FINDING: HIGH (pod will be killed mid-drain)

**Check: Load shedding**
- Grep for load shedder / queue depth middleware
- Flag: no load shedding under high concurrency → FINDING: MEDIUM

Severity guide: missing circuit breaker or timeout = HIGH, missing degradation fallback = HIGH, missing jitter = MEDIUM, missing load shedding = MEDIUM

---

## Step 8: Deployment Readiness Review

**Check: Health endpoints**
- Verify `/health/live`, `/health/ready`, `/health/startup` are implemented
- Verify `/health/ready` actually checks DB connection and critical dependencies (not just returns 200)
- Verify response format matches observability standard (status, version, checks object)
- Flag: missing any endpoint → FINDING: HIGH
- Flag: /health/ready returns 200 even when DB is down → FINDING: CRITICAL

**Check: Dockerfile**
- Read Dockerfile — verify multi-stage build (build stage separate from production stage)
- Flag: running as root user (no `USER` directive or `USER root`) → FINDING: HIGH
- Flag: no `.dockerignore` file → FINDING: MEDIUM
- Flag: `COPY . .` before dependency install (breaks layer caching) → FINDING: LOW
- Flag: using `latest` tag on base image → FINDING: MEDIUM

**Check: Kubernetes manifests**
- Read k8s/base/deployment.yaml
- Flag: container with no `resources.requests` → FINDING: HIGH (scheduler can't place pod correctly)
- Flag: container with no `resources.limits` → FINDING: HIGH (runaway process can starve node)
- Flag: no liveness probe → FINDING: HIGH
- Flag: no readiness probe → FINDING: HIGH
- Flag: HPA minReplicas < 2 → FINDING: HIGH (single replica = SPOF)
- Flag: no PDB defined → FINDING: MEDIUM (maintenance can take all pods down simultaneously)
- Flag: `maxUnavailable > 0` in rolling update strategy → FINDING: MEDIUM (causes downtime during deploys)
- Flag: no `preStop` sleep hook → FINDING: MEDIUM (LB may route to terminating pod)

**Check: Secrets hygiene**
- Grep for hardcoded connection strings, API keys, passwords in: source code, Dockerfiles, ConfigMaps, committed .env files
- Flag: any secret found outside of K8s Secret or secrets manager reference → FINDING: CRITICAL
- Flag: secrets in ConfigMap (base64 is not encryption) → FINDING: HIGH

**Check: Environment parity**
- Verify docker-compose.yml uses same DB engine and version as production (check TECH_ARCHITECTURE.md ADR)
- Flag: different DB engines between local and production → FINDING: HIGH

Severity guide: missing resource limits or probes = HIGH, hardcoded secrets = CRITICAL, SPOF single replica = HIGH

---

## Step 9: Code Quality Review  <!-- was Step 7 -->

Perform targeted code review on changed files:

**Check: Error handling**
- No empty catch blocks
- Errors are typed (not generic Exception)
- Errors are logged with context at the boundary where they're handled
- Errors are not re-thrown after logging (double logging)

**Check: Configuration**
- No hardcoded URLs, credentials, or environment-specific values
- All config from environment or config service

**Check: Security basics**
- No SQL string interpolation (use parameterized queries)
- No eval() or dynamic code execution with user input
- Authentication checked before authorization
- Sensitive data not returned in API responses unless required

**Check: Simplicity**
- Any design that could be simpler without losing functionality → flag
- Premature abstractions (abstractions with only one implementation) → flag
- Dead code → flag

## Step 10: Write Review Report

**Create/update docs/review/REVIEW_REPORT.md:**

```markdown
# Review Report
*Date: [date] | Scope: [feature/full system]*

## Summary
- 🔴 Critical: [N]
- 🟠 High: [N]
- 🟡 Medium: [N]
- 🟢 Low: [N]

## Critical Findings
### REVIEW-001: [Title]
- **Dimension:** [Requirements|Data|Architecture|Test|Observability|Code]
- **Severity:** Critical
- **Location:** [file:line or doc section]
- **Finding:** [Specific description]
- **Impact:** [What goes wrong if not fixed]
- **Remediation:** [Exact fix]
- **TODO:** TASK-[NNN] added to TODO.md

[repeat for each critical finding]

## High Findings
[same format]

## Medium Findings
[same format]

## Low Findings
[same format]

## Clean Checks
[Dimensions with no findings — affirm what's good]
```

## Step 11: Create Remediation Tasks

For each HIGH/CRITICAL finding, add a task to $STATE tasks array:

```json
{"id": "TASK-[NNN]", "description": "[Fix description from REVIEW-NNN]", "status": "pending", "tags": ["review"], "priority": "P0"}
```

## Step 12: Update State

Mark Phase 13 (Review) complete in $STATE.

Output:
```
Review Complete: [feature/system]

Critical: [N] | High: [N] | Medium: [N] | Low: [N]
Remediation tasks added to $STATE: [N]

File: $ARTIFACTS/review/review-report.md

Recommended Next: /sdlc:00-start (verify is automatic, or say "verify phase N") 13   ← confirms all HIGH/CRITICAL findings have tasks
```
