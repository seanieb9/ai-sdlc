---
name: sdlc:test-cases
description: Design comprehensive MECE test cases with full requirement traceability. Given/When/Then per use case. Feeds test automation directly.
argument-hint: "[feature/scope] [--update] [--persona <name>]"
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
Design comprehensive, MECE test cases with full requirement traceability. Test cases are the specification for automation — quality here directly determines quality of the system.

Requires:
  - .claude/ai-sdlc/workflows/<branch>/artifacts/idea/prd.md (must exist)

Reads (if available):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/journey/customer-journey.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/data-model/data-model.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/design/api-spec.md
  - .claude/ai-sdlc/workflows/<branch>/artifacts/test-cases/test-cases.md (update, never recreate)
  - Actual implemented code (for edge case discovery)

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/test-cases/test-cases.md

Test case structure:
  - TC-ID (permanent, never reused)
  - REQ-ID / BR-ID traceability
  - Given/When/Then format
  - Test type: unit / integration / E2E / contract / performance / security
  - Priority: P0 (smoke) / P1 (regression) / P2 (extended)
  - Happy path + primary failure path + edge cases per feature
  - No duplicate test cases — check existing before adding
</objective>

<context>
Feature/scope: $ARGUMENTS

Flags:
  --update           Update existing test cases (add new, update changed requirements)
  --persona <name>   Focus on journeys for a specific persona
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/test-cases.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 9 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
