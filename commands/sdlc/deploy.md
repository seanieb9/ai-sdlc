---
name: sdlc:deploy
description: Deployment checklist — CI/CD verification, rollback plan, handoff notes, release gate
argument-hint: "[environment] [--rollback] [--dry-run]"
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
Phase 14 deployment readiness. Verifies CI/CD pipeline health, generates a complete deployment checklist specific to the architecture, defines smoke tests, and documents the exact rollback procedure.

This phase is a hard gate: it will not proceed if there are open CRITICAL findings in the verification report, or if UAT was in scope and has not been signed off.

Reads:
  - `$ARTIFACTS/verify/verification-report.md` — REQUIRED. 0 open CRITICAL findings required.
  - `$ARTIFACTS/uat/uat-plan.md` — sign-off record (if UAT was performed)
  - `$ARTIFACTS/design/tech-architecture.md` — deployment architecture (if exists)
  - `$ARTIFACTS/sre/observability.md` — health check endpoints (if exists)
  - `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile` — CI/CD pipeline files

Outputs:
  - `$ARTIFACTS/deploy/deployment-checklist.md` — pre-flight checklist, deployment steps, post-deploy verification, rollback procedure, sign-off
</objective>

<context>
Target environment: $ARGUMENTS

Flags:
  --rollback    Generate rollback-only checklist for an in-progress deployment
  --dry-run     Validate checklist completeness without marking deployment started
</context>

<execution_context>
@~/.claude/sdlc/workflows/deploy.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the deploy verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
