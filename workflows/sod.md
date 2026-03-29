# Start of Day Workflow

Orient Claude, plan the session, and start the first task — in under two minutes. This is more than a resume: it reviews yesterday's state, sets today's goal, and surfaces anything that needs attention before work begins.

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

## Step 1: Load Context

Read in parallel:
- `$STATE` — checkpoint, phase progress, tasks, verification log (read and parse JSON)
- `$ARTIFACTS/plan/implementation-plan.md` — execution plan (scan for today-relevant tasks, if exists)
- Git log: `git log --oneline -5` — what was last committed

---

## Step 2: Assess Overnight State

Check for anything that changed or needs attention since yesterday:

**Stale decisions:**
- Are there open decisions in NEXT_ACTION.md that have been sitting more than 1 day?
- Flag any that are blocking today's work

**Dependency check:**
- Are there external blockers noted in yesterday's EOD? (waiting on a PR review, waiting on infra, etc.)
- If blocked: surface the blocker and suggest what to work on instead

**Phase gate check:**
- Was yesterday's phase completed? If so, does it need verification before today's work begins?
- Check verification_log in $STATE — any unverified completed phases?

---

## Step 3: Plan Today's Session

Based on TODO.md and PLAN.md, determine:

**What to aim to complete today:**
- Look at the next 3–5 P0/P1 TODO items
- Estimate realistic scope for a day's session
- Identify any natural stopping points (e.g., "complete the application layer today")

**What to tackle first:**
- The single first action (from checkpoint.next_action in $STATE)
- If that's blocked: identify the next unblocked task

**What to watch for:**
- Any task in today's plan that has a known complexity or decision point
- Surface these upfront so they don't surprise mid-session

---

## Step 4: Deliver SOD Brief

Print the start-of-day brief:

```
╔══════════════════════════════════════════════════════╗
║  START OF DAY: [Project Name]                        ║
║  [date]                                              ║
╠══════════════════════════════════════════════════════╣
║  WHERE WE LEFT OFF                                   ║
║  Phase [N]: [Phase Name] — [step]                    ║
║  [1 sentence summary of yesterday's progress]        ║
╠══════════════════════════════════════════════════════╣
║  FIRST ACTION                                        ║
║  [exact command]                                     ║
║  [what it does — 1 sentence]                         ║
╠══════════════════════════════════════════════════════╣
║  TODAY'S GOAL                                        ║
║  [realistic aim — e.g. "Complete application layer   ║
║   (3 use cases) and start infrastructure adapters"]  ║
╠══════════════════════════════════════════════════════╣
║  WATCH OUT FOR                                       ║
║  [known decision points or complexity ahead — or     ║
║   "Clear run — no known blockers"]                   ║
╠══════════════════════════════════════════════════════╣
║  NEEDS ATTENTION                                     ║
║  [unverified phases, stale decisions, blockers —     ║
║   or "None"]                                         ║
╠══════════════════════════════════════════════════════╣
║  TASKS: [N] complete / [N] total   P0 remaining: [N] ║
╚══════════════════════════════════════════════════════╝

Say "go" to start the first action, or give a different instruction.
```

---

## Step 5: Wait for Confirmation

Do not auto-execute. The user may want to adjust today's plan, ask a question, or take a different direction before starting.

---

## Step 6: Auto-Checkpoint Reminder

After the brief, if the user says "go" or starts work, remind once:

```
Tip: run /loop 15m /sdlc:checkpoint to auto-save context while you work.
```

Only remind once per session — do not repeat this on subsequent actions.
