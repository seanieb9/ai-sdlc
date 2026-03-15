# Session Checkpoint
*Saved: {{DATETIME}}*

## Active Work
- **Project:** {{PROJECT_NAME}}
- **Phase:** {{PHASE_NUMBER}} — {{PHASE_NAME}}
- **Step:** {{CURRENT_STEP}} (e.g. "Step 4b: Application layer — implementing ShortenUrlUseCase")
- **Status:** {{in_progress | at_decision_point | phase_complete | blocked}}

## What Was Just Completed
{{1-3 sentences describing the last thing that was finished this session}}

## Exact Next Action
**Run:** `{{exact command, e.g. /sdlc:08-code --task TASK-005}}`
**What it does:** {{what the command will do and why it's next}}
**Critical context:** {{anything Claude needs to know that isn't captured in the docs — e.g. a verbal decision the user made, a constraint that came up mid-session, a preference expressed}}

## Open Decisions
<!-- Any unresolved questions or decisions. Write "None" if clear. -->
- {{Decision or question}}

## In-Progress Files
<!-- Files partially written or mid-edit that need attention -->
- {{file path}} — {{what's incomplete}}

## Do Not Lose
<!-- Verbal instructions, constraints, or decisions from this session that aren't written anywhere else -->
- {{e.g. "User confirmed Redis should fail open, not closed"}}
- {{e.g. "User wants TypeScript strict mode enforced across all layers"}}

## Checkpoint Cadence
Last checkpoint: {{DATETIME}}
Recommended next checkpoint: after completing {{NEXT_MILESTONE}}
