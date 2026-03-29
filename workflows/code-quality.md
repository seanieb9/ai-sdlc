# Code Quality Auto-Chain

Runs automatically after every build phase completion. Performs static analysis, security scanning, dependency health check, and complexity analysis. Reports findings without blocking (findings go to technical debt register for prioritization).

Critical/High security findings are surfaced as blocking items in the verify phase. All other findings are queued for prioritization.

---

## Step 0: Workspace Resolution

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$ARTIFACTS/code-quality"
```

Then use $WORKSPACE, $STATE, $ARTIFACTS throughout.

---

## Step 1: Read Configuration

- Read `.claude/ai-sdlc.config.yaml` — extract `language`, `framework`, `packageManager`
- Read `$ARTIFACTS/build/` directory listing — identifies files changed in this build
- If no build artifacts are listed: scan the full project `src/` directory as the file set

Determine the language stack from config. All subsequent steps adapt their commands accordingly.

---

## Step 2: Static Analysis (Language-Specific)

Run the appropriate commands for the detected language. Capture all output. Count total errors and warnings.

**JavaScript / TypeScript:**
```bash
# Lint check — treat warnings as errors for reporting purposes
npx eslint src/ --ext .ts,.tsx,.js,.jsx --max-warnings 0 --format json 2>&1 | tail -50

# Type check
npx tsc --noEmit 2>&1 | tail -20

# Complexity check (if available)
npx complexity-report --format json src/ 2>/dev/null | head -50
```

**Python:**
```bash
# Lint + style check
ruff check src/ --output-format=json 2>&1 | tail -30

# Type checking
mypy src/ --ignore-missing-imports --no-error-summary 2>&1 | tail -20
```

**Go:**
```bash
go vet ./... 2>&1 | tail -20
staticcheck ./... 2>&1 | tail -20
```

**Ruby:**
```bash
bundle exec rubocop src/ --format json 2>&1 | tail -30
```

**Java / Kotlin:**
```bash
./gradlew checkstyleMain spotbugsMain 2>&1 | tail -30
# or for Maven:
# mvn checkstyle:check spotbugs:check -q 2>&1 | tail -30
```

Parse the output and record:
- Total error count
- Total warning count
- Any functions/methods exceeding cyclomatic complexity 10
- Any files exceeding 200 lines

---

## Step 3: Security Scan

Run secrets scanning and dependency vulnerability checks.

```bash
# Secrets scanning — check changes since last commit
git diff HEAD~1 --name-only 2>/dev/null | head -20
gitleaks detect --source . --log-opts HEAD~1 2>&1 | tail -20
```

**Dependency vulnerabilities by language:**

```bash
# JavaScript / TypeScript
npm audit --audit-level=moderate --json 2>&1 | tail -50

# Python
pip-audit --format json 2>&1 | tail -30

# Go
govulncheck ./... 2>&1 | tail -20

# Ruby
bundle audit check --update 2>&1 | tail -20
```

Classify each finding by severity: CRITICAL, HIGH, MODERATE, LOW.

Record:
- Total vulnerability count
- Critical/High count (these are blocking)
- Any secrets detected in the diff

---

## Step 4: Dependency Health

Check for:
- Outdated dependencies that have security patches available (flag as HIGH if security patch)
- Dependencies with known vulnerabilities (from Step 3)
- Dependencies with GPL/AGPL/SSPL licenses in a commercial product — flag for legal review

```bash
# JavaScript / TypeScript
npm outdated 2>&1 | head -20

# Python
pip list --outdated --format=json 2>&1 | head -30

# Go
go list -m -u all 2>&1 | head -20

# Ruby
bundle outdated --strict 2>&1 | head -20
```

Count: total outdated, security-patch-available (from audit cross-reference).

---

## Step 5: Dead Code Detection

```bash
# JavaScript / TypeScript — unused exports
npx ts-prune 2>&1 | head -20

# Python — unused imports
ruff check --select F401 src/ 2>&1 | head -20

# Go — unused code (go vet covers some; use deadcode if available)
deadcode ./... 2>&1 | head -20

# Ruby
bundle exec debride src/ 2>&1 | head -20
```

Count total dead code items found. These are informational — not blocking.

---

## Step 6: Compile Findings Report

Produce a structured Markdown report from all findings above.

```markdown
# Code Quality Report
*Generated: [ISO 8601 timestamp UTC]*
*Build: [phase/task name that triggered this run]*
*Branch: [git branch]*

## Summary

| Check | Status | Count |
|-------|--------|-------|
| Lint errors | ✅ clean / ⚠️ warnings / ❌ errors | N |
| Type errors | ✅ clean / ❌ errors | N |
| Security vulnerabilities | ✅ clean / ⚠️ moderate / ❌ critical+high | N (CRITICAL: N, HIGH: N) |
| Secrets detected | ✅ none / ❌ detected | N |
| Outdated dependencies | ℹ️ | N |
| Dead code items | ℹ️ | N |

## Critical Findings (must fix before deploy)

<!-- CRITICAL/HIGH severity items. Empty = none. -->

| Severity | Location | Description | Recommended Fix |
|----------|----------|-------------|-----------------|
| CRITICAL | [file:line] | [description] | [action] |

## Warnings (address before next release)

<!-- MODERATE/WARN severity items -->

| Severity | Location | Description |
|----------|----------|-------------|

## Informational

<!-- LOW severity, dead code, outdated deps with no security issue -->

- [list items]
```

Write report to: `$ARTIFACTS/code-quality/quality-report.md`

---

## Step 7: Route Findings

Route findings based on severity to the appropriate registries.

### CRITICAL / HIGH security findings
1. Write a blocking item to `$ARTIFACTS/verify/code-quality-blocks.md` (create or append):
   ```markdown
   ## Code Quality Blocks — [ISO timestamp]
   The following CRITICAL/HIGH findings must be resolved before the deploy gate passes:
   - [finding description] ([location])
   ```
2. Add each item to the technical debt register (`$ARTIFACTS/debt/technical-debt.md`) with priority CRITICAL:
   ```
   | CRITICAL | [description] | code-quality auto-chain | [ISO date] | open |
   ```

### Lint / type errors
Add each item to `$ARTIFACTS/debt/technical-debt.md` with priority HIGH.

### Warnings
Add each item to `$ARTIFACTS/debt/technical-debt.md` with priority MEDIUM.

### Informational items (dead code, outdated deps, low severity)
Log to the auto-chain run log only. Do not add to technical debt register (too noisy).

---

## Step 8: Log to State

Append to `autoChainLog` in `$STATE`:
```json
{
  "trigger": "build",
  "skill": "code-quality",
  "status": "success",
  "result": "[N] critical, [N] high, [N] warnings",
  "runAt": "[ISO timestamp]"
}
```

Set `status` to `"failed"` if any tool invocation returned a non-zero exit code that prevented analysis from completing (tool not installed, parse error, etc.).

---

## Step 9: Output Summary

Print:
```
[code-quality] Complete
  Lint:     [✅ clean / ⚠️ N warnings / ❌ N errors]
  Types:    [✅ clean / ❌ N errors]
  Security: [✅ clean / ⚠️ N moderate / ❌ N critical+high]
  Secrets:  [✅ none detected / ❌ N secrets found]
  Deps:     [ℹ️ N outdated]
  Dead code:[ℹ️ N items]
  → Report: $ARTIFACTS/code-quality/quality-report.md
  [If critical/high: → BLOCKING: N items added to verify gate]
```
