---
name: sdlc:test-gen
description: Generate automation scripts from test cases — 1:1 TC-ID mapping, coverage gates, drift detection
argument-hint: "[feature or test layer] [--layer <unit|integration|e2e>] [--update-only]"
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
Phase 10 test automation generation. Converts test cases into runnable automation scripts with strict 1:1 TC-ID traceability.

Every generated test must reference its TC-ID in a comment. Coverage gates are configured from project settings. Drift detection is documented so future code changes can be audited against the test suite.

Reads:
  - `$ARTIFACTS/test-cases/test-cases.md` — REQUIRED. Must contain ≥3 TC-IDs.
  - `$ARTIFACTS/data-model/data-model.md` — for test data factories (if exists)
  - `$ARTIFACTS/design/api-spec.md` — for contract tests (if exists)
  - `.claude/ai-sdlc.config.yaml` — test framework and coverage thresholds

Outputs:
  - Test code files organized by layer (unit, integration, contract, e2e)
  - Coverage configuration file (jest.config / vitest.config / pytest.ini)
  - `$ARTIFACTS/test-gen/test-automation.md` — TC-ID to file mapping, coverage gate summary, drift detection notes
</objective>

<context>
Feature or test layer: $ARGUMENTS

Flags:
  --layer <l>      Generate tests for a specific layer only (unit|integration|e2e)
  --update-only    Update existing test files for changed TC-IDs only (no new files)
</context>

<execution_context>
@~/.claude/sdlc/workflows/test-gen.md
@~/.claude/sdlc/references/testing-standards.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the test-gen verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
