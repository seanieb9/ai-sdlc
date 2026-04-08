# Test Gaps Workflow

Analyses test coverage by mapping every requirement and acceptance criterion to test cases. Identifies uncovered requirements, missing test layers, and API endpoints without contract tests.

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/test-gaps"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Read Source Artifacts

Read in parallel:
- `$ARTIFACTS/idea/prd.md` — REQ-IDs and acceptance criteria
- `$ARTIFACTS/test-cases/test-cases.md` — TC-IDs and which REQ they cover
- `$ARTIFACTS/design/api-spec.md` — API endpoints (if exists)

If test-cases.md does not exist: note it as a critical gap (0% coverage) and proceed to generate a full gap report.

Build inventories:

**Requirements inventory** (from prd.md):
```
REQ-ID: [identifier]
Title: [brief title]
Acceptance criteria: [count of explicit AC items]
Priority: [MUST / SHOULD / COULD]
```

**Test case inventory** (from test-cases.md):
```
TC-ID: [identifier]
Title: [brief title]
Covers: [REQ-IDs referenced]
Type/Layer: [Unit / Integration / Contract / E2E / Performance / Security / UAT / Regression / Smoke]
```

**API endpoint inventory** (from api-spec.md):
```
Endpoint: [METHOD /path]
Has contract test: [yes/no]
```

---

## Step 2: Gap Analysis

### 2a: REQ → TC Coverage

For each REQ-ID in the requirements inventory:
- Find all TC-IDs that reference this REQ-ID
- An acceptance criterion is "covered" if at least one TC explicitly tests that criterion
- Mark as:
  - COVERED: ≥1 TC covers this REQ and its ACs
  - PARTIAL: some ACs covered but not all
  - UNCOVERED: no TC references this REQ at all

Flag UNCOVERED requirements of priority MUST as CRITICAL findings.
Flag UNCOVERED requirements of priority SHOULD as WARN findings.
Flag all PARTIAL coverage as WARN.

### 2b: Test Layer Coverage

The 9 required test layers are:
1. Unit — individual functions/classes in isolation
2. Integration — service + real dependencies (DB, queue)
3. Contract — API schema and consumer-driven contracts
4. End-to-End — full user journey through the system
5. Performance — load, stress, throughput validation
6. Security — auth bypass, injection, OWASP checks
7. UAT — acceptance criteria confirmed by stakeholder
8. Regression — previously fixed bugs don't reappear
9. Smoke — basic health checks post-deploy

For each layer: does at least one TC-ID exist for that layer? If not: flag as WARN.

### 2c: API Contract Coverage

For each endpoint in api-spec.md:
- Is there a TC-ID of type "Contract" that covers this endpoint?
- Missing contract tests = WARN

### 2d: Orphaned Test Cases

For each TC-ID: does it reference at least one REQ-ID? If not, it is an orphaned test case — it exists but has no traceable requirement. Flag as INFO (it may be valid exploratory testing, but it should be explicitly linked).

### 2e: Thin Coverage

A REQ is "thin" if it has exactly one TC (single point of coverage — one failure hides the gap). Flag as INFO.

---

## Step 3: Coverage Metrics

Calculate:

```
Total REQs: [N]
Fully covered: [N] ([%])
Partially covered: [N] ([%])
Uncovered: [N] ([%])

MUST requirements covered: [N/total] ([%])
SHOULD requirements covered: [N/total] ([%])

Test layers represented: [N/9]
Missing layers: [list]

API endpoints with contract tests: [N/total] ([%])
Orphaned TCs: [N]
Thin coverage REQs: [N]
```

---

## Step 4: Write Artifact

Write `$PHASE_ARTIFACTS/test-gap-report.md`:

```markdown
# Test Coverage Gap Report
*Generated: [date] | Branch: [branch]*

## Coverage Summary

| Metric | Value | Status |
|--------|-------|--------|
| REQ coverage (all) | [N]% | [✅/⚠️/❌] |
| MUST REQ coverage | [N]% | [✅/⚠️/❌] |
| Test layers represented | [N]/9 | [✅/⚠️/❌] |
| API contract coverage | [N]% | [✅/⚠️/❌] |
| Orphaned TCs | [N] | [✅/⚠️] |

## CRITICAL: Uncovered Requirements

| REQ-ID | Title | Priority | Acceptance Criteria | Recommended TC |
|--------|-------|----------|--------------------|--------------  |
[only UNCOVERED + priority MUST]

## WARNING: Partial Coverage

| REQ-ID | Title | Covered ACs | Missing ACs | TC-IDs Existing |
|--------|-------|-------------|-------------|-----------------|
[PARTIAL coverage rows]

## Missing Test Layers

| Layer | Status | Impact | Recommendation |
|-------|--------|--------|----------------|
[one row per missing layer]

## API Contract Coverage

| Endpoint | Method | Has Contract Test | TC-ID |
|----------|--------|------------------|-------|
[all endpoints, showing gap]

## REQ → TC Coverage Matrix

| REQ-ID | Title | Priority | TC-IDs | Coverage |
|--------|-------|----------|--------|----------|
[all REQs with their mapped TC-IDs]

## Orphaned Test Cases (no source REQ)

| TC-ID | Title | Recommendation |
|-------|-------|---------------|
[TCs with no REQ reference]

## Recommendations

### Immediate (CRITICAL — block release)
[numbered list of actions for uncovered MUST requirements]

### Before Release (WARN)
[numbered list for partial coverage and missing layers]

### Backlog (INFO)
[orphaned TCs, thin coverage, nice-to-have contract tests]
```

---

## Step 5: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "test-gaps",
  "triggeredAfter": "build",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/test-gap-report.md",
  "summary": "<N>% REQ coverage, <X> uncovered MUST reqs, <Y>/9 layers present",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 6: Output

If `--auto-chain`:
```
✅ test-gaps — <N>% coverage, <X> CRITICAL gaps, <Y>/9 layers [<PHASE_ARTIFACTS>/test-gap-report.md]
```

If interactive:
```
✅ Test Gap Analysis Complete

Coverage: [N]% REQs covered ([M] MUST / [total MUST])
Test layers: [N]/9 present

CRITICAL findings: [N] uncovered MUST requirements
  [list REQ-IDs]

WARN findings: [N] partial coverage, [N] missing layers
  Missing layers: [list]

API contract gaps: [N] endpoints without contract tests

Report: <PHASE_ARTIFACTS>/test-gap-report.md
```
