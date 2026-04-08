# Checkpoint Workflow

Save a precise session snapshot into state.json. Run this proactively before context fills, at the end of every phase, or any time you want a clean resume point.

The goal is to capture everything needed to continue work in a fresh context window — so the next session starts in 30 seconds, not 10 minutes of re-orientation.

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

## Step 1: Read Current State

Read in parallel:
- `$STATE` — phase progress, decisions, verification log, tasks (read and parse JSON)
- `$ARTIFACTS/plan/implementation-plan.md` — execution plan (if exists)

Also check which artifacts exist (Glob `$ARTIFACTS/**/*.md`) to build an accurate document index.

---

## Step 2: Assess Current Position

Determine precisely:

**Phase and step:**
- Which SDLC phase is active? (1–13)
- Which step within that phase is in-progress? (e.g. "Step 4b: Application layer")
- Is the phase complete, in-progress, or at a decision point?

**What was just completed:**
- What specific work happened in this session?
- Which files were created or modified?
- Which TODO items were checked off?

**What is next:**
- The single exact next command to run
- Any context needed to run it correctly
- Estimated scope (e.g. "2 use cases remaining in Step 4b")

**Open decisions:**
- Any unresolved choices that will need user input
- Any spec divergences that haven't been resolved
- Any architectural decisions that were deferred

**What only exists in conversation context:**
- User preferences or constraints stated verbally but not written to any document
- Decisions made during this session that affect downstream work but aren't yet in STATE.md
- Any "don't forget" items the user mentioned

---

## Step 3: Write checkpoint into `$STATE`

Update the `checkpoint` field in state.json (this is always the current state, not a log):

```json
{
  "checkpoint": {
    "saved_at": "[ISO datetime]",
    "project": "[project name]",
    "phase": [N],
    "phase_name": "[Phase Name]",
    "step": "[specific step, e.g. Step 4b — implementing application use cases]",
    "status": "in_progress | at_decision_point | phase_complete | blocked",
    "what_was_completed": "[1-3 sentences — what was finished this session]",
    "next_action": {
      "command": "[exact command with flags]",
      "what_it_does": "[what will happen when this runs]",
      "critical_context": "[anything not in the documents that Claude needs to know]"
    },
    "open_decisions": [],
    "in_progress_files": [],
    "do_not_lose": "[Verbal instructions, decisions, or preferences from this session not written anywhere else]",
    "stats": {
      "tasks_complete": "[N]/[total]",
      "phases_verified": [],
      "last_verify": "[phase N — PASS/FAIL]",
      "files_changed": [N]
    }
  }
}
```

---

## Step 4: Update state.json context log

Append to the `context_log` array in $STATE:
```json
{"datetime": "[datetime]", "event": "CHECKPOINT", "note": "Phase [N] Step [X] — [one-line status] → Next: [command]"}
```

---

## Step 4b: Update Institutional Memory

Before confirming the checkpoint, capture learnings from this session that should persist beyond this context window.

Review the session work and identify:
- Any non-obvious patterns, constraints, or conventions discovered (e.g. "this codebase uses X pattern for Y")
- Any user preferences or decisions stated verbally but not written to docs
- Any surprises — things that didn't work as expected and how they were resolved

If anything worth persisting is found, append it to the project's CLAUDE.md (create it at the project root if it doesn't exist):

```markdown
## Session Learnings — [date]
- [learning 1]
- [learning 2]
```

Keep each learning to one sentence. Maximum 5 learnings per session. If nothing worth persisting was found, skip this step silently.

---

## Step 5: Confirm to User

```
✅ Checkpoint saved → $STATE (checkpoint field)

Phase [N]: [Phase Name] — [status]
Next action: [exact command]
Open decisions: [N]
Do-not-lose items: [N]

To resume after /clear: /sdlc:resume
To auto-checkpoint:     /loop 15m /sdlc:checkpoint
```
