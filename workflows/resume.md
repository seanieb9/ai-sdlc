# Resume Workflow

Re-orient Claude completely after `/clear`, a new session, or context loss. Reads all persistent state and delivers a crisp brief so work continues in under a minute.

Run as the very first command in a new context window.

---

## Step 0: Workspace Resolution
Run this bash to determine workspace paths:
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$WORKSPACE/artifacts"
```
Then use $WORKSPACE, $STATE, $ARTIFACTS throughout.

## Step 1: Load Everything in Parallel

Read all of the following simultaneously:

**Primary state:**
- `$STATE` — checkpoint (most important — tells Claude exactly where to pick up), phase progress, decisions, verification log, tasks (read and parse JSON)
- `$ARTIFACTS/plan/implementation-plan.md` — execution plan (if exists)

**Artifact existence check** (Glob `$ARTIFACTS/**/*.md` — read index only, not full content):
- Which phase outputs exist tells Claude which phases are complete

**Spot-read current work** (only if checkpoint in $STATE specifies in-progress files):
- Read any files listed under `checkpoint.in_progress_files` in $STATE
- Read any files related to `checkpoint.next_action` to understand what's being built

Do NOT read all docs in full — that defeats the purpose of a lean resume. Read only what's needed to execute the next action.

---

## Step 2: Reconstruct Context

From the files read, reconstruct:

1. **Project identity** — name, type, domain (from $STATE)
2. **Phase status** — which phases complete, which in-progress, which blocked
3. **Verification status** — which phases have been verified (from verification_log in $STATE)
4. **Current task** — exact task in-progress (from $STATE tasks array + checkpoint)
5. **Next action** — the single command to run next (from $STATE checkpoint.next_action)
6. **Open decisions** — anything unresolved that may come up immediately
7. **Do-not-lose items** — verbal constraints or preferences from last session

---

## Step 3: Deliver Resume Brief

Print a structured brief before doing anything else:

```
╔══════════════════════════════════════════════════════╗
║  RESUMED: [Project Name]                             ║
║  [date/time of last checkpoint]                      ║
╠══════════════════════════════════════════════════════╣
║  PHASE PROGRESS                                      ║
║  ✅ [completed phases]                               ║
║  🔄 Phase [N]: [Phase Name] — [current step]         ║
║  ⬜ [remaining phases]                               ║
╠══════════════════════════════════════════════════════╣
║  LAST SESSION                                        ║
║  [What was just completed — 1 sentence]              ║
╠══════════════════════════════════════════════════════╣
║  NEXT ACTION                                         ║
║  [exact command to run]                              ║
║  [what it will do — 1 sentence]                      ║
╠══════════════════════════════════════════════════════╣
║  OPEN DECISIONS: [N]                                 ║
║  [list if any, "None" if clear]                      ║
╠══════════════════════════════════════════════════════╣
║  DO NOT LOSE                                         ║
║  [Critical verbal context from last session]         ║
║  ["None" if nothing]                                 ║
╠══════════════════════════════════════════════════════╣
║  TASKS: [N] complete / [N] total                     ║
╚══════════════════════════════════════════════════════╝

Ready. Run the next action above or say "go" to execute it now.
```

---

## Step 4: Wait for Confirmation

After printing the brief, pause. Do not execute the next action automatically.

The user may want to:
- Confirm and proceed: "go" or "continue" or "yes"
- Change direction: give a new instruction
- Ask a question first

Only proceed to execute the next action when the user confirms.

---

## If $STATE Does Not Exist or Has No Checkpoint

Fall back to `/sdlc:00-start` behavior:
- Inform the user which branch was detected
- Display the standard SDLC dashboard
- Route to the recommended next phase

Inform the user: "No checkpoint found for branch '$BRANCH'. Reading project state to determine where to resume..."
