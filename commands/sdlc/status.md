---
name: sdlc:status
description: >
  Show the current SDLC state — phases completed, active work, todos, doc health, and recommended next action.
  AUTO-TRIGGER — invoke this skill when the user expresses uncertainty about direction or asks what to do next.
  Trigger patterns (any of these):
  - Asking for direction: "what should we do next?", "what's next?", "where do we go from here?", "what should I do now?"
  - Asking about progress: "where are we?", "how far along are we?", "what phase are we on?", "what have we done so far?"
  - Asking if ready to proceed: "are we done?", "can we move on?", "is this phase complete?", "are we ready to start X?"
  - Asking for a plan check: "what's left?", "what's still todo?", "what's outstanding?"
  Do NOT trigger on questions about specific technical topics, codebase questions, or general conversation.
  Do NOT trigger if state.json does not exist for the current branch (no active SDLC project).
argument-hint: "[--verbose] [--docs] [--todos]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

<objective>
Display a clear SDLC dashboard for the current project.

Dashboard sections:
  1. Project summary (name, type, last updated)
  2. Phase progress (✅ complete | 🔄 in progress | ⛔ blocked | ⬜ not started)
  3. Active tasks (from implementation-plan.md in $ARTIFACTS/plan/)
  4. Document health (exists, missing, stale)
  5. Recommended next action

Read from:
  - state.json (phases, checkpoint, decisions)
  - $ARTIFACTS/plan/implementation-plan.md (if exists)
  - $ARTIFACTS/ (check what artifact files exist per phase)

Show clearly what the recommended next step is based on current state.
</objective>

<context>
Flags: $ARGUMENTS
  --verbose  Show full details per phase
  --docs     Focus on document health
  --todos    Show full todo list with statuses
</context>

<execution_context>
@~/.claude/sdlc/workflows/status.md
</execution_context>

