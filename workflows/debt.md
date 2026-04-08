# Debt Workflow

View and manage the technical debt register stored in state.json. Supports adding new items, resolving existing items, and exporting the full register to a markdown report.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

**Parse $ARGUMENTS:**
- Detect `--add <description>` — everything after `--add` up to the next flag is the description
- Detect `--resolve <TD-ID>` — the TD-ID to resolve
- Detect `--export` — flag to write the register to a file

---

## Step 1: Load Debt Register

Read `$STATE` (state.json). Extract the `technicalDebts` array.

**If state.json does not exist:**
```
No SDLC workspace found on branch $BRANCH.
Run /sdlc:00-start to initialize a project first.
```
STOP.

**If technicalDebts array is missing or empty and no flags are provided:**
```
Technical Debt Register: Empty

No technical debt items recorded for branch $BRANCH.

To add items:
  ask Claude to run the debt workflow --add "<description of the debt>"

To discover debt automatically:
  Run ask Claude to run the gaps workflow — spawns 3 analysis agents and populates the register.
```
STOP (unless --add or --export flags are present).

---

## Step 2: Handle --add Flag

If `--add` flag is present:

**Extract description** from arguments after `--add`.

If description is empty: output "Please provide a description. Example: ask Claude to run the debt workflow --add 'UserService is a 600-line fat class that mixes domain logic with HTTP handling'" STOP.

**Determine next TD-NNN ID:**
- Read existing IDs in technicalDebts array
- Sort numerically, take highest number + 1
- If no items exist: TD-001

**Classify severity** — infer from description keywords:
- Keywords: security, vulnerability, CVE, SQL injection, hardcoded credential, exposed secret → CRITICAL
- Keywords: no tests, untested, missing error handling, production incident, data loss risk → HIGH
- Keywords: TODO, FIXME, complex, large file, duplicate, refactor, tech debt → MEDIUM
- Default → LOW

**Classify category:**
- Keywords: test, coverage, spec → test-coverage
- Keywords: security, auth, credential, vulnerability → security
- Keywords: architecture, layer, dependency, import, circular → architecture
- Keywords: performance, slow, latency, N+1, query → performance
- Keywords: doc, comment, readme, documentation → documentation
- Keywords: dependency, package, library, upgrade → dependencies
- Default → code-quality

**Determine recommendation:**
Based on severity and category, generate a concise recommendation:
- CRITICAL: "Address immediately before next deployment"
- HIGH: "Schedule for current sprint"
- MEDIUM: "Add to backlog for next quarter"
- LOW: "Track and address during related refactoring"

**Append to technicalDebts array in state.json:**

```json
{
  "id": "TD-NNN",
  "description": "<description>",
  "severity": "<CRITICAL|HIGH|MEDIUM|LOW>",
  "category": "<category>",
  "file": null,
  "phaseCreated": "manual",
  "status": "open",
  "recommendation": "<recommendation>",
  "createdAt": "<ISO timestamp>",
  "resolvedAt": null,
  "resolvedBy": null,
  "fixRef": null
}
```

Update `updatedAt` in state.json. Write the file.

Output:
```
Added TD-NNN: <description>
Severity: <CRITICAL|HIGH|MEDIUM|LOW>
Category: <category>
Recommendation: <recommendation>
```

Then proceed to display the register (Step 4).

---

## Step 3: Handle --resolve Flag

If `--resolve` flag is present:

**Parse TD-ID** from arguments after `--resolve` (e.g., `--resolve TD-007`).

**Validate:**
- TD-ID must exist in technicalDebts array. If not: output "TD-ID '<id>' not found in the register. Run ask Claude to run the debt workflow to see all IDs." STOP.
- TD-ID must have `status: "open"`. If already resolved: output "TD-ID '<id>' is already resolved (resolved at <resolvedAt>)." STOP.

**Update the item in state.json:**
- Set `status: "resolved"`
- Set `resolvedAt: "<ISO timestamp>"`
- Set `resolvedBy: "manual"` (user marked it resolved)

**Check for related FIX or ITER files:**
```bash
grep -l "<TD-ID>" .claude/ai-sdlc/ITERATIONS/*.md 2>/dev/null
```
If a related fix/iter file exists, set `fixRef` to that file's ID.

Update `updatedAt`. Write state.json.

Output:
```
Resolved TD-NNN: <description>
Resolved at: <ISO timestamp>
```

Then proceed to display the register (Step 4).

---

## Step 4: Display Debt Register

Compute stats from the technicalDebts array:

```
╔══════════════════════════════════════════════════════════════════╗
║  TECHNICAL DEBT REGISTER                                         ║
║  Branch: <$BRANCH>    Updated: <date>                            ║
╠══════════════════════════════════════════════════════════════════╣
║  OPEN ITEMS                                                      ║
║  CRITICAL: <N>   HIGH: <N>   MEDIUM: <N>   LOW: <N>             ║
║  Total open: <N>   Total resolved: <N>   Total: <N>             ║
╚══════════════════════════════════════════════════════════════════╝
```

**Table of open items (sorted by severity: CRITICAL → HIGH → MEDIUM → LOW):**

```
OPEN TECHNICAL DEBT

| TD-ID | Severity | Category | Description | Phase Created | Recommendation |
|-------|----------|----------|-------------|---------------|----------------|
| TD-001 | CRITICAL | security | Hardcoded DB password in config.ts | gaps | Address immediately |
| TD-002 | HIGH | architecture | UserService mixes HTTP handling with domain logic | gaps | Refactor in current sprint |
| TD-003 | MEDIUM | test-coverage | Payment flow has no integration tests | gaps | Add to backlog |
```

**Table of resolved items** (show only if any exist, collapsed by default):

```
RESOLVED TECHNICAL DEBT (last 10)

| TD-ID | Severity | Description | Resolved At | Fix Ref |
|-------|----------|-------------|-------------|---------|
```

---

## Step 5: Handle --export Flag

If `--export` flag is present:

Create the output directory:
```bash
mkdir -p "$ARTIFACTS/maintain"
```

Write `$ARTIFACTS/maintain/debt-register.md`:

```markdown
# Technical Debt Register
*Branch: <$BRANCH> | Exported: <ISO date>*

## Summary

| Status | CRITICAL | HIGH | MEDIUM | LOW | Total |
|--------|----------|------|--------|-----|-------|
| Open | N | N | N | N | N |
| Resolved | N | N | N | N | N |
| **Total** | **N** | **N** | **N** | **N** | **N** |

---

## Open Debt Items

### CRITICAL

| TD-ID | Category | Description | File | Phase Created | Recommendation |
|-------|----------|-------------|------|---------------|----------------|
<rows — only CRITICAL open items>

### HIGH

| TD-ID | Category | Description | File | Phase Created | Recommendation |
|-------|----------|-------------|------|---------------|----------------|
<rows — only HIGH open items>

### MEDIUM

| TD-ID | Category | Description | File | Phase Created | Recommendation |
|-------|----------|-------------|------|---------------|----------------|
<rows>

### LOW

| TD-ID | Category | Description | File | Phase Created | Recommendation |
|-------|----------|-------------|------|---------------|----------------|
<rows>

---

## Resolved Debt Items

| TD-ID | Severity | Category | Description | Resolved At | Fix Reference |
|-------|----------|----------|-------------|-------------|---------------|
<all resolved items>

---

## Remediation Priority Plan

Top items to address ordered by Severity × Age:

| Priority | TD-ID | Action | Effort | Assigned To |
|----------|-------|--------|--------|-------------|
| 1 | TD-NNN | <action> | S/M/L | <unassigned> |
...

---
*Generated by ask Claude to run the debt workflow — re-run to refresh*
```

Update `phases.maintain.artifacts` array in state.json to include the export file path.
Update `updatedAt`.

Output: "Exported debt register to $ARTIFACTS/maintain/debt-register.md (<N> open items, <N> resolved)"

---

## Step 6: Suggest Next Steps

After displaying the register:

```
NEXT STEPS:
```

If CRITICAL items exist:
```
  ! <N> CRITICAL items require immediate attention.
    Run /sdlc:fix --maintenance to address each one.
    Run ask Claude to run the gaps workflow for root-cause analysis of debt patterns.
```

If no items exist:
```
    Debt register is clean. Run ask Claude to run the gaps workflow periodically to catch new debt.
```

Otherwise:
```
    Run ask Claude to run the debt workflow --add "<description>" to add items manually.
    Run ask Claude to run the debt workflow --resolve <TD-ID> to mark items fixed.
    Run ask Claude to run the debt workflow --export to generate a shareable debt report.
    Run ask Claude to run the gaps workflow to auto-discover debt via codebase analysis.
```
