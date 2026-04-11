# Fix Workflow

Lightweight fix lifecycle for bugs, production hotfixes, and maintenance tasks. Creates a FIX-NNN tracking record, scopes the minimal set of phases needed, performs root cause analysis for bugs, and always adds regression coverage.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

Also ensure the ITERATIONS directory exists:
```bash
mkdir -p ".claude/ai-sdlc/ITERATIONS"
```

---

## Step 1: Classify Fix Type

**Parse $ARGUMENTS:**
- Extract the problem description (everything before flags)
- Detect `--hotfix` flag
- Detect `--maintenance` flag

**Determine fix type and phase scope:**

| Fix Type | Flag | Phases | Notes |
|----------|------|--------|-------|
| Bug fix | (none) | plan → build → test-cases → verify | Standard path, adds regression tests |
| Hotfix | `--hotfix` | plan → build → verify → deploy | Fastest path, no test-gen; all overrides logged as HOTFIX |
| Maintenance | `--maintenance` | plan → build → test-cases → verify | For tech debt, dependency upgrades, refactoring |

**Hotfix warning:** If `--hotfix` is detected, output:
```
HOTFIX MODE ACTIVE
This path skips test-gen for speed. Regression tests should be added in a follow-up fix.
All actions will be tagged HOTFIX in the fix manifest.
Proceed? (yes/no)
```
Use AskUserQuestion for confirmation.

---

## Step 2: Generate FIX-NNN ID

**Find the next sequential ID:**
```bash
ls .claude/ai-sdlc/ITERATIONS/FIX-*.md 2>/dev/null | sort | tail -1
```

Parse the highest existing number. Next ID is that number + 1, zero-padded to 3 digits (e.g., FIX-001, FIX-023).

If no FIX files exist, start at FIX-001.

**Create the fix manifest** at `.claude/ai-sdlc/ITERATIONS/<FIX-NNN>.md`:

```markdown
# <FIX-NNN>: <problem description>

| Field | Value |
|-------|-------|
| ID | <FIX-NNN> |
| Type | <bug-fix | hotfix | maintenance> |
| Branch | <$BRANCH> |
| Status | in-progress |
| Started | <ISO date> |
| Completed | — |
| Hotfix | <true | false> |

## Problem Description
<problem description from $ARGUMENTS>

## Root Cause Analysis
(populated in Step 3)

## Fix Summary
(populated during build phase)

## Phases in Scope
<ordered list>

## Phase Status
| Phase | Status | Completed At | Notes |
|-------|--------|--------------|-------|
<one row per phase, all initially: pending | — | — >

## Regression Coverage
| TC-ID | Description | Added |
|-------|-------------|-------|
(populated when test cases are written)

## Notes
(added during execution)
```

---

## Step 3: Root Cause Analysis (Bug Fix and Hotfix Only)

Skip this step for `--maintenance` fixes.

Use AskUserQuestion to gather root cause information:

**Question 1:** "What is the observed behavior? (What does the system do that it shouldn't, or fail to do that it should?)"

**Question 2:** "What is the expected behavior?"

**Question 3:** "Where in the codebase does this occur? (file, function, module — if known)"

**Question 4:** "What is the likely root cause? Choose one:
  a) Logic error — wrong conditional, wrong calculation, wrong data transformation
  b) Missing handling — edge case, empty/null state, concurrent access not handled
  c) Integration error — wrong API contract, unexpected response shape, timeout not handled
  d) Data issue — corrupt or unexpected data in database
  e) Config/environment issue — wrong setting in a specific environment
  f) Design gap — the spec/architecture didn't account for this scenario
  g) Unknown — needs investigation"

**Question 5:** "Is there a workaround available while the fix is being developed? (yes/no — describe if yes)"

**Record all answers in the Root Cause Analysis section of FIX-NNN.md.**

**Design gap detection:** If the user selects option (f) — design gap:
Output:
```
ROOT CAUSE: Design Gap Detected
The root cause appears to be a specification or architecture gap, not a coding error.

Recommendation: After completing this fix, run the product spec phase (tell Claude to proceed) to update the product spec
with the missing requirement or constraint, then run tell Claude to verify to confirm consistency.

Proceeding with fix. A follow-up spec update is strongly recommended.
```
Note this recommendation in FIX-NNN.md.

---

## Step 4: Plan Phase

Generate a focused implementation plan for the fix at `$ARTIFACTS/plan/implementation-plan.md` (append if file exists, creating a new section for this fix).

The plan must include:

```markdown
## <FIX-NNN> Fix Plan: <problem description>
*Date: <ISO date>*

### Problem
<one-paragraph problem statement from root cause analysis>

### Root Cause
<root cause category and explanation>

### Fix Approach
<describe the specific code change required — which files, which functions, what changes>

### Tasks
| Task | File(s) | Description | Effort | Risk |
|------|---------|-------------|--------|------|
| TASK-NNN | <file> | <description> | S/M/L | LOW/MED/HIGH |

### Test Plan
- Reproduce the bug first (write a failing test before fixing)
- Apply the fix
- Confirm the previously failing test now passes
- Run the full test suite to verify no regressions

### Rollback Plan
<how to revert this change if the fix causes issues — especially important for hotfixes>

### Definition of Fixed
<specific, verifiable statement: "The system does X when Y, and TC-NNN passes">
```

**Task IDs:** Continue from the existing highest TASK-ID in implementation-plan.md. If no plan exists, start at TASK-001.

Update FIX-NNN.md Phase Status: plan → completed.

---

## Step 5: Build Phase

For hotfix mode:
- Output: "HOTFIX BUILD: Implementing fix with minimal footprint. Changes should be surgical — touch only what is required to fix the issue."
- Remind: document every file changed in FIX-NNN.md Notes section.

For standard/maintenance:
- Proceed with implementation per the plan tasks.

After build completes, update FIX-NNN.md:
- Phase Status: build → completed
- Fix Summary: brief description of what was changed

---

## Step 6: Test Cases Phase (Skip for Hotfix)

For `--hotfix`: skip this step. Note in FIX-NNN.md: "test-cases skipped (hotfix mode) — regression tests must be added in a follow-up FIX or ITER."

For bug fix and maintenance:

**Check existing test coverage:** Read `$ARTIFACTS/test-cases/test-cases.md` if it exists. Search for TC-IDs that should have caught this bug.

**Coverage gap reporting:**
- If an existing TC-ID covers this scenario: note it. Determine why it didn't catch the regression (test wasn't run? test was wrong? new code path?). Document in FIX-NNN.md.
- If no existing TC-ID covers this scenario: **this is a required gap to fill.** Create a regression test case.

**Regression test case format:**
Continue from the existing highest TC-ID sequence.

```markdown
### TC-NNN: [Fix NNN] Regression — <description>
**Type:** Regression
**Linked Fix:** <FIX-NNN>
**Priority:** P0

**Preconditions:** <system state>
**Steps:**
1. <action>
2. <action>
**Expected Result:** <what correct behavior looks like>
**Failure Indicator:** <what the bug looked like — confirms regression if seen>
```

Append to `$ARTIFACTS/test-cases/test-cases.md` (create if not exists).

Update FIX-NNN.md Regression Coverage table with new TC-IDs.
Update Phase Status: test-cases → completed.

---

## Step 7: Verify Phase

Run the verify check scoped to the files and artifacts touched by this fix:

1. Read all source files modified by the fix
2. Check: does the fix address the root cause described in the RCA section?
3. Check: does the fix introduce any new edge cases (null paths, concurrent access issues, error handling gaps)?
4. Check: are all new test cases well-formed and traceable?
5. For hotfix: check that the rollback plan is documented and actionable

Output verification result:
```
FIX-NNN VERIFY: <pass | fail>
Root cause addressed: <yes/no>
New edge cases introduced: <yes/no — describe if yes>
Regression coverage added: <TC-IDs or "deferred (hotfix)">
Rollback plan present: <yes/no>
```

Update FIX-NNN.md Phase Status: verify → completed.

---

## Step 8: Deploy Phase (Hotfix Only)

For `--hotfix` only: Output deploy guidance:
```
HOTFIX DEPLOY CHECKLIST
  [ ] Fix has been peer-reviewed (even a quick async review)
  [ ] Rollback plan confirmed with team
  [ ] Monitoring dashboards ready to watch after deploy
  [ ] Incident ticket updated with fix reference: <FIX-NNN>
  [ ] Deploy to staging environment first if possible
  [ ] Deploy to production
  [ ] Confirm fix resolves the incident
  [ ] Post-incident: schedule /sdlc:fix (without --hotfix) to add regression tests
```

Update FIX-NNN.md Phase Status: deploy → completed.

---

## Step 9: Complete the Fix

**Update FIX-NNN.md:**
- Status: completed
- Completed: ISO timestamp

**Update state.json:**
- Append to `autoChainLog`: `{ "fix": "<FIX-NNN>", "type": "<type>", "completedAt": "<ISO>" }`
- If a design gap was detected: append to `technicalDebts` array:
  ```json
  {
    "id": "TD-NNN",
    "description": "Design gap found during <FIX-NNN>: <description>",
    "severity": "HIGH",
    "phaseCreated": "fix",
    "status": "open",
    "recommendation": "Run the product spec phase (tell Claude to proceed) to update spec with missing requirement"
  }
  ```

**Final output:**
```
FIX-NNN Complete: <problem description>
Type: <bug-fix | hotfix | maintenance>
Root cause: <category>
Phases: <list>

Regression coverage:
  <TC-IDs added or "deferred (hotfix mode)">

Design gap found: <yes — TD-NNN added to debt register | no>

Manifest: .claude/ai-sdlc/ITERATIONS/<FIX-NNN>.md

Next:
  Run tell Claude to verify to confirm artifact consistency.
  Run tell Claude to create a release when ready to include this fix in a versioned release.
```
