# SDLC Execution Modes

Every phase command operates in one of two modes. Check `.sdlc/STATE.md` → `Mode:` field before executing. If MODE is missing or STATE.md doesn't exist, default to INTERACTIVE.

A `--yolo` flag on any command overrides the project mode for that run only.

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

## YOLO

Run all workflow steps autonomously without pausing. Make all decisions, apply defaults, proceed.

### Behavior

- Do not present analysis summaries before writing
- Do not ask for confirmation before writing documents
- When a decision point is reached, choose the most reasonable default and note it
- Track every assumption in a running internal list as you work

### Assumptions tracking

Whenever you make a judgment call the user didn't specify, record it:
- Assumed [X] because [Y was not stated / Z is the industry default]
- Defaulted to [X] based on [research findings / product spec context]
- Chose [X] over [Y] because [reason]

### Output at end of phase

After auto-verify completes, add:

```
---
⚡ YOLO MODE — Assumptions made this phase:
1. [assumption]
2. [assumption]
...
Review these if anything looks unexpected.
---
```

If no assumptions were made, omit the block.

### Rules

- Breaking changes always require confirmation regardless of mode
- Data model gate approval always requires explicit user sign-off regardless of mode
- If a blocking ambiguity is encountered (two equally valid options with significant downstream impact), pause and ask — then resume YOLO after resolution

---

## Setting Mode

**At project start:** The orchestrator asks during `/sdlc:00-start` initialization. Mode is recorded in `.sdlc/STATE.md` → `Mode:` field.

**Per-command override:** Any phase command accepts `--yolo` to run in YOLO mode for that invocation only. Does not change the project-level mode in STATE.md.

**Changing mode mid-project:** Edit `.sdlc/STATE.md` directly — change `Mode: INTERACTIVE` to `Mode: YOLO` or vice versa.
