# Traceability Workflow

Builds a bidirectional requirements traceability matrix linking REQ-IDs → TC-IDs → ADR-IDs → OBS-IDs. Surfaces orphaned test cases and uncovered requirements.

---

## Step 0: Workspace Resolution

@/Users/seanlew/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/traceability"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Read All Source Artifacts

Read in parallel:
- `$ARTIFACTS/idea/prd.md` — REQ-NNN and NFR-NNN identifiers, acceptance criteria
- `$ARTIFACTS/test-cases/test-cases.md` — TC-NNN identifiers and linked REQ-IDs
- `$ARTIFACTS/design/tech-architecture.md` — ADR-NNN identifiers and the requirements they address
- `$ARTIFACTS/design/solution-design.md` — additional ADR-NNN entries (if exists)
- `$ARTIFACTS/observability/observability.md` — OBS-NNN identifiers and linked SLOs/NFRs (if exists)

Build four inventories:

**REQ inventory:**
```
REQ-ID: [identifier]
Title: [brief description]
Type: [Functional / NFR]
Priority: [MUST / SHOULD / COULD]
Acceptance criteria count: [N]
```

**TC inventory:**
```
TC-ID: [identifier]
Title: [brief description]
Layer: [test layer]
REQ references: [list of REQ-IDs this TC covers]
```

**ADR inventory:**
```
ADR-ID: [identifier]
Title: [decision title]
REQ references: [which REQ-IDs or NFR-IDs drove this decision]
Status: [Accepted / Draft / Superseded]
```

**OBS inventory (if observability.md exists):**
```
OBS-ID: [identifier]
Title: [log/metric/alert name]
NFR reference: [which NFR-ID this monitors]
SLO: [target value if specified]
```

---

## Step 2: Build REQ → TC Matrix

For each REQ-ID:
1. Find all TC-IDs that list this REQ-ID in their "covers" or "related requirements" field
2. Also search for TCs that mention the REQ-ID anywhere in their description (looser match — note as "indirect")
3. Record coverage status:
   - COVERED: ≥1 TC directly references this REQ
   - INDIRECT: only indirect references found
   - UNCOVERED: no TC references this REQ

---

## Step 3: Build REQ → ADR Matrix

For each REQ-ID (especially NFR-NNNs):
1. Find all ADR-IDs that reference this REQ/NFR as a driver
2. Also check: does the ADR's Context section describe a constraint that matches this REQ?
3. Record:
   - LINKED: ADR explicitly references this REQ
   - INFERRED: ADR likely addresses this REQ based on content
   - NONE: no ADR maps to this REQ

---

## Step 4: Build NFR → ADR → TC → SLO Chain

For each NFR-NNN specifically:

1. Find ADR(s) that address this NFR (from Step 3)
2. Find TC(s) that validate this NFR (from Step 2 — performance, security, and load test layers)
3. Find OBS-ID(s) that monitor this NFR (from OBS inventory)
4. Mark the chain:
   - COMPLETE: NFR → ≥1 ADR → ≥1 TC → ≥1 OBS-ID
   - PARTIAL: some links missing
   - BROKEN: missing ADR or TC or both

A broken chain means the NFR has been stated but not properly architected, tested, or monitored.

---

## Step 5: Find Gaps

### Orphaned TCs
TC-IDs that do not reference any REQ-ID. These tests exist but have no traceable requirement.
- Could be valid exploratory tests — but they must be explicitly linked or documented as exploratory.
- Severity: WARNING

### Uncovered REQs
REQ-IDs with no TC (UNCOVERED status from Step 2).
- MUST priority uncovered = CRITICAL
- SHOULD priority uncovered = WARNING
- COULD priority uncovered = INFO

### ADR-less NFRs
NFR-NNNs with no ADR (NONE status from Step 3).
- These NFRs were stated but never architecturally addressed.
- Severity: WARNING

### Broken NFR chains
NFRs missing any link in the NFR → ADR → TC → OBS chain.
- Severity: WARNING (CRITICAL if it's a compliance or availability NFR)

---

## Step 6: Write Artifact

Write `$PHASE_ARTIFACTS/traceability-matrix.md`:

```markdown
# Requirements Traceability Matrix
*Generated: [date] | Branch: [branch]*

## Coverage Overview

| Dimension | Total | Covered | Partial | Uncovered |
|-----------|-------|---------|---------|-----------|
| REQ → TC | [N] | [N] ([%]) | [N] | [N] |
| NFR → ADR | [N] | [N] ([%]) | [N] | [N] |
| NFR chains (→ADR→TC→OBS) | [N] | [N] complete | [N] partial | [N] broken |

## REQ → TC Matrix

| REQ-ID | Title | Priority | TC-IDs | Coverage Status |
|--------|-------|----------|--------|-----------------|
[all REQs — one row each]

## NFR Traceability Chain

| NFR-ID | Description | ADR-ID | TC-IDs | OBS-ID | Chain Status |
|--------|-------------|--------|--------|--------|-------------|
[all NFRs — one row each, COMPLETE/PARTIAL/BROKEN]

## REQ → ADR Mapping

| REQ-ID | Title | ADR-IDs | Link Type |
|--------|-------|---------|-----------|
[REQs that have ADR coverage]

## CRITICAL: Uncovered Requirements

| REQ-ID | Title | Priority | Missing Coverage |
|--------|-------|----------|------------------|
[UNCOVERED + MUST priority only]

## WARNING: Orphaned Test Cases

| TC-ID | Title | Layer | Recommendation |
|-------|-------|-------|----------------|
[TCs with no REQ reference]

## WARNING: ADR-less NFRs

| NFR-ID | Description | Recommendation |
|--------|-------------|----------------|
[NFRs with no ADR]

## WARNING: Broken NFR Chains

| NFR-ID | Missing Link | Impact |
|--------|-------------|--------|
[NFRs where the chain is incomplete]
```

---

## Step 7: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "traceability",
  "triggeredAfter": "test-cases",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/traceability-matrix.md",
  "summary": "<N> REQs traced, <X> uncovered, <Y> orphaned TCs, <Z> broken NFR chains",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 8: Output

If `--auto-chain`:
```
✅ traceability — <N> REQs, <X> uncovered, <Y> orphaned TCs [<PHASE_ARTIFACTS>/traceability-matrix.md]
```

If interactive:
```
✅ Traceability Matrix Complete

Requirements traced: [N total]
  Fully covered:  [N] ([%])
  Partial:        [N]
  Uncovered:      [N] — [M] CRITICAL (MUST priority)

NFR chains (→ADR→TC→OBS):
  Complete: [N] | Partial: [N] | Broken: [N]

Orphaned test cases (no source REQ): [N]
ADR-less NFRs: [N]

Matrix: <PHASE_ARTIFACTS>/traceability-matrix.md
```
