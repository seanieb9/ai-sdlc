# Squad Workflow

Team-level dashboard showing all active SDLC workflows across branches. Reads all state.json files, presents a consolidated table, and highlights branches that need attention.

---

## Step 0: Find All Workflows

Use Glob to find all state.json files:

Pattern: `.claude/ai-sdlc/workflows/*/state.json`

If no files are found:
```
No active SDLC workflows found in this project.

To start a new workflow:
  Run /sdlc:start <idea> to begin a new project or feature.
```
STOP.

---

## Step 1: Read All state.json Files in Parallel

Read each discovered state.json file simultaneously.

For each state.json, extract:
- `branch` — the sanitized branch name
- `rawBranch` — the original git branch name (if present)
- `projectName` — the project or feature name
- `intentType` — new-project | new-feature | bug-fix | refactor | documentation
- `currentPhase` — the current active phase (may be null)
- `updatedAt` — last update timestamp
- `phases` — the full phase map (to compute completedPhases count and detect stale phases)
- `checkpoint.nextPhase` — if set, shows what's queued next
- `technicalDebts` — count of open debt items

---

## Step 2: Compute Per-Branch Metrics

For each workspace, compute:

**completedPhases:** count of phases where `status === "completed"`

**totalPhases:** count of phases where `status !== "pending"` (i.e., started or completed)

**progress:** `completedPhases / 22` (total possible phases) as percentage

**stalePhasesCount:** count of phases where `stale === true`

**lastUpdatedDays:** number of days since `updatedAt` (use current date)

**branch status:** classify each branch into one of:
- `ACTIVE` — updated within the last 3 days
- `STALE` — last updated 4–14 days ago
- `DORMANT` — last updated > 14 days ago
- `BLOCKED` — has any phase with `status === "blocked"` OR has a gate override with a pending reason
- `REVIEW-READY` — currentPhase is `review` or `verify` or `uat`

**openDebts:** count of entries in `technicalDebts` array where `status === "open"`

---

## Step 3: Display Team Dashboard

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║  SQUAD DASHBOARD                                                                 ║
║  Project root: <cwd>    Workflows found: <N>    Date: <date>                     ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  Branch              Intent          Current Phase    Progress   Status    Days  ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  <branch>            <intentType>    <currentPhase>   <N>/<22>   ACTIVE    <N>d ║
║  <branch>            <intentType>    <currentPhase>   <N>/<22>   STALE    <N>d  ║
║  <branch>            <intentType>    <currentPhase>   <N>/<22>   BLOCKED  <N>d  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

**Ordering:**
1. ACTIVE branches first (most recently updated at top)
2. REVIEW-READY branches next (needs human attention)
3. BLOCKED branches
4. STALE branches
5. DORMANT branches at the bottom

**Status indicators:**
- `ACTIVE` — no special marker
- `REVIEW-READY` → prefix branch name with `* ` (needs review attention)
- `BLOCKED` → prefix with `! ` and show blocker reason if available
- `STALE` → show days since update in red/warning
- `DORMANT` → dim/grayed

---

## Step 4: Attention Highlights

After the main table, show attention sections:

### Branches Needing Review
List any branch where `currentPhase` is `review`, `verify`, or `uat`:

```
NEEDS REVIEW:
  * <branch> — <projectName> is waiting in <currentPhase> phase (<N> days)
    To review: /sdlc:verify or /sdlc:review on branch <rawBranch>
```

### Stale Phases
List branches where `stalePhasesCount > 0`:

```
STALE ARTIFACTS:
  ! <branch> — <N> phase(s) marked stale (data-model, design)
    To refresh: git checkout <rawBranch> && /sdlc:verify --all
```

### Blocked Branches
List branches with `BLOCKED` status:

```
BLOCKED:
  ! <branch> — blocked on <phase> (<N> days waiting)
```

### Technical Debt Hotspots
List branches where `openDebts > 5`:

```
HIGH DEBT:
  <branch> — <N> open technical debt items
    Run /sdlc:debt on branch <rawBranch> to review
```

---

## Step 5: Summary Counts

```
SUMMARY:
  Active:       <N> branches
  Review-ready: <N> branches
  Stale:        <N> branches
  Blocked:      <N> branches
  Dormant:      <N> branches

  Total open technical debts: <N> across all branches
```

---

## Step 6: Quick-Reference Commands

```
QUICK COMMANDS:
  Switch to branch and continue:
    git checkout <branch> && /sdlc:resume

  Check specific branch status:
    git checkout <branch> && /sdlc:status

  Review artifacts:
    git checkout <branch> && /sdlc:verify

  Start new workflow:
    git checkout -b <new-branch> && /sdlc:start <idea>
```

---

## Error Handling

**Malformed state.json:** If any state.json cannot be parsed, show the branch as `ERROR` in the table with: "state.json malformed — run /sdlc:status on that branch to repair."

**Missing required fields:** If a state.json is missing `branch` or `phases`, treat `branch` as the directory name and `phases` as all pending.

**No git repo:** If git is not initialized (no `.git/`), use `default` for the current branch context.
