# Checkpoint Workflow

Save a precise session snapshot to `.sdlc/NEXT_ACTION.md`. Run this proactively before context fills, at the end of every phase, or any time you want a clean resume point.

The goal is to capture everything needed to continue work in a fresh context window — so the next session starts in 30 seconds, not 10 minutes of re-orientation.

---

## Step 1: Read Current State

Read in parallel:
- `.sdlc/STATE.md` — phase progress, decisions, verification log
- `.sdlc/TODO.md` — task list (identify what's in-progress vs complete)
- `.sdlc/PLAN.md` — execution plan (if exists)
- `.sdlc/NEXT_ACTION.md` — previous checkpoint (if exists, to diff against)

Also check which docs exist (Glob `docs/**/*.md`) to build an accurate document index.

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

## Step 3: Write `.sdlc/NEXT_ACTION.md`

Overwrite completely (this is always the current state, not a log):

```markdown
# Session Checkpoint
*Saved: [ISO datetime]*

## Active Work
- **Project:** [project name from STATE.md]
- **Phase:** [N] — [Phase Name]
- **Step:** [specific step, e.g. "Step 4b — implementing application use cases"]
- **Status:** [in_progress | at_decision_point | phase_complete | blocked]

## What Was Just Completed
[1-3 sentences — what was finished this session, specific enough to orient a fresh context]

## Exact Next Action
**Run:** `[exact command with flags]`
**What it does:** [what will happen when this runs]
**Critical context:** [anything not in the documents that Claude needs to know]

## Open Decisions
[List each unresolved decision. "None" if clear.]

## In-Progress Files
[Files partially written or mid-edit. "None" if everything is committed.]

## Do Not Lose
[Verbal instructions, decisions, or preferences from this session not written anywhere else.
 These are lost on /clear without this checkpoint. Be specific.]

## Stats
- TODOs complete: [N]/[total]
- Phases verified: [list]
- Last verify: [phase N — PASS/FAIL]
- Files changed this session: [N]
```

---

## Step 4: Update STATE.md

Append to `## Context` in STATE.md:
```
[datetime] CHECKPOINT: Phase [N] Step [X] — [one-line status] → Next: [command]
```

---

## Step 5: Confirm to User

```
✅ Checkpoint saved → .sdlc/NEXT_ACTION.md

Phase [N]: [Phase Name] — [status]
Next action: [exact command]
Open decisions: [N]
Do-not-lose items: [N]

To resume after /clear: /sdlc:resume
To auto-checkpoint:     /loop 15m /sdlc:checkpoint
```
