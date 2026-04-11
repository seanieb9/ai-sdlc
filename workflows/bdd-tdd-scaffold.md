# BDD/TDD Scaffold Workflow

Auto-generates Gherkin feature files and failing TDD test stubs for every scenario in test-cases.md. This is the BDD→TDD bridge: structured test cases become executable, failing tests before implementation begins.

**Triggered after:** test-cases phase

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/test-cases"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Read Test Cases and Config

Read `$ARTIFACTS/test-cases/test-cases.md`.

Search for all TC-NNN entries. Extract each scenario:
```
TC-ID: [e.g. TC-001]
Title: [scenario title]
Given: [preconditions]
When: [action]
Then: [expected outcome]
Layer: [Unit / Integration / E2E / Contract / Performance / Security]
Feature area: [grouping — e.g. "Payment Processing", "User Auth"]
```

Also read `.claude/ai-sdlc.config.yaml`. Extract:
- `language` — e.g. `typescript`, `python`, `go`, `java`
- `testFramework` — e.g. `jest`, `pytest`, `go-test`, `junit`

If test-cases.md does not exist OR contains no TC-NNN entries:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "No TC-NNN entries in test-cases.md" }` and output `⏭️ bdd-tdd-scaffold — skipped: no TC-IDs found in test-cases.md`
- If interactive: inform the user that test-cases.md is missing or empty and stop.

---

## Step 2: Generate Gherkin Feature Files

Group TC-IDs by feature area. For each feature area, produce a Gherkin feature block:

```gherkin
Feature: Payment Processing
  As a customer
  I want to complete a payment
  So that my order is confirmed

  Scenario: TC-012 — Reject payment with expired card
    Given the customer has an expired card on file
    When the customer submits a payment request
    Then the system returns a 422 error
    And the error body contains "card_expired"
    And no charge is created

  Scenario: TC-013 — Accept payment with valid card
    Given the customer has a valid card on file
    When the customer submits a payment request for $50.00
    Then the system returns a 200 response
    And the order status transitions to "paid"
    And a payment_completed event is published
```

Rules:
- One `Feature:` block per feature area
- Each TC-ID becomes one `Scenario:` with the TC-ID and title in the scenario name
- Use the extracted Given/When/Then verbatim — do not paraphrase
- Preserve `And` / `But` steps if present in the original

---

## Step 3: Generate Failing TDD Test Stubs

For each TC-ID, generate a failing test stub in the target language. The test name must include the TC-ID so it is traceable back to the requirement.

### Jest / TypeScript or JavaScript
```typescript
// TC-012: Reject payment with expired card
describe('PaymentService', () => {
  it('TC-012: should reject payment with expired card', async () => {
    // Given
    // TODO: set up expired card fixture

    // When / Then
    throw new Error('TC-012 not implemented');
  });
});
```

### pytest / Python
```python
def test_TC012_reject_payment_with_expired_card():
    """TC-012: Reject payment with expired card"""
    # Given
    # TODO: set up expired card fixture

    # When / Then
    raise NotImplementedError("TC-012 not implemented")
```

### Go
```go
func TestTC012_RejectPaymentWithExpiredCard(t *testing.T) {
    // TC-012: Reject payment with expired card
    // Given
    // TODO: set up expired card fixture

    // When / Then
    t.Fatal("TC-012 not implemented")
}
```

### JUnit / Java
```java
@Test
@DisplayName("TC-012: Reject payment with expired card")
void tc012_rejectPaymentWithExpiredCard() {
    // Given
    // TODO: set up expired card fixture

    // When / Then
    throw new UnsupportedOperationException("TC-012 not implemented");
}
```

Group stubs by layer (Unit, Integration, E2E). Apply the matching template for the detected `testFramework`.

---

## Step 4: Write Artifact Files

Write two files:

**`$PHASE_ARTIFACTS/bdd-features.md`** — all Gherkin features consolidated:
```markdown
# BDD Feature Files
*Generated: [date] | TC-IDs scaffolded: [N]*

> Copy each Feature block to a `.feature` file in your `features/` or `test/features/` directory.
> File naming convention: `<feature-area-kebab-case>.feature`

## Feature: [Area 1]
[Gherkin block]

## Feature: [Area 2]
[Gherkin block]
```

**`$PHASE_ARTIFACTS/tdd-stubs.md`** — all TDD stubs grouped by test layer:
```markdown
# TDD Test Stubs
*Generated: [date] | Framework: [testFramework] | Language: [language]*

> Copy these stubs to your test directory before implementing.
> Tests should fail first — that is the point.
> Each stub is named with its TC-ID for full traceability to test-cases.md.

## Unit Tests

[stubs for Layer: Unit]

## Integration Tests

[stubs for Layer: Integration]

## E2E Tests

[stubs for Layer: E2E]
```

---

## Step 5: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "bdd-tdd-scaffold",
  "triggeredAfter": "test-cases",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/tdd-stubs.md",
  "summary": "<N> TC-IDs scaffolded into Gherkin features and failing <testFramework> stubs",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 6: Output

If `--auto-chain`:
```
✅ bdd-tdd-scaffold — <N> TC-IDs → Gherkin + <testFramework> stubs [<PHASE_ARTIFACTS>/tdd-stubs.md]
```

If interactive:
```
✅ BDD/TDD Scaffold Complete

TC-IDs scaffolded: [N]
  Feature areas: [list]
  Test layers: Unit [N] | Integration [N] | E2E [N] | Other [N]

Framework: [testFramework] ([language])

Artifacts written:
  • [PHASE_ARTIFACTS]/bdd-features.md — Gherkin feature files (copy to features/)
  • [PHASE_ARTIFACTS]/tdd-stubs.md — Failing test stubs (copy to test/)

Next step: Copy stubs to your test directory. All tests should fail. Begin implementation.
```
