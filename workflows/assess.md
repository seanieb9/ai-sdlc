# Assess Workflow

Brownfield codebase readiness assessment. Scores the codebase across 5 dimensions using evidence gathered directly from source files and the codebase map. Produces a structured readiness rating with prioritized improvement recommendations.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

**Parse $ARGUMENTS for focus area** (optional). If provided, limit dimension analysis to files/patterns relevant to that area.

---

## Step 1: Check Codebase Map

Check if the codebase map exists at `.claude/ai-sdlc/codebase/architecture.md`:

```bash
[ -f ".claude/ai-sdlc/codebase/architecture.md" ] && echo "exists" || echo "missing"
```

If missing:
```
WARNING: Codebase map not found at .claude/ai-sdlc/codebase/architecture.md

The assessment will proceed but with reduced accuracy. For a more comprehensive assessment:
  1. Run /sdlc:map first to build the codebase map
  2. Then re-run ask Claude to re-run the assess workflow

Continuing with direct codebase inspection...
```

If the map exists: read it to get the directory structure, key modules, and tech stack before starting dimension analysis.

---

## Step 2: Establish Codebase Inventory

Before scoring, establish the codebase inventory:

```bash
# Count source files by type
find . -not -path './.git/*' -not -path './node_modules/*' -not -path './.claude/*' \
  -name '*.ts' -o -name '*.js' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.rb' \
  | wc -l

# Find test files
find . -not -path './.git/*' -not -path './node_modules/*' \
  -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name 'test_*.*' \
  | wc -l

# Find configuration files
ls -1 package.json pyproject.toml Cargo.toml go.mod pom.xml Gemfile 2>/dev/null

# Top-level directory structure
ls -d */ 2>/dev/null | head -20
```

---

## Step 3: Score Dimension 1 — Architecture Quality

**Assess (0–10):**

Use Glob and Grep to check:

**Layer separation (max 4 points):**
- Check if canonical clean architecture directories exist: `src/domain`, `src/application`, `src/infrastructure`, `src/delivery` (or equivalents for the tech stack)
- Check if a hexagonal/ports-and-adapters pattern is present: look for `ports/`, `adapters/`, `interfaces/`
- Check if domain code imports infrastructure packages: `grep -r "import.*database\|import.*http\|import.*redis" src/domain/` should return nothing
- Score: 1 pt per layer present and correctly bounded

**Dependency direction (max 3 points):**
- Grep for circular imports or wrong-direction dependencies
- Check for domain models that reference delivery/framework types
- Score: 3 pts if no violations, 2 pts if minor, 1 pt if significant, 0 if domain and infra are mixed

**Separation of concerns (max 3 points):**
- Check for "fat" files (> 300 lines): `wc -l $(find . -name '*.ts' -o -name '*.py' | head -50)`
- Check for multiple responsibilities in single files (large classes combining DB access + business logic + HTTP handling)
- Score: 3 pts if well-separated, 2 pts if some fat files, 1 pt if widespread, 0 if everything in one place

Record: score, evidence list (specific files or patterns cited), top 3 improvement actions.

---

## Step 4: Score Dimension 2 — Test Coverage

**Assess (0–10):**

**Test files exist (max 2 points):**
- Count test files. Score: 2 pts if > 10% of source files have tests, 1 pt if < 10%, 0 if none

**Test framework configured (max 2 points):**
- Check for test framework config: `jest.config.*`, `pytest.ini`, `go test`, `rspec`, etc.
- Check for CI test step in `.github/workflows/`, `Jenkinsfile`, `.circleci/`, etc.
- Score: 1 pt for framework, 1 pt for CI integration

**Coverage reports (max 2 points):**
- Check for coverage config: `coverage` in jest/pytest config, `.coverage` file, `coverage/` directory
- Check for coverage threshold enforcement
- Score: 1 pt if coverage is measured, 1 pt if thresholds are enforced

**Test quality (max 4 points):**
- Check for tests at multiple levels: unit tests (fast, isolated), integration tests, E2E tests
- Check for mocking patterns (not just happy-path integration tests)
- Grep for `TODO: fix this test`, `skip(`, `xit(`, `@pytest.mark.skip` — known-broken tests lower score
- Score: 1 pt per test level type present (unit/integration/e2e/contract), capped at 4

Record: score, evidence, top 3 improvements.

---

## Step 5: Score Dimension 3 — Observability

**Assess (0–10):**

**Structured logging (max 3 points):**
- Grep for structured log calls: `logger.info(`, `log.With(`, `winston`, `pino`, `structlog`, `zerolog`
- Check if log format is JSON/structured vs. plain string concatenation
- Grep for `console.log(` in production code (anti-pattern)
- Score: 3 pts if structured logging throughout, 2 pts if partial, 1 pt if basic logging exists, 0 if none

**Distributed tracing (max 3 points):**
- Grep for OpenTelemetry, Jaeger, Zipkin, Datadog APM, AWS X-Ray usage
- Check for trace ID propagation headers
- Score: 3 pts if full tracing instrumented, 2 pts if partial, 1 pt if trace IDs exist but not propagated, 0 if none

**Metrics and health (max 4 points):**
- Check for health endpoint: `grep -r "health\|/live\|/ready" src/`
- Check for metrics: Prometheus, StatsD, CloudWatch custom metrics
- Check for alerting config: `alerts.yaml`, dashboards directory, Grafana configs
- Score: 1 pt per area (health endpoint / metrics collection / alerts configured / dashboards)

Record: score, evidence, top 3 improvements.

---

## Step 6: Score Dimension 4 — Security Hygiene

**Assess (0–10):**

**Secrets management (max 3 points):**
- Check `.gitignore` for `.env` entries
- Grep for hardcoded credentials: `password\s*=\s*["']`, `api_key\s*=\s*["']`, `SECRET\s*=\s*["']` in source files
- Check for secrets scanning CI step (gitleaks, truffleHog, AWS credential scanning)
- Score: 3 pts if no hardcoded secrets and scanning in CI, 2 pts if no secrets but no scanning, 1 pt if minor issues, 0 if credentials found in source

**Dependency hygiene (max 3 points):**
- Check for dependency audit tools: `npm audit`, `safety`, `dependabot.yml`, `Snyk`, `OWASP dependency-check`
- Check `package.json` / `requirements.txt` for pinned vs. floating versions
- Score: 1 pt for audit tool present, 1 pt for CI integration, 1 pt for pinned versions

**Auth patterns (max 4 points):**
- Grep for authentication middleware: `auth`, `authenticate`, `@login_required`, `requireAuth`
- Check for JWT handling patterns (verify signature? check expiry? validate claims?)
- Check for HTTPS enforcement, CORS configuration
- Check for input validation/sanitization patterns
- Score: 1 pt per area (auth middleware / JWT validation / HTTPS+CORS / input validation)

Record: score, evidence, top 3 improvements.

---

## Step 7: Score Dimension 5 — Documentation

**Assess (0–10):**

**Inline code documentation (max 3 points):**
- Grep for JSDoc, Python docstrings, Go doc comments on exported functions
- Sample 5–10 key files and assess documentation density
- Score: 3 pts if well-documented, 2 pts if partial, 1 pt if minimal, 0 if none

**API documentation (max 3 points):**
- Check for OpenAPI/Swagger: `openapi.yaml`, `swagger.json`, `@ApiOperation`, fastapi auto-docs
- Check for README with API usage examples
- Score: 3 pts if full API spec present and up to date, 2 pts if partial, 1 pt if README only, 0 if none

**Architecture documentation (max 4 points):**
- Check for README.md with project overview
- Check for architecture decision records (ADR directory or doc)
- Check for a getting-started / local development guide
- Check for runbooks or operational documentation
- Score: 1 pt per area present

Record: score, evidence, top 3 improvements.

---

## Step 8: Compute Overall Rating

**Total score:** sum of all 5 dimension scores (max 50)

**Readiness rating:**

| Score | Rating | Meaning |
|-------|--------|---------|
| 40–50 | READY | Codebase is well-structured and ready for new feature development |
| 25–39 | NEEDS-WORK | Several gaps that should be addressed before or alongside feature work |
| 0–24 | SIGNIFICANT-GAPS | Major structural issues that will slow or risk any new development |

**Dimension-level ratings:**

| Score | Level |
|-------|-------|
| 8–10 | STRONG |
| 5–7 | ADEQUATE |
| 2–4 | WEAK |
| 0–1 | CRITICAL GAP |

---

## Step 9: Prioritize Improvement Actions

Collect all "top 3 improvements" from each dimension (up to 15 items). Prioritize:

1. Any dimension with score 0–1 → **P0: Address before new feature work**
2. Any dimension with score 2–4 → **P1: Address within current sprint/quarter**
3. Any dimension with score 5–7 → **P2: Improve incrementally**

Output the top 10 prioritized actions:

| Priority | Dimension | Action | Estimated Effort | Impact |
|----------|-----------|--------|-----------------|--------|
| P0 | Security | Remove hardcoded credentials in config.ts | S | Critical |

---

## Step 10: Output Assessment Report

Present the full assessment as a structured report in the conversation:

```
╔══════════════════════════════════════════════════════════════════╗
║  CODEBASE READINESS ASSESSMENT                                   ║
║  Project: <project name>  Branch: <$BRANCH>  Date: <date>       ║
╠══════════════════════════════════════════════════════════════════╣
║  OVERALL: <READY | NEEDS-WORK | SIGNIFICANT-GAPS>  (<N>/50)     ║
╠══════════════════════════════════════════════════════════════════╣
║  DIMENSION SCORES                                                ║
║  Architecture Quality  <N>/10  [STRONG|ADEQUATE|WEAK|CRITICAL]  ║
║  Test Coverage         <N>/10  [STRONG|ADEQUATE|WEAK|CRITICAL]  ║
║  Observability         <N>/10  [STRONG|ADEQUATE|WEAK|CRITICAL]  ║
║  Security Hygiene      <N>/10  [STRONG|ADEQUATE|WEAK|CRITICAL]  ║
║  Documentation         <N>/10  [STRONG|ADEQUATE|WEAK|CRITICAL]  ║
╠══════════════════════════════════════════════════════════════════╣
║  PRIORITY IMPROVEMENTS                                           ║
║  P0: <action>                                                    ║
║  P1: <action>                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

Then expand each dimension with:
- Evidence that supports the score (specific files, patterns, counts)
- Top 3 improvements with effort estimate

---

## Step 11: Suggest Next Steps

Based on the overall rating and dimension scores:

**If READY:**
```
Next: Run /sdlc:iterate to add new features on a solid foundation.
      Run ask Claude to run the gaps workflow for a deeper dive into specific debt areas.
```

**If NEEDS-WORK:**
```
Next: Address P0 items before new feature work (run /sdlc:fix --maintenance).
      Run ask Claude to run the gaps workflow for detailed debt identification.
      Consider /sdlc:iterate with --type nfr to address observability/security gaps.
```

**If SIGNIFICANT-GAPS:**
```
Next: Run ask Claude to run the gaps workflow for a comprehensive debt analysis.
      Plan a dedicated hardening sprint before new feature development.
      Run /sdlc:fix --maintenance for each P0 item.
      Re-run ask Claude to re-run the assess workflow after hardening sprint to track improvement.
```
