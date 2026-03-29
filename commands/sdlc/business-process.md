---
name: sdlc:business-process
description: Map back-office and operational processes — approvals, fulfillment, exception handling, compliance steps, escalation paths, scheduled operations. Produces BP-IDs, swimlane diagrams, RACI, SLAs, and data model implications.
argument-hint: "[process area] [--update]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Map the operational processes that run behind user-facing journeys. Captures what humans and systems do to make the product work — approvals, fulfillment, exception handling, compliance steps, escalation paths, and scheduled operations. These processes reveal data entities and state machines the data model must support.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/journey/customer-journey.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/personas/personas.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/business-process/business-process.md

Deliverables per process:
  - BP-ID (permanent, never reused)
  - Swimlane diagram (Mermaid)
  - RACI matrix
  - SLA / time bounds
  - Exception paths and escalation rules
  - Data model implications summary (feeds Phase 5)
</objective>

<context>
Process area: $ARGUMENTS

Flags:
  --update   Update existing business process document (add new processes, refine existing)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/business-process.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 4b verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
