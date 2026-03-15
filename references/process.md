# SDLC Process Reference

## The Lifecycle

Every piece of work — new project, new feature, bug fix, improvement — flows through this lifecycle. Phase gates are enforced by the orchestrator. No phase can be skipped without explicit justification.

```
IDEA
  ↓
RESEARCH       → docs/research/RESEARCH.md, GAP_ANALYSIS.md
  ↓
SYNTHESIZE     → docs/research/SYNTHESIS.md
  ↓
PRODUCT SPEC   → docs/product/PRODUCT_SPEC.md
  ↓
CX JOURNEY     → docs/product/CUSTOMER_JOURNEY.md
  ↓
DATA MODEL ⚠️  → docs/data/DATA_MODEL.md  ← CRITICAL GATE
  ↓
TECH ARCH      → docs/architecture/TECH_ARCHITECTURE.md, API_SPEC.md
  ↓
PLAN           → .sdlc/PLAN.md, .sdlc/TODO.md
  ↓
CODE           → Implementation (clean architecture)
  ↓
TEST CASES     → docs/qa/TEST_CASES.md
  ↓
TEST AUTO      → docs/qa/TEST_AUTOMATION.md
  ↓
OBSERVABILITY  → docs/sre/OBSERVABILITY.md + implementation
  ↓
SRE            → docs/sre/RUNBOOKS.md, SLO.md
  ↓
REVIEW         → docs/review/REVIEW_REPORT.md
```

---

## Phase Gates (Hard Rules)

These gates are enforced by the orchestrator. Bypassing requires `--force` flag and a documented reason.

| Gate | Phase Blocked | Requires |
|------|--------------|---------|
| DATA-MODEL | tech-arch, plan, code, test-cases | docs/data/DATA_MODEL.md |
| PRODUCT-SPEC | data-model, test-cases | docs/product/PRODUCT_SPEC.md |
| PLAN | code | .sdlc/PLAN.md with tasks |
| TEST-CASES | test-automation | docs/qa/TEST_CASES.md |
| OBSERVABILITY | sre | docs/sre/OBSERVABILITY.md |

---

## Intent Classification

The orchestrator classifies work before routing:

| Input contains | Classification | SDLC entry point |
|---------------|---------------|------------------|
| "new", "add", "build", "create" | NEW_FEATURE | research |
| "fix", "bug", "broken", "issue" | BUG_FIX | plan (check data model first) |
| "improve", "refactor", "optimize" | IMPROVEMENT | synthesize (assess what exists) |
| "?", "what", "how", "status" | QUERY | status |
| New project, no state | NEW_PROJECT | research |

---

## Process Rules (Non-Negotiable)

1. **No code without a plan.** .sdlc/PLAN.md must exist before /sdlc:08-code runs.
2. **No plan without a data model.** docs/data/DATA_MODEL.md must exist before /sdlc:07-plan runs.
3. **No data model changes without review.** Any modification to existing entities triggers impact analysis.
4. **Documents are updated, never recreated.** Read existing content before writing. Append/update sections. Never overwrite history.
5. **Requirements are immutable.** REQ-IDs, TC-IDs, BR-IDs are never renumbered. Only deprecated (with reason and date).
6. **State is always maintained.** .sdlc/STATE.md updated after every phase completion.
7. **Quality is not bolted on.** Observability and tests are planned alongside implementation, not after.

---

## Document Sharding Rules

Documents are sharded ONLY when they become unwieldy:

| Document | Shard trigger | Shard naming |
|---------|--------------|-------------|
| PRODUCT_SPEC.md | Domain section > 400 lines | PRODUCT_SPEC_[DOMAIN].md |
| DATA_MODEL.md | Bounded context > 300 lines | DATA_MODEL_[CONTEXT].md |
| TEST_CASES.md | Layer section > 500 lines | TEST_CASES_[LAYER].md |
| RUNBOOKS.md | Individual runbook > 100 lines | RUNBOOK_[NAME].md |

Shards are referenced from the parent document. Parent document remains the index.

---

## What NOT to Do

- ❌ Start coding before planning
- ❌ Create PRODUCT_SPEC_v2.md (update the existing one)
- ❌ Delete requirements or test cases (deprecate them)
- ❌ Skip data model for "small" features (all features touch data)
- ❌ Add observability "later" (it's part of each phase)
- ❌ Write tests after coding (tests should be designed from requirements)
- ❌ Use exotic patterns for novelty (use established, justified patterns)
- ❌ Ignore phase gates (document why if you must override)

---

## For Bug Fixes

Shortened lifecycle — but still requires discipline:

1. **DIAGNOSE** — what is the root cause? What data/behavior is wrong?
2. **CHECK DATA MODEL** — does the bug reveal a data model gap? If yes, fix model first.
3. **PLAN** — even for bugs: what exactly will change, how will we verify the fix?
4. **CODE** — implement the fix following clean architecture
5. **UPDATE TEST CASES** — add a regression test (TC-ID for this bug)
6. **UPDATE AUTOMATION** — automate the regression test
7. **REVIEW** — did the fix introduce any new issues?

Bug fixes that reveal data model issues are escalated to full SDLC treatment.

---

## For Improvements/Refactors

1. **SYNTHESIZE** — what does the current codebase look like? What's the problem?
2. **PLAN** — what exactly will change? What must NOT change (behavior preservation)?
3. **CODE** — apply /simplify, follow clean architecture
4. **UPDATE TESTS** — ensure existing tests still pass, update any that break due to refactor
5. **REVIEW** — verify no regressions
