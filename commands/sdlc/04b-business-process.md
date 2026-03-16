---
name: sdlc:04b-business-process
description: Map back-office and operational processes — approvals, fulfillment, exception handling, compliance steps, escalation paths, scheduled operations. Produces docs/product/BUSINESS_PROCESS.md with BP-IDs, swimlane diagrams, RACI, SLAs, and data model implications for Phase 5.
argument-hint: "[process name or area] [--new] [--update <BP-ID>] [--inventory-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

<objective>
Map the operational processes that run behind user-facing journeys.

Captures what humans and systems do to make the product work — approvals, fulfillment, exception handling, compliance steps, escalation paths, and scheduled operations.

Reads:
  - docs/product/CUSTOMER_JOURNEY.md — required; processes derive from journey touchpoints
  - docs/product/PRODUCT_SPEC.md — requirements and business rules context
  - docs/product/PERSONAS.md — operational roles

Outputs (update existing, never recreate):
  - docs/product/BUSINESS_PROCESS.md — BP-IDs, swimlane diagrams, RACI, SLA breakdowns, exception paths, data model implications

Key outputs fed to Phase 5 (Data Model):
  - New operational entities (ApprovalRecord, AuditLog, EscalationRecord, JobExecution)
  - State machine fields on existing entities (status, assigned_to, sla_deadline)
  - Process-driven relationships (approval belongs to order, escalation belongs to ticket)

Rules:
  - BP-IDs are immutable — only deprecated, never deleted or renumbered
  - Every human-in-loop step must have an SLA and a breach action
  - Every process must have an exception path
  - Every exception path must state who is notified and how self-healing or manual recovery works
  - Data model implications must be explicitly flagged for Phase 5 consumption
</objective>

<context>
Process or area to map: $ARGUMENTS

Flags:
  --new                Add a new process (will assign next BP-ID)
  --update <BP-ID>     Update a specific existing process
  --inventory-only     Discover and list all processes without full documentation (quick scan)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/business-process.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 4b verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
