# Docs Management Workflow

Maintain document health and integrity. The canonical document set is fixed — only update, never proliferate.

## Canonical Document Registry

These are the ONLY documents that should exist (shards are ok):
```
docs/research/RESEARCH.md
docs/research/GAP_ANALYSIS.md
docs/research/SYNTHESIS.md
docs/product/PRODUCT_SPEC.md
docs/product/PRODUCT_SPEC_[DOMAIN].md  (shards, only if main > 400 lines per domain)
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
docs/sre/INCIDENT_RESPONSE.md
docs/review/REVIEW_REPORT.md
.sdlc/STATE.md
.sdlc/TODO.md
.sdlc/PLAN.md
.sdlc/DECISIONS.md
```

## --audit Flag: Run Full Audit

1. Glob all markdown files: `docs/**/*.md` and `.sdlc/*.md`
2. Compare against registry above
3. For each file:
   - Is it in the registry? (if not: candidate for consolidation)
   - Does it have a "Last Updated" header? (if not: flag as missing metadata)
   - Is it referenced from STATE.md document index? (if not: flag)
   - Does it have meaningful content or is it a stub? (< 10 lines: flag as stub)

4. For each registry file that DOESN'T exist: flag as missing

5. Check for content duplication:
   - If two docs cover the same topic, flag for consolidation

Output: audit findings table with recommended actions.

## --index Flag: Rebuild Document Index

Read STATE.md. Update the Document Index section to reflect actual file existence:
- `[x]` for files that exist
- `[ ]` for files that don't exist yet

## --clean Flag: Interactive Cleanup

For each audit finding, ask user:
- Non-registry file: "This file is not in the canonical registry. Consolidate into [target doc]? [y/n/skip]"
- Duplicate content: "These sections appear to duplicate each other. Merge? [y/n/skip]"
- Stale file: "This file hasn't been updated in 60+ days and the feature is active. Review? [y/n/skip]"

Perform consolidation only after confirmation.

## --status Flag: Doc Health Dashboard

```
Document Health
===============
✅ docs/research/RESEARCH.md          (updated 3 days ago)
✅ docs/data/DATA_MODEL.md            (updated today) ⚠️ CRITICAL
❌ docs/architecture/TECH_ARCHITECTURE.md  (missing)
⚠️  docs/product/PERSONAS.md
  docs/product/PRODUCT_SPEC.md      (not updated in 45 days)

Registry compliance: 8/22 documents exist
```

After any operation, update STATE.md document index.
