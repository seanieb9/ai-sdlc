# Contract Test Scaffold Workflow

Auto-scaffolds consumer-driven contract test stubs for every API endpoint defined in api-spec.md. Produces stubs that define the minimum response shape consumers depend on — not implementation tests, but interface guarantees.

**Triggered after:** design phase (conditional: only if api-spec.md exists)

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/design"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Check Precondition

Check whether `$ARTIFACTS/design/api-spec.md` exists and is non-empty.

If it does not exist:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "api-spec.md not found in design artifacts" }` and output `⏭️ contract-test-scaffold — skipped: api-spec.md not found`
- If interactive: inform the user that api-spec.md is required and stop.

---

## Step 2: Extract API Endpoints

Read `$ARTIFACTS/design/api-spec.md`. For each endpoint, extract:

```
Method: [GET / POST / PUT / PATCH / DELETE]
Path: [e.g. /api/v1/payments/{id}]
Auth required: [yes/no — and type: Bearer JWT / API Key / none]
Request body schema: [field names, types, required/optional]
Path/query parameters: [names and types]
Response 2xx: [status code, body shape]
Response 4xx: [which codes — 400/401/403/404/422 — and error body shape]
Response 5xx: [500 — any documented error shape]
```

If api-spec.md exists but contains no endpoint definitions, treat as skipped-condition-not-met.

---

## Step 3: Generate Contract Test Stubs

For each endpoint, generate stubs for four contract scenarios. Use the language-agnostic pseudo-code format below — the consumer implements these using their preferred tool (Pact, MSW, supertest, etc.).

**Example for `POST /api/v1/payments`:**

```
CONTRACT: POST /api/v1/payments

--- Happy path (201 Created) ---
Request:
  POST /api/v1/payments
  Authorization: Bearer <valid-token>
  Content-Type: application/json
  Body: { "amount": 5000, "currency": "USD", "card_token": "tok_visa" }

Expected response shape:
  Status: 201
  Body shape (types, not values):
    {
      "id": string,
      "status": "pending" | "completed",
      "amount": number,
      "currency": string,
      "created_at": ISO-8601 string
    }
  Assert: body.id is present and non-empty
  Assert: body.status is one of ["pending", "completed"]

--- Auth failure (401 Unauthorized) ---
Request:
  POST /api/v1/payments
  [no Authorization header]
  Body: { "amount": 5000, "currency": "USD", "card_token": "tok_visa" }

Expected response shape:
  Status: 401
  Body shape:
    { "error": string, "code": string }
  Assert: body.error is present

--- Validation error (400 / 422) ---
Request:
  POST /api/v1/payments
  Authorization: Bearer <valid-token>
  Body: { "amount": -1 }   ← missing required fields, invalid amount

Expected response shape:
  Status: 400 or 422
  Body shape:
    { "error": string, "fields": [{ "field": string, "message": string }] }
  Assert: body.fields is an array
  Assert: body.fields[0].field is present

--- Not found (404) ---
  GET /api/v1/payments/nonexistent-id-000
  Authorization: Bearer <valid-token>

Expected response shape:
  Status: 404
  Body shape:
    { "error": string }
  Assert: body.error is present

--- Server error pattern (500) ---
  Note: inject a failure condition in your test environment.
  Assert: status is 500
  Assert: body does NOT leak a stack trace or internal file paths
  Assert: body shape matches error envelope: { "error": string }
```

Apply this template to every endpoint extracted in Step 2.

---

## Step 4: Write Artifact

Write `$PHASE_ARTIFACTS/contract-tests.md`:

```markdown
# Contract Tests
*Generated: [date] | Endpoints covered: [N]*

> These are consumer-driven contracts. Each stub defines the minimum response shape
> the consumer depends on. Implement using Pact, MSW, supertest, or your preferred
> contract testing tool.
>
> Rule: tests must assert shape and status — never assert on dynamic values like IDs or timestamps.

## Endpoints Covered

[table: Method | Path | Happy Path | Auth | Validation | Not Found]

---

## [METHOD] [path]

[full contract block from Step 3]

---

[repeat for each endpoint]
```

---

## Step 5: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "contract-test-scaffold",
  "triggeredAfter": "design",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/contract-tests.md",
  "summary": "<N> endpoints scaffolded with contract stubs (happy path, auth, validation, 404)",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 6: Output

If `--auto-chain`:
```
✅ contract-test-scaffold — <N> endpoints → contract stubs [<PHASE_ARTIFACTS>/contract-tests.md]
```

If interactive:
```
✅ Contract Test Scaffold Complete

Endpoints covered: [N]
  [list: METHOD /path]

Scenarios per endpoint: happy path, auth failure (401), validation error (400/422), not found (404), 5xx pattern

Artifact: [PHASE_ARTIFACTS]/contract-tests.md

Next step: Implement these stubs using Pact, MSW, or supertest before writing production code.
Recommended: Run sdlc:09-test-cases to link contract stubs back to TC-IDs.
```
