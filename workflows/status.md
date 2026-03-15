# Status Workflow

Display a clear, useful SDLC dashboard showing exactly where things stand and what to do next.

## Step 1: Read State

Read in parallel:
- `.sdlc/STATE.md`
- `.sdlc/TODO.md`
- `.sdlc/PLAN.md`

Check which doc files actually exist using Glob: `docs/**/*.md`

If .sdlc/STATE.md doesn't exist: show "No SDLC project initialized. Run /sdlc:00-start to begin."

## Step 2: Compute Phase Status

For each phase, check:
- RESEARCH: docs/research/RESEARCH.md exists?
- SYNTHESIZE: docs/research/SYNTHESIS.md exists?
- PRODUCT-SPEC: docs/product/PRODUCT_SPEC.md exists?
- CUSTOMER-JOURNEY: docs/product/CUSTOMER_JOURNEY.md exists?
- DATA-MODEL: docs/data/DATA_MODEL.md exists?
- TECH-ARCH: docs/architecture/TECH_ARCHITECTURE.md exists?
- PLAN: .sdlc/PLAN.md exists with tasks?
- CODE: TODO items for implementation marked [x]?
- TEST-CASES: docs/qa/TEST_CASES.md exists?
- TEST-AUTO: docs/qa/TEST_AUTOMATION.md exists?
- OBSERVABILITY: docs/sre/OBSERVABILITY.md exists?
- SRE: docs/sre/RUNBOOKS.md exists?
- REVIEW: docs/review/REVIEW_REPORT.md exists?

## Step 3: Parse TODO Stats

From .sdlc/TODO.md:
- Count `[ ]` → pending
- Count `[~]` → in progress
- Count `[x]` → done
- Count blocked items

## Step 4: Determine Recommended Next Action

Based on phase status + gate rules, identify the single most important next step.

## Step 5: Display Dashboard

```
╔═══════════════════════════════════════════════════════════════╗
║  SDLC: [Project Name]                                         ║
║  [Type] · Last updated: [date]                                ║
╠═══════════════════════════════════════════════════════════════╣
║  PHASES                                                       ║
║  [✅/🔄/⬜/⛔] Research          [✅/🔄/⬜/⛔] Synthesize   ║
║  [✅/🔄/⬜/⛔] Product Spec      [✅/🔄/⬜/⛔] CX Journey   ║
║  [✅/🔄/⬜/⛔] Data Model ⚠️    [✅/🔄/⬜/⛔] Tech Arch    ║
║  [✅/🔄/⬜/⛔] Plan             [✅/🔄/⬜/⛔] Code         ║
║  [✅/🔄/⬜/⛔] Test Cases       [✅/🔄/⬜/⛔] Test Auto    ║
║  [✅/🔄/⬜/⛔] Observability    [✅/🔄/⬜/⛔] SRE          ║
║  [✅/🔄/⬜/⛔] Review                                        ║
╠═══════════════════════════════════════════════════════════════╣
║  TODOS: [N] pending · [N] in progress · [N] done             ║
╠═══════════════════════════════════════════════════════════════╣
║  NEXT: /sdlc:[command] [reason]                               ║
╚═══════════════════════════════════════════════════════════════╝
```

Legend: ✅ Complete | 🔄 In Progress | ⬜ Not Started | ⛔ Blocked | ⚠️ Gate

If --todos flag: show full TODO list below dashboard.
If --docs flag: show document health (exists/missing/stale).
If --verbose flag: show what's in each complete phase.
