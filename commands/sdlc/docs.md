---
name: sdlc:docs
description: Document management — audit, organize, and maintain all SDLC docs. Finds duplicates, stale docs, missing sections. Updates index. Never creates new docs when existing ones should be updated.
argument-hint: "[--audit] [--index] [--clean] [--status]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
---

<objective>
Maintain the health and integrity of all SDLC documentation.

Canonical document registry (these are the ONLY docs that should exist):
  docs/research/RESEARCH.md
  docs/research/GAP_ANALYSIS.md
  docs/research/SYNTHESIS.md
  docs/product/PRODUCT_SPEC.md (shards: PRODUCT_SPEC_[DOMAIN].md)
  docs/product/CUSTOMER_JOURNEY.md
  docs/product/BUSINESS_PROCESS.md
  docs/data/DATA_MODEL.md
  docs/data/DATA_DICTIONARY.md
  docs/architecture/TECH_ARCHITECTURE.md
  docs/architecture/API_SPEC.md
  docs/architecture/SOLUTION_DESIGN.md
  docs/qa/TEST_CASES.md
  docs/qa/TEST_AUTOMATION.md
  docs/sre/OBSERVABILITY.md
  docs/sre/RUNBOOKS.md
  docs/sre/SLO.md
  docs/review/REVIEW_REPORT.md
  .claude/ai-sdlc/workflows/$BRANCH/state.json  ← machine-readable project state

Audit checks:
  - Artifact files outside canonical registry (candidates for consolidation)
  - Docs with duplicate content
  - Docs missing required sections
  - Stale docs (last updated > 30 days, still active feature)
  - Broken cross-references between docs
  - Phases marked complete in state.json but missing artifact files

Actions:
  --audit   Run full audit, output findings
  --index   List all artifact files that exist under $ARTIFACTS/
  --clean   Consolidate duplicate/stale docs (asks confirmation per action)
  --status  Show doc health dashboard
</objective>

<context>
Command: $ARGUMENTS

Flags:
  --audit   Full doc audit
  --index   List artifact files under $ARTIFACTS/
  --clean   Interactive cleanup of duplicate/stale docs
  --status  Doc health dashboard
</context>

<execution_context>
@~/.claude/sdlc/workflows/docs.md
@~/.claude/sdlc/references/doc-management.md
@~/.claude/sdlc/references/doc-writing-standards.md
</execution_context>

