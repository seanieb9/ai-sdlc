---
name: sdlc:sre
description: SRE practices — runbooks, SLOs/SLAs, incident response, capacity planning, reliability patterns. Requires observability to be defined first.
argument-hint: "[service/scope] [--update] [--incident]"
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
Define service reliability objectives, runbooks, and incident response. Makes operations predictable and reduces MTTR.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/observability/observability.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/tech-architecture.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/sre/runbooks.md (update, never recreate)
  - .claude/ai-sdlc/workflows/<branch>/artifacts/sre/slo.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/sre/incident-response.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/sre/runbooks.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/sre/slo.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/sre/incident-response.md

Deliverables:
  - SLOs per service (availability, latency, error rate — numeric targets)
  - SLAs (customer-facing commitments derived from SLOs)
  - Error budgets and burn rate alerts
  - Operational runbooks (step-by-step, testable, with rollback procedures)
  - Incident response playbook (severity definitions, escalation matrix, comms templates)
  - Capacity planning model
  - Chaos engineering scenarios (what to test, expected outcomes)
</objective>

<context>
Service/scope: $ARGUMENTS

Flags:
  --update     Update existing SRE docs (add runbooks, adjust SLOs)
  --incident   Document a specific incident and generate a postmortem template
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/sre.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 12 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
