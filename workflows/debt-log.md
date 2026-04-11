# Debt Log Auto-Chain

Runs after code-quality completes. Promotes HIGH/CRITICAL findings from the quality report into two persistent registries: the `technicalDebts` array in state.json (machine-readable) and a new low-priority task in implementation-plan.md (actionable). This closes the loop between quality findings and the backlog.

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/code-quality"
```

---

## Step 1: Read Quality Report

Read `$PHASE_ARTIFACTS/quality-report.md`.

If the file does not exist:
- Log `{ "status": "skipped-condition-not-met", "summary": "quality-report.md not found — code-quality may not have run yet" }` and output `⏭️ debt-log — skipped: no quality report found`
- Stop.

Extract all findings by severity:
- **CRITICAL** — must fix before deploy
- **HIGH** — must fix before production
- **MEDIUM** — warnings, address before next release
- **LOW / INFO** — skip (too noisy for debt register)

---

## Step 2: Update state.json technicalDebts Array

Read `$STATE`. For each CRITICAL and HIGH finding not already present in `state.json → technicalDebts`:

```json
{
  "id": "DEBT-NNN",
  "severity": "CRITICAL|HIGH",
  "description": "[finding description from quality report]",
  "location": "[file:line if available]",
  "source": "code-quality auto-chain",
  "detectedAt": "<ISO-timestamp>",
  "status": "open",
  "linkedTask": null
}
```

Number DEBT-NNN starting after the highest existing DEBT-ID in the array (or DEBT-001 if empty).

Write the updated `technicalDebts` array back to `$STATE`.

---

## Step 3: Add Remediation Tasks to Implementation Plan

Check if `$ARTIFACTS/plan/implementation-plan.md` exists.

**If it exists:** Append a `## Technical Debt Tasks (from Code Quality)` section (or append to an existing one):

```markdown
### DEBT-NNN: [finding description]
**Priority:** CRITICAL (before deploy) | HIGH (before production)
**Location:** [file:line]
**Detected:** [ISO date] by code-quality auto-chain
**Done criteria:** Finding no longer appears in code-quality report; tests pass
**Linked:** state.json → technicalDebts → DEBT-NNN
```

Do NOT add MEDIUM or lower findings to the plan — only CRITICAL and HIGH.

**If plan does not exist:** Write tasks to `$ARTIFACTS/code-quality/debt-tasks.md` for later incorporation when the plan phase runs.

---

## Step 4: Check for MEDIUM Findings (Warn Only)

If MEDIUM findings exist: output a single compact warning at the end:

```
ℹ️  [N] medium-severity findings logged to quality-report.md — address before next release but not blocking.
```

Do not add MEDIUM findings to state.json or the plan.

---

## Step 5: Log to State

Append to `autoChainLog` in `$STATE`:

```json
{
  "skill": "debt-log",
  "triggeredAfter": "build",
  "status": "completed",
  "artifact": "$PHASE_ARTIFACTS/quality-report.md",
  "summary": "<N> CRITICAL, <M> HIGH findings → DEBT-NNN to DEBT-MMM created, <K> tasks added to plan",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 6: Output

If `--auto-chain`:
```
✅ debt-log — DEBT-NNN–DEBT-MMM created, N tasks added to plan [quality-report.md]
```

If no findings to log:
```
✅ debt-log — no CRITICAL/HIGH findings, debt register clean
```

If interactive:
```
✅ Debt Log Complete

Findings processed: [N CRITICAL, M HIGH, K MEDIUM, L INFO]
Debt items created: DEBT-NNN to DEBT-MMM (N total)
Tasks added to plan: [N]

[If any CRITICAL: → These are blocking items. They must be resolved before the deploy gate passes.]

Debt register: state.json → technicalDebts
Tasks: $ARTIFACTS/plan/implementation-plan.md (or debt-tasks.md if plan not yet created)
```
