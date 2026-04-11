# Test Generation Workflow

Phase 10 test automation generation. Converts test cases from test-cases.md into runnable test code with strict 1:1 TC-ID traceability. Every generated test references its TC-ID in a comment. Coverage gates are configured from project settings. Drift detection notes are documented for future audits.

---

## Step 0: Workspace Resolution

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$ARTIFACTS"
```

Then use `$WORKSPACE`, `$STATE`, `$ARTIFACTS` throughout.

---

## Step 1: Gate Check (HARD)

**HARD gate:** `$ARTIFACTS/test-cases/test-cases.md` must exist AND contain at least 3 TC-IDs (search for pattern `TC-[0-9]`).

If missing or fewer than 3 TC-IDs: STOP immediately. Tell the user:
```
Cannot generate tests: test-cases.md not found or contains fewer than 3 TC-IDs.
Run the test cases phase (tell Claude to proceed) first to define test cases before generating automation.
```

Read in parallel (after gate passes):
- `$ARTIFACTS/test-cases/test-cases.md` — all TC-IDs, layers, Given/When/Then, priorities
- `$ARTIFACTS/data-model/data-model.md` — entities for test data factories (if exists)
- `$ARTIFACTS/design/api-spec.md` — endpoints for contract tests (if exists)
- `.claude/ai-sdlc.config.yaml` — test framework, coverage thresholds, file extensions

Parse config for:
- `testFramework`: jest | vitest | pytest | rspec | go-test | other
- `coverageThresholds.overall`: e.g. 80
- `coverageThresholds.businessLogic`: e.g. 95
- `fileExtension`: .ts | .js | .py | .rb | .go

If config is missing or framework is not specified: ask the user which test framework the project uses before proceeding.

---

## Step 2: Parse Test Cases

Read test-cases.md and extract all TC-IDs. Build an index:

| TC-ID | Layer | Priority | Source | Summary |
|-------|-------|----------|--------|---------|
| TC-001 | Unit | P0 | REQ-001 | [brief] |
| TC-042 | E2E | P1 | CUST-JOURNEY | [brief] |

**Layer classification:**
- `Unit` → one test file per domain class, `<ClassName>.test.<ext>`
- `Integration` → test database/repository operations
- `Contract` → OpenAPI contract validation per endpoint
- `E2E` → full journey tests, happy path + critical failures
- `Performance` → load/benchmark tests (note: generate test structure, not load runner config)
- `Resilience` → fault injection tests
- `Observability` → log/metric/span assertion tests
- `Security` → auth/authz/injection tests

**Flag filtering:** If `--layer` flag is set (e.g. `--layer unit`): generate tests for that layer only. Document all other TC-IDs as "deferred."

If `--update-only` flag: only regenerate test files for TC-IDs whose test-cases.md entry has been modified since the last run. (Heuristic: check if the TC-IDs are already in $ARTIFACTS/test-gen/test-automation.md — if present and unchanged, skip.)

---

## Step 3: Confirm Test Strategy (CHECKPOINT)

This is a required checkpoint in INTERACTIVE mode. Do not generate test code until the user confirms.

Present the strategy summary:

```
Test Generation Plan
════════════════════
Framework:        [testFramework from config]
File extension:   .[ext]

Layers to generate:
  ✓ Unit           [N] TC-IDs  → [N] test files
  ✓ Integration    [N] TC-IDs  → [N] test files
  ✓ Contract       [N] TC-IDs  → [N] test files (requires api-spec.md: [found/not found])
  ✓ E2E            [N] TC-IDs  → [N] test files
  ✗ Performance    [N] TC-IDs  → skipped (--layer flag not set / no perf TCs)

Coverage targets (from config):
  Overall:         [N]%
  Business logic:  [N]%

Total TC-IDs:  [N]
Total files:   ~[N]

Confirm this test generation plan? (yes / no / adjust)
```

On "no" or "adjust": ask what should change before proceeding.

---

## Step 4: Generate Test Code by Layer

For each layer, generate test code. Follow these rules for every test file:

**Universal rules:**
- Every test block must have a comment on the first line referencing its TC-ID:
  `// TC-042: User cannot checkout with empty cart`
  (or `# TC-042: ...` for Python/Ruby, `// TC-042: ...` for Go)
- Group related TC-IDs in the same describe/class block when they share the same class or endpoint
- Use the project's existing import style (read one existing test file if any exists to match conventions)
- Do not generate mock implementations — use the project's established mock/stub library
- Generate test factories/fixtures for data setup using DATA_MODEL.md entity shapes

### Unit Tests

File naming: `<ClassName>.test.<ext>` (e.g., `Order.test.ts`, `test_order.py`)

Structure:
```
describe('[ClassName]', () => {
  describe('[method or rule being tested]', () => {
    it('[TC-NNN] [what it tests]', () => {
      // TC-NNN: [TC title from test-cases.md]
      // Arrange
      // Act
      // Assert
    })
  })
})
```

Generate one test file per domain class/entity. Place all unit TC-IDs for that class in the same file.

### Integration Tests

File naming: `<RepositoryName>.integration.test.<ext>`

Structure mirrors unit tests but uses real test infrastructure (test containers, in-memory DB, etc.). Do not mock database calls in integration tests.

Note in comments which infrastructure is required: `// Requires: PostgreSQL test container`

### Contract Tests

File naming: `<endpoint-group>.contract.test.<ext>`

Generate one test per TC-ID. Each test must:
- Set up the authenticated/unauthenticated state per the TC
- Call the exact endpoint with the exact input from the TC
- Assert the response status code
- Assert the response body shape matches the API spec schema
- Assert error bodies contain `code` and `trace_id` fields

If `$ARTIFACTS/design/api-spec.md` does not exist: generate placeholder contract tests with a prominent `// TODO: API spec not found — update assertions when api-spec.md is created` comment.

### E2E Tests

File naming: `<journey-name>.e2e.test.<ext>`

Each E2E test covers a complete user journey. Structure:
```
describe('Journey: [Journey Name]', () => {
  beforeAll(() => { /* seed test data */ })
  afterAll(() => { /* cleanup */ })

  it('[TC-NNN] [happy path / failure path]', async () => {
    // TC-NNN: [TC title]
    // Step 1: [action]
    // Step 2: [action]
    // Assert final state
    // Assert DB state
    // Assert events published (if applicable)
  })
})
```

### Coverage Configuration File

Generate the appropriate coverage configuration file for the detected framework:

**Jest / Vitest:**
```js
// jest.config.js or vitest.config.ts
export default {
  coverage: {
    thresholds: {
      global: {
        lines: [overall%],
        functions: [overall%],
        branches: [overall%],
      },
      // Business logic paths
      'src/domain/**': {
        lines: [businessLogic%],
        functions: [businessLogic%],
      }
    }
  }
}
```

**Pytest:**
```ini
# pytest.ini or pyproject.toml [tool.pytest.ini_options]
[pytest]
addopts = --cov=src --cov-fail-under=[overall%]
```

If a coverage config already exists: update the thresholds to match the configured values. Do not replace the entire file.

---

## Step 5: Write Automation Manifest

Write `$ARTIFACTS/test-gen/test-automation.md`:

```markdown
# Test Automation Manifest
*Generated: [ISO date]*
*Branch: [branch]*
*Framework: [framework]*

---

## TC-ID to File Mapping

| TC-ID | Layer | File | Status |
|-------|-------|------|--------|
| TC-001 | Unit | src/domain/__tests__/Order.test.ts | ✅ Generated |
| TC-042 | E2E | e2e/checkout.e2e.test.ts | ✅ Generated |
| TC-099 | Resilience | — | ⏳ Deferred (--layer flag) |

---

## Coverage Gate Summary

| Gate | Target | Notes |
|------|--------|-------|
| Overall coverage | [N]% | Configured in [config file] |
| Business logic coverage | [N]% | Applies to src/domain/** |

Coverage config file: [path]

---

## Drift Detection Notes

Test files are linked to TC-IDs via inline comments (`// TC-NNN: ...`).
To detect drift after a code change:
1. Run: `grep -r "TC-" tests/ | awk -F: '{print $2}' | sort -u` to list all referenced TC-IDs in automation
2. Compare against test-cases.md TC-IDs to find uncovered TCs
3. If a TC-ID's Given/When/Then changes in test-cases.md, the corresponding test file must be updated

---

## Uncovered TC-IDs

| TC-ID | Layer | Reason Not Covered |
|-------|-------|--------------------|
| [TC-ID] | [layer] | [deferred / out of scope / missing dependency] |
```

---

## Step 6: Update State

Update `$STATE` (state.json):
- Set `phases.test-gen.status` = `"completed"`
- Set `phases.test-gen.completedAt` = current ISO timestamp
- Set `phases.test-gen.artifacts` = `["test-automation.md"]`
- Set `updatedAt` = current ISO timestamp

---

## Step 7: Checkpoint

```
Test Generation Complete
════════════════════════
TC-IDs covered:    [N] / [total]
Layers generated:  [list]
Test files created: [N]
Uncovered TCs:     [N] (listed in test-automation.md)

Coverage config:   [path]
Manifest:          $ARTIFACTS/test-gen/test-automation.md

```

If any P0 TC-IDs are uncovered: WARN prominently. List them.

```
⚠ Uncovered P0 tests: TC-001, TC-007, TC-012
  These are critical — automation gaps on P0 tests must be resolved before review.
```

Suggest next step:
```
→ Run tests:     [test command from config]
→ Check coverage: [coverage command]
→ Continue to:   the observability phase (tell Claude to proceed)
```
