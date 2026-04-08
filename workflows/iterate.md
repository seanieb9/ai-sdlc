# Iterate Workflow

Scoped mini-lifecycle for adding or evolving features. Classifies the iteration type, determines which phases are relevant, tracks the iteration as ITER-NNN, runs each phase in scope, and produces a completion manifest.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

**Initialization guard:** After resolving the workspace, verify that `$STATE` exists and that at least the `idea` phase has `status: "completed"` in state.json. If not:
- If state.json does not exist: STOP. Output: "No initialized workspace found on branch `$BRANCH`. Run /sdlc:00-start to begin a project first."
- If idea phase is not completed: WARN. Output: "The idea/spec phase has not been completed. Iterations are most effective after the initial product spec exists. Proceeding anyway — you may need to create a new spec rather than iterate."

Also create the ITERATIONS directory:
```bash
mkdir -p ".claude/ai-sdlc/ITERATIONS"
```

---

## Step 1: Classify Iteration Type

**Parse $ARGUMENTS:**
- Extract the feature description (everything before flags)
- Extract `--type` value if present
- Check for `--voc` flag
- Check for `--auto` flag

**If --type is provided:** use it directly.

**If --type is not provided:** infer from the feature description using these heuristics:
- Keywords like "add", "create", "new", "introduce", "build" → `new`
- Keywords like "improve", "enhance", "extend", "update", "expand", "support" → `enhancement`
- Keywords like "performance", "latency", "throughput", "scale", "security", "compliance" → `nfr`
- Keywords like "schema", "migration", "column", "table", "field", "index" → `data`
- Keywords like "screen", "UI", "page", "journey", "flow", "layout", "design" → `ux`
- Default fallback: `enhancement`

**Determine phase scope by type:**

| Type | Phases in Scope |
|------|----------------|
| `new` | idea → data-model → design → plan → build → test-cases → test-gen → verify → deploy |
| `enhancement` | idea → data-model? → design? → plan → build → test-cases → test-gen → verify |
| `nfr` | idea → design → test-cases → observability → sre |
| `data` | data-model → design → plan → build → test-cases → test-gen |
| `ux` | journey → design? → plan → build → test-cases → test-gen |

For `enhancement`: phases marked `?` are conditional — include data-model if the description mentions entities/fields, include design if it mentions architecture changes.

For `ux`: phase `design?` is conditional — include if the description mentions new components or layout patterns.

If `--voc` flag is present: prepend `voc` phase to the scope, then `idea`, then continue per type.

---

## Step 2: Generate ITER-NNN ID

**Find the next sequential ID:**
```bash
ls .claude/ai-sdlc/ITERATIONS/ITER-*.md 2>/dev/null | sort | tail -1
```

Parse the highest existing number. Next ID is that number + 1, zero-padded to 3 digits (e.g., ITER-001, ITER-002, ITER-047).

If no ITER files exist, start at ITER-001.

**Create the iteration manifest** at `.claude/ai-sdlc/ITERATIONS/<ITER-NNN>.md`:

```markdown
# <ITER-NNN>: <feature description>

| Field | Value |
|-------|-------|
| ID | <ITER-NNN> |
| Type | <type> |
| Branch | <$BRANCH> |
| Status | in-progress |
| Started | <ISO date> |
| Completed | — |
| Breaking Change | false |

## Description
<feature description from $ARGUMENTS>

## Phases in Scope
<ordered list of phases>

## Phase Status
| Phase | Status | Completed At | Notes |
|-------|--------|--------------|-------|
<one row per phase, all initially: pending | — | — >

## IDs Introduced
| Type | IDs | Description |
|------|-----|-------------|
(populated as phases complete)

## Notes
(added during execution)
```

---

## Step 3: Scope Assessment

Read the following files in parallel (if they exist):
- `$ARTIFACTS/idea/prd.md`
- `$ARTIFACTS/data-model/data-model.md`
- `$ARTIFACTS/design/tech-architecture.md`
- `$ARTIFACTS/test-cases/test-cases.md`

**Determine scope impact:**

1. **Entity impact:** Does the description touch any existing entities named in data-model.md?
   - If yes: flag `touches_existing_entities = true`
   - Check whether data-model phase should be included (for enhancement type) or is already in scope

2. **ID sequence continuity:** What is the current highest REQ-ID, NFR-ID, TC-ID, TASK-ID?
   - Note these numbers so new IDs continue from the correct sequence
   - Output: "Continuing from REQ-NNN, NFR-NNN, TC-NNN, TASK-NNN"

3. **Breaking change detection:** Does the description imply:
   - Removing or renaming existing API fields?
   - Changing existing entity fields (non-additive)?
   - Modifying existing business rules in a backward-incompatible way?

   If yes: set `breaking_change = true`. Update ITER-NNN.md to reflect `Breaking Change: true`.

   **Require explicit user confirmation before proceeding:**
   Use AskUserQuestion: "This iteration appears to introduce breaking changes: [list specific breaking aspects]. This may require coordinated deployment and consumer updates. Confirm you want to proceed? (yes/no)"

   If user says no: STOP. Output: "Iteration paused. Reconsider the approach or ask Claude to compare backward-compatible alternatives."

4. **Show scope summary to user:**
   ```
   ITER-NNN: <description>
   Type: <type>
   Phases: <N> phases in scope: <phase list>

   Impact assessment:
   - Touches existing entities: <yes/no — entity names>
   - Breaking changes: <yes/no>
   - ID sequence: REQ continues from NNN, TC continues from NNN

   Artifacts that will be updated: <list>

   Continue? (yes/no)
   ```

   If `--auto` flag is set: skip this confirmation and proceed.

   Use AskUserQuestion for the confirmation (unless --auto).

---

## Step 4: Execute Phases in Scope

For each phase in the scope list (in order):

**Phase execution model:**
- Some phases run autonomously in this workflow (idea, data-model, plan, build, test-cases, test-gen, verify, deploy)
- Some phases require the user to run the dedicated command (design, observability, sre, journey, voc) because they produce interactive or complex outputs

**For autonomous phases (idea, plan, test-cases, test-gen, verify):**
Execute the phase inline following the relevant phase workflow from `~/.claude/sdlc/workflows/`. Use the iteration scope as context — do not re-run the full project-level phase; scope it to the feature being added.

Specifically:
- **idea phase**: Produce a scoped addition to prd.md — new REQ-IDs, NFR-IDs, and BDD scenarios for the feature only. Append to existing prd.md, do not replace it.
- **data-model phase**: Produce only the new entities/fields required. Append to data-model.md.
- **plan phase**: Produce only the tasks needed for this iteration. Append to implementation-plan.md or create a new scoped plan at `$ARTIFACTS/plan/implementation-plan-<ITER-NNN>.md`.
- **test-cases phase**: Produce test cases for new/changed behavior only, continuing from the existing TC-ID sequence.
- **test-gen phase**: Scaffold automation stubs for the new test cases.
- **verify phase**: Verify only the artifacts touched by this iteration.

**For checkpoint phases (design, observability, sre, journey, voc, build, deploy):**
Output to the user: "Phase `<phase>` requires interactive work. Please run `/sdlc:<phase>` now, then return here."

If `--auto` flag is set: skip the pause and note in ITER-NNN.md that the phase was marked pending and must be completed manually.

**After each phase (whether run inline or deferred to user):**
Update the Phase Status table in ITER-NNN.md:
- Status: `completed` (inline) or `deferred` (checkpoint)
- CompletedAt: ISO timestamp for completed phases

---

## Step 5: Stale Cascade Check

After all phases complete, check if any upstream phases may have been made stale by this iteration:

- If data-model was modified → mark `design` phase as `stale: true` in state.json (architecture may need review)
- If prd.md was modified with new REQ-IDs → mark `test-cases` phase as `stale: true` if test-cases predates this iteration
- If API surface changed → mark `test-gen` as `stale: true`

For any stale phases, output a warning:
```
WARNING: The following phases may be stale due to this iteration's changes:
  - <phase>: <reason>
Run /sdlc:verify --phase <phase> to confirm or /sdlc:<phase> to refresh.
```

---

## Step 6: Complete the Iteration

**Update state.json:**
- Append to `autoChainLog` array: `{ "iter": "<ITER-NNN>", "type": "<type>", "phases": [...], "completedAt": "<ISO timestamp>" }`
- Update `updatedAt`

**Update ITER-NNN.md:**
- Set `Status: completed`
- Set `Completed: <ISO timestamp>`
- Populate the IDs Introduced table with all new REQ-IDs, NFR-IDs, TC-IDs, TASK-IDs produced

**Final output:**
```
ITER-NNN Complete: <feature description>
Type: <type>
Phases completed: <N>/<N>
Deferred phases: <list or "none">

IDs introduced:
  REQ: <list or "none">
  NFR: <list or "none">
  TC: <list or "none">
  TASK: <list or "none">

Breaking changes: <yes/no>
Stale phases: <list or "none">

Manifest: .claude/ai-sdlc/ITERATIONS/<ITER-NNN>.md

Next: Run /sdlc:verify to confirm all artifacts are consistent.
      Run /sdlc:release when ready to version this and other completed iterations.
```
