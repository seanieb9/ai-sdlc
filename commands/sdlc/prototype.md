---
name: sdlc:prototype
description: Low-fidelity UX flows — validate interaction model before the data model locks in
argument-hint: "[feature or screen name]"
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
Phase 4c low-fidelity prototyping. Validate the interaction model before the data model is designed.

Reads all user flows from the PRD and customer journey, then produces ASCII-style wireframes for every screen. Shared components are identified to inform the design system.

Reads:
  - `$ARTIFACTS/idea/prd.md` — REQUIRED. User flows and acceptance criteria.
  - `$ARTIFACTS/journey/customer-journey.md` — SOFT REQUIRED. Journey steps drive screen inventory.

Outputs:
  - `$ARTIFACTS/prototype/prototype-spec.md` — screen inventory, per-screen wireframes, shared components, navigation map
</objective>

<context>
Feature or screen name: $ARGUMENTS

Flags:
  (none — use $ARGUMENTS to scope by feature or screen)
</context>

<execution_context>
@~/.claude/sdlc/workflows/prototype.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the prototype verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
