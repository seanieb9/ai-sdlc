# Audit Dependencies Workflow

Scans project dependencies for known CVEs, outdated versions, unused packages, and license compliance issues. Runs native audit tools when available.

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/audit-deps"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Discover Dependency Files

Glob for dependency manifest files in the project root and first-level subdirectories:

```bash
find . -maxdepth 3 \( \
  -name "package.json" \
  -o -name "requirements.txt" \
  -o -name "Pipfile" \
  -o -name "pyproject.toml" \
  -o -name "go.mod" \
  -o -name "pom.xml" \
  -o -name "build.gradle" \
  -o -name "Gemfile" \
  -o -name "Cargo.toml" \
  -o -name "composer.json" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
```

If no dependency files found:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "No dependency files found" }` and output `⏭️ audit-deps — skipped: no dependency files found`
- If interactive: inform user and ask if they want to specify a path manually.

For each file found, determine the ecosystem (Node.js, Python, Go, Java, Ruby, Rust, PHP).

---

## Step 2: Run Native Audit Tools

For each ecosystem found, run the appropriate audit command. Capture output to a temp file.

**Node.js (package.json):**
```bash
# Only if package-lock.json or yarn.lock exists
if [ -f "package-lock.json" ]; then
  npm audit --json 2>/dev/null > /tmp/npm-audit.json || true
elif [ -f "yarn.lock" ]; then
  yarn audit --json 2>/dev/null > /tmp/yarn-audit.json || true
fi
```

Parse JSON output. Extract vulnerabilities with: package name, current version, CVSS score, CVE ID, severity, fix version (if available).

**Python (requirements.txt / Pipfile / pyproject.toml):**
```bash
# pip-audit if installed
if command -v pip-audit >/dev/null 2>&1; then
  pip-audit --format json 2>/dev/null > /tmp/pip-audit.json || true
fi
```

**Go (go.mod):**
```bash
# govulncheck if installed
if command -v govulncheck >/dev/null 2>&1; then
  govulncheck ./... 2>/dev/null > /tmp/govulncheck.txt || true
fi
# Also list all modules
go list -m -json all 2>/dev/null > /tmp/go-modules.json || true
```

**Ruby (Gemfile):**
```bash
if command -v bundler-audit >/dev/null 2>&1; then
  bundle-audit check 2>/dev/null > /tmp/bundle-audit.txt || true
fi
```

If an audit tool is not available: read the dependency file directly and perform a manual check:
- Look for obviously old pinned versions (e.g., dependencies several major versions behind current)
- Flag any packages with known security histories that should be kept up-to-date
- Note which tools were unavailable so the user can install them

---

## Step 3: Categorize Findings

For each vulnerability found, categorize by severity:

```
CRITICAL: CVSS ≥ 9.0 — known exploit with high impact (RCE, auth bypass, mass data exposure)
HIGH:     CVSS 7.0–8.9 — significant vulnerability, should fix before release
MEDIUM:   CVSS 4.0–6.9 — notable risk, fix in next sprint
LOW:      CVSS < 4.0 — minor risk, fix in backlog
INFO:     No CVSS assigned or informational advisory
```

For each finding record:
```
Package: [name]
Installed version: [version]
Fix version: [version where fixed, or "no fix available"]
CVE ID: [CVE-YYYY-NNNNN or advisory ID]
CVSS Score: [score]
Severity: [CRITICAL/HIGH/MEDIUM/LOW]
Description: [brief — what the vulnerability is]
Affected by: [transitive/direct dependency]
```

---

## Step 4: Check for Unused Dependencies

**Node.js only** (most reliable detection):

Read `package.json` to get the list of direct dependencies.

For each dependency, search for imports in source files:
```bash
for pkg in $(node -e "const p=require('./package.json'); console.log(Object.keys({...p.dependencies,...p.devDependencies}).join('\n'))" 2>/dev/null); do
  count=$(grep -r "require.*['\"]${pkg}['\"]\\|from ['\"]${pkg}" \
    --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" \
    src/ lib/ app/ 2>/dev/null | wc -l)
  echo "$pkg: $count"
done
```

Flag packages with 0 import matches as potentially unused (note: some packages like babel presets or webpack plugins are used through config, not imports — mark those as "verify manually").

For other ecosystems: skip this check or note it requires manual verification.

---

## Step 5: Check License Compliance

Read all dependency files. For Node.js, check license fields in node_modules (if present):

```bash
# List all licenses (Node.js)
if [ -d "node_modules" ]; then
  find node_modules -name "package.json" -maxdepth 3 \
    -not -path "*/node_modules/*/node_modules/*" \
    -exec node -e "try{const p=require('{}');if(p.license)console.log(p.name+': '+p.license)}catch(e){}" \; 2>/dev/null \
    | grep -i "gpl\|agpl\|lgpl\|copyleft" | head -50 || true
fi
```

Flag these license types as potential compliance issues in production code:
- GPL v2/v3 (copyleft — if linking, your code may need to be GPL too)
- AGPL (network copyleft — SaaS usage may require source disclosure)
- LGPL (weaker copyleft — check linking type)
- SSPL (MongoDB license — controversial for SaaS)
- CC-BY-SA (creative commons share-alike — rarely appropriate for code)
- Unlicensed (no license = all rights reserved by default — may be an issue)

Mark as INFO for dev-only dependencies (devDependencies in package.json) since they don't ship to production.

---

## Step 6: Write Artifact

Write `$PHASE_ARTIFACTS/dependency-audit.md`:

```markdown
# Dependency Audit Report
*Generated: [date] | Branch: [branch]*

## Summary

| Severity | Count | Action |
|----------|-------|--------|
| CRITICAL | [N] | Fix immediately — block release |
| HIGH | [N] | Fix before release |
| MEDIUM | [N] | Fix in next sprint |
| LOW | [N] | Backlog |
| Unused dependencies | [N] | Review and remove |
| License issues | [N] | Legal review |

## Ecosystems Scanned
[Table: Ecosystem | Manifest file | Audit tool used | Tool available?]

## CRITICAL Vulnerabilities

| Package | Version | Fix Version | CVE | CVSS | Description |
|---------|---------|------------|-----|------|-------------|
[CRITICAL rows only]

## HIGH Vulnerabilities

| Package | Version | Fix Version | CVE | CVSS | Description |
|---------|---------|------------|-----|------|-------------|
[HIGH rows only]

## MEDIUM / LOW Vulnerabilities

| Package | Severity | CVE | Description | Fix Version |
|---------|----------|-----|-------------|------------|
[MEDIUM and LOW rows combined]

## Unused Dependencies

| Package | Ecosystem | Evidence | Recommendation |
|---------|-----------|----------|---------------|
[packages with no import matches]

## License Issues

| Package | License | Concern | Is DevDependency? | Recommendation |
|---------|---------|---------|------------------|----------------|
[flagged licenses]

## Recommended Actions

### Immediate (before release)
[numbered list — CRITICAL and HIGH fixes with specific commands]
```bash
npm update [package]@[fix-version]
# or
npm install [package]@[fix-version]
```

### Next Sprint
[MEDIUM findings]

### Backlog
[LOW findings, unused deps, minor license concerns]

## Audit Tool Availability
[List any audit tools that were not available and install instructions]
```

---

## Step 7: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "audit-deps",
  "triggeredAfter": "build",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/dependency-audit.md",
  "summary": "<X> CRITICAL, <Y> HIGH, <Z> MEDIUM vulnerabilities; <N> unused deps; <M> license issues",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 8: Output

If `--auto-chain`:
```
✅ audit-deps — <X> CRITICAL <Y> HIGH vulns, <N> unused, <M> license issues [<PHASE_ARTIFACTS>/dependency-audit.md]
```

If interactive:
```
✅ Dependency Audit Complete

Vulnerabilities found:
  CRITICAL: [N] [— block release if > 0]
  HIGH:     [N]
  MEDIUM:   [N]
  LOW:      [N]

Unused dependencies: [N]
License issues: [N]

[If CRITICAL > 0]:
⚠️  CRITICAL vulnerabilities must be patched before release.

Report: <PHASE_ARTIFACTS>/dependency-audit.md
```
