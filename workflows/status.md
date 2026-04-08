# Status Workflow

Display a clear, useful SDLC dashboard showing exactly where things stand and what to do next.

## Step 0: Workspace Resolution
Run this bash to determine workspace paths:
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$WORKSPACE/artifacts"
```
Then use $WORKSPACE, $STATE, $ARTIFACTS throughout.

## Step 1: Read State

Read and parse `$STATE` (JSON).

If $STATE doesn't exist: show "No SDLC project initialized for branch $BRANCH. Run /sdlc:00-start to begin."

## Step 2: Compute Phase Status

For each phase, check artifact existence:
- RESEARCH: $ARTIFACTS/research/research.md exists?
- SYNTHESIZE: $ARTIFACTS/research/synthesis.md exists?
- PRODUCT-SPEC: $ARTIFACTS/idea/prd.md exists?
- CUSTOMER-JOURNEY: $ARTIFACTS/journey/customer-journey.md exists?
- DATA-MODEL: $ARTIFACTS/data-model/data-model.md exists?
- TECH-ARCH: $ARTIFACTS/design/tech-architecture.md exists?
- PLAN: $ARTIFACTS/plan/implementation-plan.md exists with tasks?
- CODE: tasks in $STATE for implementation marked done?
- TEST-CASES: $ARTIFACTS/test-cases/test-cases.md exists?
- TEST-AUTO: $ARTIFACTS/test-gen/test-automation.md exists?
- OBSERVABILITY: $ARTIFACTS/observability/observability.md exists?
- SRE: $ARTIFACTS/sre/runbooks.md exists?
- REVIEW: docs/review/REVIEW_REPORT.md exists?

## Step 3: Parse Task Stats

From $STATE tasks array:
- Count status "pending" → pending
- Count status "in_progress" → in progress
- Count status "done" → done
- Count status "blocked" → blocked

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
