# Retro Workflow

Phase 16 project retrospective. Reads the full state history and all artifacts to construct a blameless retrospective. Everything is sourced from real data — phase timestamps, gate overrides, autoChainLog, decisions, and technical debts. Nothing is invented.

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

## Step 1: Load Full Project History

Read `$STATE` (state.json) in full. Extract:
- `projectName` and `intentType`
- All `phases` entries: `status`, `completedAt`, `artifacts`
- `decisions` array
- `gateOverrides` array
- `technicalDebts` array
- `autoChainLog` array
- `createdAt` and `updatedAt`

Read all artifacts that exist — in parallel:

```bash
ls $ARTIFACTS/*/  2>/dev/null
```

Read each artifact file that exists (skip missing ones silently). These provide substantive content for the retrospective:
- `$ARTIFACTS/feasibility/feasibility.md`
- `$ARTIFACTS/research/research.md`
- `$ARTIFACTS/idea/prd.md`
- `$ARTIFACTS/design/tech-architecture.md`
- `$ARTIFACTS/verify/verification-report.md`
- `$ARTIFACTS/maintain/maintenance-plan.md`
- Any other artifact files present

**Incident mode check:** If `$ARGUMENTS` contains `--incident`: frame the retro as a post-mortem. Add contributing factors analysis and a more detailed timeline. Tone remains blameless — focus on systems and processes, not individuals.

---

## Step 2: Construct the Timeline

Build a chronological narrative from phase `completedAt` timestamps.

For each phase with status `"completed"`:
1. Calculate duration: `completedAt` - previous phase's `completedAt` (or `createdAt` for the first phase)
2. Record phase name, completion date, duration, and artifacts produced

Format:

| Phase | Completed At | Duration | Artifacts Produced |
|-------|-------------|----------|--------------------|
| feasibility | [date] | [Nd Nh] | feasibility.md |
| research | [date] | [Nd Nh] | research.md, gap-analysis.md |
| ... | | | |

**Total project duration:** from `createdAt` to the most recent `completedAt`.

---

## Step 3: Gather Retrospective Data

Scan state.json for signals in each category:

### Gate Overrides
Read `gateOverrides` array. Each entry represents a moment where the team chose to bypass a phase gate.

For each override, note:
- Which gate was overridden
- What reason was given (if recorded)
- What risk was accepted

### Auto-Chain Failures
Read `autoChainLog` array. Entries with `status = "failed"` represent phases that were attempted but did not complete automatically and needed intervention.

### Technical Debts
Read `technicalDebts` array. These were incurred deliberately during the build.

### Decisions
Read `decisions` array. These are the key architectural and product decisions recorded during the project. They represent intentional choices and trade-offs.

### Stale Phases
Check if any phase has `"stale": true` — these indicate phases that were completed but then invalidated by a downstream change.

---

## Step 4: Write the Retrospective

Retrospective is blameless. Use "the team," "the process," "the system" — never individual names unless attributing ownership of an action item (with their consent implied by assignment).

Structure for each section:

### What Went Well
- Phases completed smoothly (no gate overrides, no retries)
- Good artifacts produced (complete, no gaps found in verify)
- Decisions that paid off
- Dependencies that caused no issues

### What Was Difficult
- Gate overrides that were required (each is a process friction point)
- Auto-chain failures (what caused them, what the resolution was)
- Phases with stale status (what invalidated them, rework cost)
- Technical debts incurred (what trade-offs were accepted and why)

### What Surprised Us
- Unexpected complexity discovered mid-phase
- Dependencies that behaved unexpectedly
- Scope that grew larger than the initial estimate
- Findings in the verify phase that were surprising

### What Would We Do Differently
- Derive from "What Was Difficult" — each difficulty should have a proposed change
- Be specific: not "communicate better" but "run stakeholder alignment session before data-model phase"

### Action Items
For each proposed change, create an action item with:
- What: specific action
- Owner: role (not name unless explicitly assigning to someone)
- Due date: relative (e.g., "before next project start," "Q2")
- Priority: P0 / P1 / P2

---

## Step 5: Write Artifact

Write `$ARTIFACTS/retro/retro.md`:

```markdown
# Project Retrospective: [Project Name]
*Date: [ISO date]*
*Branch: [branch]*
*Facilitated by: AI-SDLC System*

---

## Project Summary

| Metric | Value |
|--------|-------|
| Project started | [createdAt date] |
| Project completed | [last completedAt date] |
| Total duration | [N days] |
| Phases completed | [N] / [total phases in workflow] |
| Phases skipped | [list or "none"] |
| Gate overrides | [N] |
| Technical debts incurred | [N] |
| Decisions recorded | [N] |

---

## Timeline

| Phase | Completed | Duration | Artifacts |
|-------|-----------|----------|-----------|
[rows from Step 2]

---

## What Went Well

[Blameless narrative — bullet points with evidence from state.json and artifacts]

---

## What Was Difficult

[Blameless narrative — each difficulty sourced from gate overrides, auto-chain failures, stale phases, or tech debt]

---

## What Surprised Us

[Unexpected findings, scope changes, complexity discoveries]

---

## What Would We Do Differently

[Specific, actionable process changes. Each paired with a "What Was Difficult" item above]

---

## Key Decisions Made

| Decision | Rationale | Trade-off Accepted |
|----------|-----------|-------------------|
[from decisions array in state.json]

---

## Action Items

| # | Action | Owner | Due | Priority |
|---|--------|-------|-----|----------|
| 1 | [specific action] | [role] | [relative date] | P0/P1/P2 |
[additional rows]

---

## Artifacts Produced This Project

| Phase | Artifact | Path |
|-------|----------|------|
[all artifacts from phases array]
```

---

## Step 6: Update State

Update `$STATE` (state.json):
- Set `phases.retro.status` = `"completed"`
- Set `phases.retro.completedAt` = current ISO timestamp
- Set `phases.retro.artifacts` = `["retro.md"]`
- Set `updatedAt` = current ISO timestamp

---

## Step 7: Close the Workflow

Congratulate the user and present a summary of everything produced.

```
Retrospective Complete — Project Closed
════════════════════════════════════════
Project: [projectName]
Duration: [N days]
Phases completed: [N]
Artifacts produced: [N]

What went well: [N] items
What was difficult: [N] items
Action items: [N]

Retro artifact: $ARTIFACTS/retro/retro.md

════════════════════════════════════════
All artifacts produced this project:
[list each artifact with its path]

════════════════════════════════════════
Suggested next steps:
  → Archive this workflow:
    cp -r $WORKSPACE .claude/ai-sdlc/history/$(date +%Y-%m-%d)-[project-name]

  → Start a new project or feature:
    /sdlc:00-start

Thank you for using AI-SDLC.
```
