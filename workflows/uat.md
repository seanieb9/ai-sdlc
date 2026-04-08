# UAT Workflow

Phase 13b stakeholder acceptance testing. Maps every acceptance criterion to human-executable UAT scenarios written in plain language. Produces entry/exit criteria and a sign-off record.

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

## Step 1: Gate Check

**HARD gate:** `$ARTIFACTS/verify/verification-report.md` must exist. If missing: STOP. Tell the user to run `/sdlc:verify` to complete the verification phase first.

Read the verification report and check for open CRITICAL findings. If any CRITICAL findings remain unresolved: STOP. List the open criticals and tell the user they must be resolved before UAT can begin.

Read in parallel (after gate passes):
- `$ARTIFACTS/idea/prd.md` — acceptance criteria (required for UAT scenario mapping)
- `$ARTIFACTS/journey/customer-journey.md` — user flows and personas (if exists)
- `$ARTIFACTS/verify/verification-report.md` — findings context

If prd.md is missing: WARN but continue — UAT scenarios will be less precise. Note the gap in the UAT plan.

**Execution mode:** INTERACTIVE.

---

## Step 2: Extract Acceptance Criteria

Read prd.md and extract every acceptance criterion. Acceptance criteria appear under sections like:
- "Acceptance Criteria"
- "Done when..."
- "Success criteria"
- "Must..."

List all criteria with their source (REQ-ID or section reference):

| # | Source | Acceptance Criterion |
|---|--------|---------------------|
| 1 | REQ-001 | [criterion text] |
| 2 | REQ-002 | [criterion text] |

If customer-journey.md exists: also extract every journey happy path as an implicit acceptance criterion.

---

## Step 3: Map Criteria to UAT Scenarios

Assign UAT-NNN IDs (UAT-001, UAT-002, ...) to each scenario. One acceptance criterion may map to one or more UAT scenarios. Some scenarios may cover multiple related criteria.

For each UAT scenario:

```
UAT-NNN: [Scenario Name]
Persona:       [who performs this test — non-technical role name]
Source:        [REQ-ID or journey step]
Preconditions: [system state before test — what data/config must be set up]
Steps:
  1. [Human-executable action — no code, no technical jargon]
  2. [Next action]
  3. [Continue...]
Expected result: [What success looks like — visible to the tester]
Pass/Fail: ___
Notes:     [edge cases or variations the tester should also try]
```

Rules:
- Steps must be executable by a non-technical stakeholder
- No references to APIs, database queries, or code
- Use business language: "Click the Submit Order button" not "POST /orders"
- Expected result must be observable in the UI or system output — not an internal state
- Every P0 user journey must have at least one UAT scenario

---

## Step 4: Define Entry and Exit Criteria

**Entry criteria** (what must be true before UAT begins):

- [ ] Test environment is deployed and accessible at [URL/location]
- [ ] Test data is loaded (user accounts, seed records, configuration)
- [ ] All CRITICAL verification findings are resolved (confirmed in step 1)
- [ ] UAT testers have been identified and have access credentials
- [ ] UAT plan has been reviewed and approved by stakeholders
- [ ] Any required integrations are configured for the test environment

Add any project-specific entry criteria identified from the architecture or prd.

**Exit criteria** (what must be true to call UAT complete):

- [ ] All P0 UAT scenarios have been executed
- [ ] All P0 scenarios have a Pass result
- [ ] No more than [N] P1 scenarios have a Fail result (adjust based on project risk tolerance)
- [ ] All defects found during UAT are triaged (P0 defects resolved, P1 defects have owners)
- [ ] Sign-off obtained from [stakeholder role(s)]

---

## Step 5: Define Test Data Requirements

List the test data needed to execute every UAT scenario. Be specific — testers should be able to set up the environment from this list without asking for help.

| Data Item | Purpose | Required Values | Source/How to Create |
|-----------|---------|-----------------|---------------------|
| [item] | [which UAT scenarios need this] | [specific values] | [manual setup / script / seed file] |

---

## Step 6: Write Artifact

Write `$ARTIFACTS/uat/uat-plan.md`:

```markdown
# UAT Plan: [Feature / Project Name]
*Date: [ISO date]*
*Branch: [branch]*
*Scenarios: [N total]*

---

## UAT Overview

[2-3 sentence description of what is being tested and who will perform testing]

**Scope:** [what is in scope for this UAT round]
**Out of scope:** [what is explicitly excluded]

---

## Entry Criteria

- [ ] Test environment is deployed and accessible
- [ ] Test data is loaded (see Test Data Requirements section)
- [ ] All CRITICAL verification findings are resolved
- [ ] UAT testers have been identified and have access
- [ ] UAT plan has been reviewed by stakeholders
[additional project-specific criteria]

---

## Exit Criteria

- [ ] All P0 UAT scenarios executed and passing
- [ ] All P1 UAT scenarios executed (failures triaged with owners)
- [ ] No open P0 defects
- [ ] Sign-off obtained from: [stakeholder roles]

---

## Scenario Matrix

| UAT-ID | Scenario Name | Persona | Source | Priority | Pass/Fail |
|--------|--------------|---------|--------|----------|-----------|
| UAT-001 | [name] | [persona] | REQ-001 | P0 | ___ |
...

---

## UAT Scenarios

### UAT-001: [Scenario Name]
**Persona:** [role]
**Source:** [REQ-ID]
**Preconditions:**
- [condition 1]
- [condition 2]

**Steps:**
1. [step]
2. [step]
3. [step]

**Expected result:** [observable outcome]

**Pass/Fail:** ___
**Tester notes:** ___

---
[repeat for each scenario]

---

## Test Data Requirements

| Data Item | Purpose | Required Values | How to Create |
|-----------|---------|-----------------|---------------|
...

---

## Sign-off Record

| Role | Name | Date | Signature/Approval |
|------|------|------|-------------------|
| [stakeholder role] | _______________ | __________ | ______________ |
| [stakeholder role] | _______________ | __________ | ______________ |

---

## Defect Tracking

| Defect ID | UAT-ID | Description | Severity | Status | Owner |
|-----------|--------|-------------|----------|--------|-------|
| (fill during testing) | | | | | |
```

---

## Step 7: Update State

Update `$STATE` (state.json):
- Set `phases.uat.status` = `"completed"`
- Set `phases.uat.completedAt` = current ISO timestamp
- Set `phases.uat.artifacts` = `["uat-plan.md"]`
- Set `phases.uat.signedOffBy` = `null` (populated by --sign-off flow below)
- Set `updatedAt` = current ISO timestamp

---

## Step 7b: Sign-off Flow (--sign-off flag)

If `$ARGUMENTS` contains `--sign-off`:

1. Read `$ARTIFACTS/uat/uat-plan.md` to confirm it exists
2. Ask the user: "Who is signing off on this UAT? (Enter full name and role)"
3. Record the sign-off:
   - Update the Sign-off Record table in uat-plan.md with the name, role, and current date
   - Update state.json: set `phases.uat.signedOffBy` = `"[name] ([role]) — [ISO date]"`
   - Set `updatedAt` = current ISO timestamp

Output:
```
UAT Sign-off Recorded

Signed off by: [name] ([role])
Date: [date]
Artifact updated: $ARTIFACTS/uat/uat-plan.md

UAT is now complete. Ready for deployment:
  → /sdlc:deploy
```

---

## Step 8: Checkpoint

```
UAT Plan Complete
═════════════════
Scenarios:     [N total] ([N] P0, [N] P1, [N] P2)
Acceptance criteria covered: [N] / [total]
Open gaps:     [N]

Artifact: $ARTIFACTS/uat/uat-plan.md

Distribute the UAT plan to your stakeholders.
When testing is complete and sign-off is obtained, run:
  ask Claude to run the UAT workflow --sign-off

Then continue to:
  → /sdlc:deploy
```
