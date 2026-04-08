# SDLC Execution Mode

Every phase command operates in INTERACTIVE mode. All workflows are INTERACTIVE-only — there is no mode field to check. One pause per phase, before writing any output.

---

## INTERACTIVE (default)

Pause once per phase — after analysis is complete, before writing any output document.

### When to pause

After completing the main analysis/discovery steps of the workflow, before writing any files, output this block:

```
---
🔍 ANALYSIS COMPLETE

[3-5 bullet points summarizing what was found and decided]

**What I'm about to write:**
- [document name]: [one sentence on what it will contain]

**Key calls I'm making:**
- [decision or assumption that shapes the output]
- [another if relevant]

Confirm to proceed, or redirect me now.
---
```

Wait for user response. On confirmation, write all documents and complete the phase. On redirect, incorporate feedback and re-present before writing.

### What counts as "analysis complete"

- Research phases (1, 1b, 2): after gathering all sources, before writing RESEARCH.md / VOC.md / SYNTHESIS.md
- Spec phases (3, 3b, 4, 4b): after reading all input docs and drafting structure, before writing the spec
- Data model (5): after domain analysis and entity design, before writing DATA_MODEL.md
- Architecture (6): after design decisions are formed, before writing TECH_ARCHITECTURE.md / API_SPEC.md
- Plan (7): after task breakdown is complete, before writing PLAN.md / TODO.md
- Code (8): after reading existing code and forming implementation approach, before writing any code
- QA phases (9, 10): after coverage analysis, before writing TEST_CASES.md / TEST_AUTOMATION.md
- SRE phases (11, 12): after gap analysis, before writing OBSERVABILITY.md / RUNBOOKS.md
- Review (13): after all review dimensions checked, before writing REVIEW_REPORT.md

### Rules

- One pause per phase, not per step
- The pause question is always the same: confirm direction before writing
- Never pause mid-document (finish a document once started)
- Breaking changes always require confirmation regardless of mode
- Data model gate approval always requires explicit user sign-off regardless of mode

---

## Setting Mode

**Mode:** Always INTERACTIVE. There is no configuration needed — this cannot be changed.
