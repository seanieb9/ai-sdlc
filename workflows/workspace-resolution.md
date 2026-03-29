# Workspace Resolution

Reusable procedure executed at the start of every workflow. Establishes the branch-scoped workspace, resolves all path variables, creates missing directories, and loads or initializes state.json.

---

## Step 1: Determine Sanitized Branch Name

Run the following bash to derive $BRANCH, $WORKSPACE, $STATE, and $ARTIFACTS:

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
RAW_BRANCH="$BRANCH"
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
```

Sanitization rules applied in order:
1. Lowercase all characters
2. Replace `/` with `--` (preserves hierarchy in branch names like `feature/foo`)
3. Replace any character outside `[a-z0-9-]` with `-`
4. Collapse consecutive `-` into a single `-`
5. Trim leading and trailing `-`
6. If result is empty, default to `default`

Examples:
- `main` → `main`
- `feature/user-auth` → `feature--user-auth`
- `Feature/OAuth_2.0` → `feature--oauth-2-0`
- `HOTFIX/critical!!bug` → `hotfix--critical-bug`

---

## Step 2: Create Missing Directories

Run mkdir -p for all required paths. Never fail if they already exist.

```bash
PHASE_DIRS="feasibility research voc synthesize idea personas journey business-process prototype data-model design plan build test-cases test-gen observability sre verify uat deploy maintain retro"

mkdir -p "$WORKSPACE"
mkdir -p "$ARTIFACTS"
for phase in $PHASE_DIRS; do
  mkdir -p "$ARTIFACTS/$phase"
done
mkdir -p ".claude/ai-sdlc/codebase"
mkdir -p ".claude/ai-sdlc/history"
```

---

## Step 3: Detect New vs. Existing Workspace

Check whether $STATE exists:

```bash
if [ -f "$STATE" ]; then
  WORKSPACE_STATUS="existing"
else
  WORKSPACE_STATUS="new"
fi
```

- **New workspace**: inform the user that a new workspace is being initialized for branch `$BRANCH`.
- **Existing workspace**: proceed silently — do not announce anything.

---

## Step 4: Load or Initialize state.json

### If state.json exists

Read the file and parse its contents. Set the following variables from the JSON:
- `$PROJECT_ID` — the `projectId` field
- `$PROJECT_NAME` — the `projectName` field
- `$CURRENT_PHASE` — the `currentPhase` field (may be null)
- `$INTENT_TYPE` — the `intentType` field
- `$SCOPE_LOCKED` — the `scopeLocked` field

### If state.json does not exist

Generate a new UUID for `projectId` (use `uuidgen` or `python3 -c "import uuid; print(uuid.uuid4())"`) and write the initial state.json:

```json
{
  "version": "2.0.0",
  "projectId": "<generated-uuid>",
  "branch": "<sanitized-branch>",
  "rawBranch": "<raw-git-branch>",
  "projectName": "",
  "intentType": "new-project",
  "currentPhase": null,
  "phases": {
    "feasibility":        { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "research":           { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "voc":                { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "synthesize":         { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "idea":               { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "personas":           { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "journey":            { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "business-process":   { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "prototype":          { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "data-model":         { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "design":             { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "plan":               { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "build":              { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "test-cases":         { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "test-gen":           { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "observability":      { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "sre":                { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "verify":             { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "uat":                { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "deploy":             { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "maintain":           { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] },
    "retro":              { "status": "pending", "stale": false, "completedAt": null, "artifacts": [] }
  },
  "decisions": [],
  "gateOverrides": [],
  "checkpoint": {
    "savedAt": null,
    "nextPhase": null,
    "nextAction": null,
    "sessionNote": null
  },
  "scopeLocked": false,
  "technicalDebts": [],
  "autoChainLog": [],
  "createdAt": "<ISO-timestamp>",
  "updatedAt": "<ISO-timestamp>"
}
```

Use the current ISO 8601 timestamp (e.g. `date -u +"%Y-%m-%dT%H:%M:%SZ"`) for `createdAt` and `updatedAt`.

---

## Step 5: Expose Resolved Variables

After this procedure completes, the following variables are available to the calling workflow:

| Variable        | Value                                               |
|-----------------|-----------------------------------------------------|
| `$BRANCH`       | Sanitized branch name (e.g. `feature--user-auth`)   |
| `$RAW_BRANCH`   | Raw git branch (e.g. `feature/user-auth`)           |
| `$WORKSPACE`    | `.claude/ai-sdlc/workflows/$BRANCH`                 |
| `$STATE`        | `$WORKSPACE/state.json`                             |
| `$ARTIFACTS`    | `$WORKSPACE/artifacts`                              |

---

## Error Handling

- If `git branch --show-current` returns empty (detached HEAD): use `default` as the branch.
- If the working directory is not a git repo: use `default` as the branch.
- If state.json exists but is malformed JSON: warn the user, offer to reset to a fresh state (with confirmation), and back up the corrupt file to `$WORKSPACE/state.json.corrupt.<timestamp>`.
- Never silently overwrite an existing state.json without user confirmation.
