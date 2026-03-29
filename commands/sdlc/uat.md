---
name: sdlc:uat
description: Stakeholder acceptance testing plan — UAT-NNN scenarios, entry/exit criteria, sign-off record
argument-hint: "[feature or persona] [--sign-off]"
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
Phase 13b stakeholder acceptance testing. Maps every acceptance criterion from the PRD to human-executable UAT scenarios that non-technical stakeholders can run.

Each scenario is assigned a UAT-NNN ID and written in plain language — no code, no technical jargon. Entry and exit criteria define when UAT can begin and when it is complete. Sign-off records capture who approved.

Reads:
  - `$ARTIFACTS/verify/verification-report.md` — REQUIRED. Must show 0 open CRITICAL findings.
  - `$ARTIFACTS/idea/prd.md` — acceptance criteria to map to scenarios
  - `$ARTIFACTS/journey/customer-journey.md` — user flows (if exists)

Outputs:
  - `$ARTIFACTS/uat/uat-plan.md` — UAT overview, entry/exit criteria, scenario matrix, test data requirements, sign-off record
</objective>

<context>
Feature or persona: $ARGUMENTS

Flags:
  --sign-off    Record stakeholder sign-off (prompts for name, updates state.json)
</context>

<execution_context>
@~/.claude/sdlc/workflows/uat.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the UAT verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
