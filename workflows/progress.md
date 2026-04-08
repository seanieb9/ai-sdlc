# Progress Workflow

Display implementation task progress, update task status, and hydrate the native task panel. Reads progress.json; if missing, bootstraps from implementation-plan.md.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

**Parse $ARGUMENTS:**
- Detect `--update <TASK-ID> <done|skip>` pattern
- Detect `--next` flag

---

## Step 1: Load or Bootstrap progress.json

**Check if progress.json exists:**
```bash
[ -f "$WORKSPACE/progress.json" ] && echo "exists" || echo "missing"
```

### If progress.json exists:
Read and parse it. The expected schema is:

```json
{
  "version": "1.0.0",
  "projectName": "<name>",
  "branch": "<branch>",
  "updatedAt": "<ISO timestamp>",
  "summary": {
    "total": 0,
    "done": 0,
    "skipped": 0,
    "inProgress": 0,
    "blocked": 0,
    "pending": 0
  },
  "phases": [
    {
      "name": "<phase name>",
      "tasks": [
        {
          "id": "TASK-NNN",
          "title": "<title>",
          "layer": "<data|domain|application|infrastructure|delivery|crosscutting|test>",
          "effort": "S|M|L|XL",
          "risk": "LOW|MEDIUM|HIGH",
          "dependencies": ["TASK-NNN"],
          "doneCriteria": "<verifiable completion condition>",
          "status": "pending|in-progress|done|skipped|blocked",
          "startedAt": null,
          "completedAt": null,
          "notes": ""
        }
      ]
    }
  ]
}
```

### If progress.json does not exist:
Check for implementation-plan.md:
```bash
[ -f "$ARTIFACTS/plan/implementation-plan.md" ] && echo "exists" || echo "missing"
```

**If implementation-plan.md exists:**
Parse tasks from implementation-plan.md. Extract:
- Task IDs (TASK-NNN pattern)
- Task titles
- Phase sections (Phase 1: Foundation, etc.)
- Effort labels (S/M/L/XL)
- Dependencies listed

Bootstrap progress.json from these tasks. Set all statuses to `pending`. Write the file.

Output: "Bootstrapped progress.json from implementation-plan.md — <N> tasks loaded."

**If neither file exists:**
Output:
```
No progress.json or implementation-plan.md found for branch $BRANCH.

To get started:
  1. Run /sdlc:07-plan to generate an implementation plan
  2. Then run ask Claude to run the progress workflow again to see the task dashboard
```
STOP.

---

## Step 2: Handle --update Flag

If `--update` flag is present:

Parse: `--update <TASK-ID> <done|skip>`

**Validate:**
- TASK-ID must exist in progress.json. If not: output "TASK-ID '<id>' not found. Run ask Claude to run the progress workflow to see all task IDs." STOP.
- Status must be `done` or `skip`. If not: output "Status must be 'done' or 'skip'." STOP.

**Update the task in progress.json:**
- `done`: set `status: "done"`, `completedAt: "<ISO timestamp>"`
- `skip`: set `status: "skipped"`, `completedAt: "<ISO timestamp>"`, `notes: "Skipped by user"`

**Check dependencies:** If any other tasks depend on this TASK-ID and are still `blocked`, update them:
- If all their dependencies are now `done` or `skipped` → set their status to `pending` (unblocked)

**Recompute summary counts** and update progress.json.

Output: "Updated TASK-NNN → <done|skipped>"

Then proceed to display the dashboard (Step 3).

---

## Step 3: Handle --next Flag

If `--next` flag is present (and no `--update`):

Find the single best next task to work on:
1. Filter tasks with `status: "pending"` or `status: "in-progress"`
2. Filter out tasks whose dependencies are not all `done` or `skipped`
3. Sort remaining by: in-progress first, then by phase order (Phase 1 before Phase 2), then by risk (HIGH risk first within phase)
4. Pick the top task

Output:
```
NEXT TASK: TASK-NNN
Title: <title>
Layer: <layer>
Effort: <S/M/L/XL>
Risk: <LOW/MEDIUM/HIGH>
Phase: <phase name>
Dependencies: <all completed — none blocking | TASK-NNN (done), TASK-NNN (done)>

Done Criteria:
  <doneCriteria text>

Context:
  Read: <relevant files from architecture that apply to this task>
  Pattern to follow: <layer-specific guidance>
```

STOP after showing next task.

---

## Step 4: Display Progress Dashboard

Compute current stats from progress.json:

```
╔══════════════════════════════════════════════════════════════════╗
║  IMPLEMENTATION PROGRESS                                         ║
║  <projectName>  Branch: <$BRANCH>                                ║
╠══════════════════════════════════════════════════════════════════╣
║  OVERALL: <N>/<total> tasks (<pct>%)                             ║
║  Done: <N>  In Progress: <N>  Blocked: <N>  Pending: <N>        ║
╠══════════════════════════════════════════════════════════════════╣
║  BY PHASE                                                        ║
<for each phase:>
║  <Phase Name>: <N>/<total> (<pct>%)  [██████░░░░]               ║
╠══════════════════════════════════════════════════════════════════╣
║  IN PROGRESS                                                     ║
║  [~] TASK-NNN: <title> (<effort>)                               ║
╠══════════════════════════════════════════════════════════════════╣
║  BLOCKED                                                         ║
║  [!] TASK-NNN: <title> — waiting for: <dependency list>         ║
╠══════════════════════════════════════════════════════════════════╣
║  NEXT: TASK-NNN — <title> (<effort>, <risk> risk)               ║
╚══════════════════════════════════════════════════════════════════╝
```

**Progress bar generation:**
- 10-character bar: `<N filled>/<10>` where filled = round(pct/10)
- Filled character: `█`, empty character: `░`

**Show all tasks in a checklist** below the dashboard:

```
TASK CHECKLIST:

Phase 1: Foundation
  [x] TASK-001: Create DB migration for users table (S, LOW)
  [~] TASK-002: Implement User entity (M, LOW) — IN PROGRESS
  [ ] TASK-003: Implement UserRepository port (S, LOW) — depends: TASK-002
  [!] TASK-004: PostgresUserRepository (M, MEDIUM) — BLOCKED: TASK-003 pending

Phase 2: Application
  [ ] TASK-005: CreateUser use case (M, MEDIUM) — depends: TASK-003, TASK-004
  ...
```

Legend: [x] Done | [~] In Progress | [ ] Pending | [!] Blocked | [-] Skipped

---

## Step 5: Hydrate Native Task Panel

Use TaskList to check which tasks are already in the native task panel.

For each task in progress.json **not yet in the panel**: use TaskCreate to add it with:
- Title: `<TASK-ID>: <title>`
- Status: map progress.json status to native task status

For each task already in the panel where the status differs from progress.json: use TaskUpdate to sync the status.

**Status mapping:**

| progress.json | Native task status |
|--------------|-------------------|
| pending | todo |
| in-progress | in_progress |
| done | done |
| skipped | done |
| blocked | todo |

---

## Step 6: Final Output Footer

After the dashboard and task list:

```
Updated: <ISO timestamp>
Artifact: $WORKSPACE/progress.json

Commands:
  ask Claude to run the progress workflow --next                    — show the single next task
  ask Claude to run the progress workflow --update TASK-NNN done   — mark a task complete
  ask Claude to run the progress workflow --update TASK-NNN skip   — skip a task
```
