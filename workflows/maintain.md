# Maintain Workflow

Phase 15 maintenance planning. Consolidates all technical debt, identifies scheduled operational tasks, assesses dependency health, and produces a forward-looking upgrade roadmap. Run after deployment.

---

## Step 0: Workspace Resolution

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$ARTIFACTS"
```

Then use `$WORKSPACE`, `$STATE`, `$ARTIFACTS` throughout.

---

## Step 1: Load Existing State and Artifacts

Read in parallel:
- `$STATE` (state.json) — `technicalDebts` array, all phase `completedAt` timestamps
- `$ARTIFACTS/verify/verification-report.md` — WARN and INFO findings that were not blocking (if exists)
- `$ARTIFACTS/design/tech-architecture.md` — architecture-implied operational tasks (if exists)
- `$ARTIFACTS/sre/observability.md` — monitoring and alerting setup (if exists)
- `$ARTIFACTS/sre/runbooks.md` — existing scheduled operations (if exists)

**Flag handling:**
- `--debt-only`: skip Steps 4 and 5 (scheduled operations and upgrade roadmap), produce debt register only
- `--schedule-only`: skip Steps 3 and 5 (debt and roadmap), produce scheduled operations only

**Execution mode:** INTERACTIVE.

---

## Step 2: Consolidate Technical Debt

Gather all tech debt from three sources:

### Source A: state.json technicalDebts array

Read `technicalDebts` from state.json. Each entry may have an ID or be a free-form note. Assign TD-IDs to any entries that don't have them (TD-001, TD-002, ...).

### Source B: Verification report findings

Read verification-report.md and extract all findings with severity WARN or INFO that are not marked as resolved. These represent known quality gaps that were acceptable for release but should be tracked.

### Source C: Source code scan

Run the following to find TODO, FIXME, and HACK comments in the source:

```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|DEBT\|WORKAROUND" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
  --include="*.rb" --include="*.java" --include="*.cs" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
  . 2>/dev/null | head -100
```

For each result, extract the file, line number, and comment text. Group duplicates (same issue referenced in multiple places).

---

## Step 3: Prioritize Tech Debt

For each TD-ID, assign a priority:

- **P0**: Blocks the next feature or creates a security/data integrity risk. Must fix before next release.
- **P1**: Degrades code quality, performance, or observability. Should fix in next sprint.
- **P2**: Nice to fix, low impact, can be batched.

Build the debt register:

| TD-ID | Description | Source | Severity | Effort | Priority | Recommendation |
|-------|-------------|--------|----------|--------|----------|---------------|
| TD-001 | [description] | state.json | HIGH/MED/LOW | S/M/L | P0/P1/P2 | [what to do] |

**Effort sizing:**
- S (Small): < 1 day
- M (Medium): 1-3 days
- L (Large): > 3 days

---

## Step 4: Identify Scheduled Operations

Review the architecture for operational tasks that must run on a schedule:

**Database operations** (from data model / tech-architecture):
- VACUUM / ANALYZE (PostgreSQL)
- Index rebuilds
- Partition maintenance
- Archive / purge jobs (data retention policies)

**Security operations:**
- TLS certificate renewal (note expiry dates from config)
- Secret / API key rotation schedule
- Dependency vulnerability scans

**Infrastructure operations:**
- Backup verification (not just backup creation — verify restore works)
- Log rotation and archival
- Monitoring alert rule review

**Dependency management:**
- Dependency update cadence (weekly/monthly patches, quarterly major updates)

Build the scheduled operations table:

| Operation | Frequency | Owner | Automation? | Last Run | Notes |
|-----------|-----------|-------|-------------|----------|-------|
| [operation] | Daily/Weekly/Monthly/Quarterly | [role] | Yes/No | [date or N/A] | [notes] |

---

## Step 5: Dependency Health Assessment

Run the appropriate dependency audit command (do not modify any files — read-only audit):

```bash
# Node.js
npm outdated 2>/dev/null || true
npm audit --audit-level=high 2>/dev/null || true

# Python
pip list --outdated 2>/dev/null || true

# Ruby
bundle outdated 2>/dev/null || true

# Go
go list -u -m all 2>/dev/null || true
```

Categorize findings:
- **Security vulnerabilities** (HIGH or CRITICAL): must upgrade before next release
- **Outdated major version**: plan upgrade, may have breaking changes
- **Outdated minor/patch**: include in routine maintenance

---

## Step 6: Build Upgrade Roadmap

Based on debt priorities and dependency findings, recommend what to tackle in the next quarter:

**Next sprint (P0 items and security vulnerabilities):**
- [list TD-IDs and security deps]

**Next month (P1 items and major version upgrades):**
- [list TD-IDs and deps]

**Next quarter (P2 items, architectural improvements):**
- [list items]

**Future (low priority, no date):**
- [list items]

---

## Step 7: Write Artifact

Write `$ARTIFACTS/maintain/maintenance-plan.md`:

```markdown
# Maintenance Plan: [Feature / Project Name]
*Date: [ISO date]*
*Branch: [branch]*

---

## Tech Debt Register

| TD-ID | Description | Source | Severity | Effort | Priority | Recommendation |
|-------|-------------|--------|----------|--------|----------|---------------|
[rows from Step 3]

**Summary:** [N] total items — [N] P0, [N] P1, [N] P2

---

## Scheduled Operations

| Operation | Frequency | Owner | Automation? | Last Run | Notes |
|-----------|-----------|-------|-------------|----------|-------|
[rows from Step 4]

---

## Dependency Health

### Security Vulnerabilities
[HIGH/CRITICAL findings — must address]

### Outdated Major Versions
[list with current version and latest version]

### Outdated Minor/Patch
[batched list]

---

## Upgrade Roadmap

### Next Sprint
[P0 debt items + security vulnerabilities]

### Next Month
[P1 debt items + major version upgrades]

### Next Quarter
[P2 debt items + architectural improvements]

### Future
[low priority items with no set date]
```

---

## Step 8: Update State

Update `$STATE` (state.json):
- Set `phases.maintain.status` = `"completed"`
- Set `phases.maintain.completedAt` = current ISO timestamp
- Set `phases.maintain.artifacts` = `["maintenance-plan.md"]`
- Set `updatedAt` = current ISO timestamp

---

## Step 9: Checkpoint

```
Maintenance Plan Complete
══════════════════════════
Tech debt items:    [N] ([N] P0, [N] P1, [N] P2)
Scheduled ops:      [N] identified
Security vulns:     [N] HIGH/CRITICAL
Outdated deps:      [N] major, [N] minor

Artifact: $ARTIFACTS/maintain/maintenance-plan.md
```

If any P0 debt items exist: warn prominently:
```
⚠ P0 Tech Debt: [N] items must be resolved before the next release.
  See TD-IDs: [list]
```

Suggest:
```
Next steps:
  → Run project retrospective: ask Claude to run the retro workflow
  → Review P0 debt items before starting next feature
```
