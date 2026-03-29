# PII Audit Workflow

Cross-references PII fields from the data model against observability log entries and source code logging statements. Identifies unmasked PII exposure risks.

---

## Step 0: Workspace Resolution

@/Users/seanlew/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/pii-audit"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Condition Check

Check whether `$ARTIFACTS/observability/observability.md` exists.

If it does not exist:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "observability.md not found — observability phase not yet completed" }` and output `⏭️ pii-audit — skipped: observability phase not completed`
- If interactive: inform the user and ask whether to proceed with a source-code-only scan (no OBS-ID cross-reference).

---

## Step 2: Build PII Field Inventory

Read `$ARTIFACTS/data-model/data-model.md`.

Identify all fields that are or may contain PII. Known PII field name patterns (case-insensitive, partial match):

**Direct identifiers:**
- firstName, lastName, fullName, name, displayName
- email, emailAddress
- phone, phoneNumber, mobile, mobileNumber
- ssn, socialSecurityNumber, nationalId, nationalIdentifier
- dob, dateOfBirth, birthDate
- address, streetAddress, addressLine1, addressLine2, city, postcode, zipCode
- passportNumber, drivingLicenseNumber, licenseNumber
- ipAddress, deviceId, macAddress
- username (if linked to real identity)

**Financial identifiers:**
- cardNumber, creditCardNumber, debitCardNumber, pan
- accountNumber, bankAccountNumber, sortCode, routingNumber, iban
- cvv, cvv2

**Health/sensitive:**
- medicalRecordNumber, healthId
- diagnosis, condition, medication (flag any field in a health-related entity)

**Derived/indirect:**
- biometricData, faceId, fingerprint
- locationData, gpsCoordinates, latitude, longitude (if precise)

For each PII field found, record:
```
Field: [field name]
Entity: [which entity/table it belongs to]
Classification: [Direct PII / Financial / Health / Location / Indirect]
Sensitivity: [HIGH / MEDIUM / LOW]
  HIGH = direct identifier (name, email, SSN, card number)
  MEDIUM = indirect identifier (IP address, username)
  LOW = derived or aggregated
At-rest protection: [encrypted / hashed / tokenised / plaintext — from data model if documented]
```

---

## Step 3: Read Observability Entries

Read `$ARTIFACTS/observability/observability.md`.

Extract all OBS-NNN log entries. For each entry, determine:
```
OBS-ID: [identifier]
Type: [log / metric / trace / alert]
Context: [what is being logged — e.g. "user login", "payment processed", "order created"]
Domain objects logged: [which entities or DTOs are included in the log payload]
Fields logged: [specific fields mentioned, if listed]
Masking documented: [yes/no — does the OBS entry specify any PII masking]
```

---

## Step 4: Cross-Reference OBS Entries Against PII Fields

For each OBS-NNN that logs a domain object or entity:

1. Check whether any of the entity's PII fields (from Step 2) could be included in the log payload
2. Determine risk level:
   - CRITICAL: PII field is explicitly included in the log with no masking — confirmed exposure
   - HIGH: domain object is logged wholesale (e.g., `log.info("User created", { user })`) and entity contains HIGH sensitivity PII — likely exposure
   - WARN: domain object logged but entity contains only MEDIUM sensitivity PII, or masking is mentioned but not verified
   - INFO: OBS entry logs an event with only non-PII identifiers (e.g., user_id, order_id) — acceptable pattern
   - OK: OBS entry explicitly states PII fields are excluded or masked

Flag each OBS-NNN with its risk level and the specific PII concern.

---

## Step 5: Scan Source Files (if present)

If the project has source files (check for `src/`, `app/`, `lib/`, `services/` directories in the project root):

Search for logging statements that may include PII objects. Look for patterns like:
- `logger.info(..., user)` or `log.info(..., { user })`
- `console.log(user)`, `console.log(customer)`, `console.log(order)`
- Logging of entire request/response objects (which may contain user data)
- `JSON.stringify(user)`, `JSON.stringify(payload)` in log context

Use grep patterns:
```bash
grep -rn "logger\.\(info\|warn\|error\|debug\)\|console\.log\|log\.\(info\|warn\|error\|debug\)" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
  src/ app/ lib/ services/ 2>/dev/null | head -100
```

For each suspicious logging statement found:
- Identify which file and line number
- Determine which object is being logged
- Check if the object type maps to a PII-containing entity
- Rate as CRITICAL / HIGH / WARN based on Step 4 criteria

Limit source scan to top 100 matches to avoid noise. Note if more exist.

---

## Step 6: Write Artifact

Write `$PHASE_ARTIFACTS/pii-audit-report.md`:

```markdown
# PII Audit Report
*Generated: [date] | Branch: [branch]*

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL (confirmed PII in logs) | [N] |
| HIGH (likely PII exposure) | [N] |
| WARN (unverified / partial masking) | [N] |
| INFO (suggestion) | [N] |
| OK (correctly masked) | [N] |

## PII Fields Inventory

| Field | Entity | Classification | Sensitivity | At-Rest Protection |
|-------|--------|----------------|-------------|-------------------|
[one row per PII field found]

## OBS-ID PII Coverage

| OBS-ID | Log Context | Domain Objects | PII Risk | Masked? | Finding |
|--------|-------------|----------------|----------|---------|---------|
[one row per OBS entry that involves domain objects]

## CRITICAL Findings

[For each CRITICAL finding:]
**[OBS-ID or source file reference]**
- Location: [file:line or OBS-ID]
- PII field(s) at risk: [list]
- Current behaviour: [what the code/OBS entry does]
- Required fix: [specific action — e.g., "exclude email field from log context", "use user.id instead of user object"]

## HIGH Findings

[Similar format for HIGH severity findings]

## WARN Findings

[Table: Location | PII Field | Current State | Recommended Action]

## INFO / Suggestions

[Bulleted list of improvements that are not immediate risks]

## Recommended Masking Patterns

For each entity that appears in logs, document the safe logging pattern:

```
// Safe: log only non-PII identifiers
logger.info('User created', { userId: user.id, tenantId: user.tenantId });

// UNSAFE: never log the full user object
logger.info('User created', { user }); // exposes email, name, phone
```

[List safe patterns per entity]
```

---

## Step 7: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "pii-audit",
  "triggeredAfter": "build",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/pii-audit-report.md",
  "summary": "<N> PII fields, <X> CRITICAL, <Y> HIGH, <Z> WARN findings",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 8: Output

If `--auto-chain`:
```
✅ pii-audit — <N> PII fields, <X> CRITICAL <Y> HIGH findings [<PHASE_ARTIFACTS>/pii-audit-report.md]
```

If interactive:
```
✅ PII Audit Complete

PII fields inventoried: [N] across [M] entities

Findings:
  CRITICAL: [N] — confirmed PII exposure in logs
  HIGH:     [N] — likely PII exposure (full objects logged)
  WARN:     [N] — unverified masking
  OK:       [N] — correctly handled

[If CRITICAL > 0]:
⚠️  CRITICAL findings must be resolved before release.
    These represent real data breach risk in production logs.

Report: <PHASE_ARTIFACTS>/pii-audit-report.md
```
