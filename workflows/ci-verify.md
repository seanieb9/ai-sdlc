# CI Verify Workflow

Gate check for the deploy phase. Verifies that a CI pipeline exists and contains all required jobs. Hard FAIL if no CI config is found — this is a deploy blocker.

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/deploy"
mkdir -p "$PHASE_ARTIFACTS"
```

Note: CI verification artifact is placed in the deploy phase directory since this is a deploy gate.

---

## Step 1: Find CI Configuration

Search for CI configuration files:

```bash
# GitHub Actions
find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null

# GitLab CI
[ -f ".gitlab-ci.yml" ] && echo ".gitlab-ci.yml"

# Jenkins
[ -f "Jenkinsfile" ] && echo "Jenkinsfile"

# CircleCI
[ -f ".circleci/config.yml" ] && echo ".circleci/config.yml"

# Bitbucket Pipelines
[ -f "bitbucket-pipelines.yml" ] && echo "bitbucket-pipelines.yml"

# Azure Pipelines
find . -maxdepth 2 -name "azure-pipelines.yml" 2>/dev/null
```

If NO CI configuration files are found:
- This is a HARD FAIL — deploy is blocked
- Write the artifact with GATE: FAIL
- If `--auto-chain`: log `{ "status": "failed", "summary": "HARD FAIL: No CI pipeline found — deploy blocked" }` and output `❌ ci-verify — HARD FAIL: no CI pipeline found — deploy blocked`
- If interactive: output a prominent failure message and recommended fix

Do not continue to Step 2 if no CI config found.

---

## Step 2: Read CI Configuration

Read all CI config files found in Step 1.

For each file, parse:
- Platform: [GitHub Actions / GitLab CI / Jenkins / CircleCI / Bitbucket / Azure]
- Pipeline triggers: [push to main? pull_request? tags? manual?]
- Jobs/stages defined: [list of all job names]
- For each job: what commands does it run?

---

## Step 3: Verify Required Jobs

Check for the presence of these four required job categories. A job "exists" if its commands match the purpose — the job name doesn't matter, only what it does.

### Required Job 1: Build
The pipeline must compile, transpile, or package the code.
Look for commands like: `npm run build`, `go build`, `mvn package`, `gradle build`, `pip install`, `python setup.py build`, `cargo build`, `docker build`

### Required Job 2: Test with Coverage
The pipeline must run tests AND measure coverage.
Look for commands like: `npm test`, `pytest`, `go test`, `mvn test`, `gradle test`, `rspec`, `cargo test`
AND coverage flags: `--coverage`, `--cov`, `-cover`, `jacoco`, `simplecov`, `tarpaulin`

### Required Job 3: Lint / Format Check
The pipeline must check code quality and formatting.
Look for commands like: `eslint`, `prettier --check`, `flake8`, `pylint`, `black --check`, `golangci-lint`, `rubocop`, `clippy`, `checkstyle`, `spotless`

### Required Job 4: Security Scan
The pipeline must check for vulnerabilities.
Look for commands like: `npm audit`, `pip-audit`, `trivy`, `snyk`, `govulncheck`, `bundler-audit`, `cargo audit`, `dependency-check`, `semgrep`, any SAST tool

For each required job, record:
```
Job: [Build / Test / Lint / Security]
Present: [yes/no]
Job name: [actual job name in CI file]
Commands found: [matching commands]
Status: [PASS / FAIL]
```

---

## Step 4: Check Coverage Threshold

Is a coverage threshold enforced in the test job?

Look for:
- `--coverage-threshold` or `--coverageThreshold` in Jest config or CLI
- `--fail-under` in pytest-cov
- `<failOnMinimumCoverage>` in JaCoCo Maven config
- `minimumCoverage` in gradle
- `-coverprofile` + threshold check in Go
- `minimum_coverage` in simplecov

Record:
```
Coverage threshold enforced: [yes/no]
Threshold value: [N% or "not specified"]
Fails build on low coverage: [yes/no]
```

A pipeline that runs tests but does not fail on low coverage provides no coverage gate.

---

## Step 5: Check Trigger Configuration

Does the CI pipeline run on:
- Pull request / merge request: [yes/no]
- Push to main/master branch: [yes/no]
- Tag creation (for release workflows): [yes/no]

A pipeline that only runs on main pushes (not on PRs) means code reaches main before being checked.

---

## Step 6: Determine Gate Result

**PASS** — all conditions met:
- At least one CI config file exists
- All 4 required jobs present
- Coverage threshold enforced
- Pipeline triggers on pull requests AND main branch

**CONDITIONAL PASS** — CI exists and core jobs present, but gaps exist:
- CI config exists
- Build + Test jobs present
- Missing Lint or Security scan
- Coverage threshold not enforced

**FAIL** — CI exists but is critically incomplete:
- Missing Build OR Test job
- OR: no CI config at all

Gate result for deploy:
- PASS → deploy may proceed
- CONDITIONAL PASS → deploy may proceed with acknowledged risk, gaps must be backlog items
- FAIL → deploy blocked (if hard fail: no CI config at all)

---

## Step 7: Write Artifact

Write `$PHASE_ARTIFACTS/ci-verification.md`:

```markdown
# CI Pipeline Verification
*Generated: [date] | Branch: [branch]*

## Gate Result: [PASS / CONDITIONAL PASS / FAIL]

[If FAIL:]
> ⛔ Deploy is BLOCKED. [Reason]

[If CONDITIONAL PASS:]
> ⚠️ Deploy may proceed but the following gaps must be addressed.

## Pipeline Overview

| Platform | Config File | Triggers |
|----------|-------------|---------|
[one row per CI file found]

## Required Jobs Status

| Job | Status | Job Name | Commands Found |
|-----|--------|----------|---------------|
| Build | [✅ PASS / ❌ FAIL] | [job name] | [commands] |
| Test + Coverage | [✅ PASS / ❌ FAIL] | [job name] | [commands] |
| Lint / Format | [✅ PASS / ⚠️ MISSING] | [job name] | [commands] |
| Security Scan | [✅ PASS / ⚠️ MISSING] | [job name] | [commands] |

## Coverage Gate

| Metric | Status | Value |
|--------|--------|-------|
| Tests run in CI | [✅/❌] | — |
| Coverage measured | [✅/⚠️] | — |
| Coverage threshold enforced | [✅/⚠️] | [N%] |
| Build fails on low coverage | [✅/⚠️] | — |

## Trigger Configuration

| Trigger | Configured |
|---------|-----------|
| Pull requests | [✅/❌] |
| Push to main | [✅/❌] |
| Tag creation | [✅/❌/N/A] |

## Recommendations

[If FAIL:]
### Immediate (deploy blocked)
- [specific action to unblock deploy]

[If gaps exist:]
### Before Next Release
- [numbered list of specific improvements]

### Suggested additions (if missing):
```yaml
# Add to your CI pipeline:
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npm audit --audit-level=high
```
[Only include if security scan is missing]
```

---

## Step 8: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "ci-verify",
  "triggeredAfter": "deploy",
  "status": "[completed|failed]",
  "artifact": "<PHASE_ARTIFACTS>/ci-verification.md",
  "summary": "Gate: [PASS/CONDITIONAL PASS/FAIL] — Build:[✅/❌] Test:[✅/❌] Lint:[✅/❌] Security:[✅/❌]",
  "completedAt": "<ISO-timestamp>"
}
```

Set `"status": "failed"` in the log entry if gate result is FAIL.

---

## Step 9: Output

If `--auto-chain`:

On PASS:
```
✅ ci-verify — PASS: all required jobs present, coverage gated [<PHASE_ARTIFACTS>/ci-verification.md]
```

On CONDITIONAL PASS:
```
⚠️ ci-verify — CONDITIONAL PASS: missing [lint/security] [<PHASE_ARTIFACTS>/ci-verification.md]
```

On FAIL:
```
❌ ci-verify — HARD FAIL: [no CI config found / missing build+test jobs] — deploy blocked
```

If interactive:
```
[Gate result header]

Pipeline: [platform] — [config file]

Required jobs:
  Build:    [✅/❌]
  Test:     [✅/❌] (coverage threshold: [N%/not set])
  Lint:     [✅/❌]
  Security: [✅/❌]

Triggers:
  Pull requests: [✅/❌]
  Main branch:   [✅/❌]

[If FAIL or CONDITIONAL PASS:]
Actions required:
  [numbered list]

Report: <PHASE_ARTIFACTS>/ci-verification.md
```
