# Product Standards Reference

---

## Requirements Standards

### REQ-ID Format

Every requirement gets a permanent, never-renumbered ID:

```
REQ-001   Functional requirement
BR-001    Business rule
NFR-001   Non-functional requirement (performance, security, availability, scalability)
```

**Rules:**
- IDs are append-only — never delete, never renumber
- Deprecated requirements are marked `[DEPRECATED]`, not removed
- Every REQ must trace to at least one BR (why it exists)
- Every NFR must have a numeric threshold — no subjective language

---

## NFR — SMART Thresholds

Every Non-Functional Requirement must be **Specific, Measurable, Achievable, Relevant, Time-bound**.

### Reject these — replace with the SMART version:

| Vague (reject) | SMART (require) |
|----------------|-----------------|
| "The system must be fast" | "p95 response time < 200ms at 1,000 RPS sustained for 60 minutes" |
| "The system must be available" | "99.9% availability measured monthly (≤ 43.8 min downtime/month)" |
| "The system must be scalable" | "Horizontal scale to 10× baseline load with no config changes" |
| "The system must be secure" | "OWASP Top 10 compliant; all auth endpoints rate-limited to 20 req/min per IP" |
| "The system must handle errors gracefully" | "All 5xx errors return within 500ms with RFC 7807 error body; no stack traces exposed" |
| "Minimal downtime during deployments" | "Zero-downtime rolling deployments; health probe must pass within 30s of pod start" |

### Required NFR categories (every project must address all of these):

| Category | Minimum specification |
|----------|-----------------------|
| **Performance** | Latency target (p50/p95/p99) + load (RPS or concurrent users) + duration |
| **Availability** | SLA percentage + measurement window (monthly) |
| **Scalability** | Scale trigger (CPU/memory/queue depth) + scale-out time |
| **Security** | Auth mechanism + session lifetime + rate limiting + data classification |
| **Data retention** | Retention period + archival strategy + deletion SLA (for GDPR) |
| **Recovery** | RTO (recovery time objective) + RPO (recovery point objective) |

---

## MoSCoW Priority Rules

Apply MoSCoW to every functional requirement. Rules:

| Priority | Definition | Constraint |
|----------|-----------|-----------|
| **Must** | Failure to include = product fails. Legal, safety, or core-value requirement. | ≤ 40% of requirements |
| **Should** | High value, expected by users, painful to omit. Not fatal to launch without. | ≤ 35% of requirements |
| **Could** | Nice-to-have. Include if time/budget allow. Cut first when scope pressures arise. | No limit |
| **Won't** | Explicitly out of scope for this release. Reduces ambiguity, prevents scope creep. | Document all Won'ts |

**Violation check:** If > 60% of requirements are Must → scope is too large. Re-evaluate.

---

## Business Rules

Business rules are constraints the system must enforce regardless of who wrote the code.

**Format:**
```
BR-001: [Statement of the rule in plain language]
         Trigger: [what event activates this rule]
         Enforcement: [where the rule is checked — domain entity / use case / API gateway]
         Violation: [what happens if the rule is broken — error code, message, consequence]
```

**Rules:**
- Business rules live in the domain layer — never in controllers or UI
- Every BR must be testable: a test case must be able to prove it passes and fails
- BR-IDs are permanent and referenced in test cases

---

## BDD Scenario Standards

### Given/When/Then syntax rules:

```
Scenario: [descriptive name — what situation is being tested]
  Given [initial state / preconditions — what is true before the action]
  And   [additional preconditions]
  When  [the triggering action — one specific thing the actor does]
  Then  [the observable outcome — what the system does in response]
  And   [additional assertions]
```

**Every scenario must have:**
- A name that reads as a test case summary (not "happy path" — describe what specifically succeeds)
- One `When` clause — if you need two, it's two scenarios
- At least one `Then` assertion for the happy path
- A corresponding failure scenario for every non-trivial `When`

**Completeness check — every scenario must cover:**

| Coverage area | Required scenarios |
|---------------|-------------------|
| Happy path | At least one per functional requirement |
| Validation failures | One per input field with a constraint |
| Business rule violations | One per BR that can be triggered by user action |
| Authorization failures | One per role boundary |
| Concurrency / idempotency | One where the same action is repeated |
| Downstream failure | One where an external dependency fails |

---

## Jobs-to-be-Done (JTBD) Syntax

### Three job types (all required for each persona):

```
Functional job:  "When [situation], I want to [action], so I can [outcome]"
Emotional job:   "When [situation], I want to feel [emotion], so I avoid [negative feeling]"
Social job:      "When [situation], I want to be seen as [perception], so others [reaction]"
```

**Examples:**
```
Functional:  "When I finish a client project, I want to send a professional invoice in under
              2 minutes, so I can get paid without administrative friction."
Emotional:   "When I send an invoice, I want to feel confident it looks professional,
              so I avoid feeling embarrassed in front of clients."
Social:      "When a client receives my invoice, I want to be seen as organised and credible,
              so they feel confident referring me to others."
```

**Violation check:** If the job statement cannot be completed by the persona acting on the product → it's an aspiration, not a job. Rewrite it.

---

## Persona Completeness Rules

Every persona requires all of the following before it is considered complete:

| Component | Rule |
|-----------|------|
| Segment | Must map to a real customer segment — not a fictional archetype |
| Evidence link | Every pain must cite a source: VOC.md quote, GAP_ANALYSIS.md finding, or explicit assumption (flagged) |
| All 3 JTBD jobs | Functional + emotional + social — all three |
| Empathy map | Think / Feel / Say / Do — all four quadrants |
| Anti-persona | Who this is NOT, and why we will not build for them |
| Validation criteria | What real data confirms this persona exists |

**Minimum 2, maximum 5 personas per project.**

If you have > 5 personas: consolidate or move extras to anti-personas.

---

## Customer Journey Completeness Rules

Every journey map must contain:

| Element | Rule |
|---------|------|
| Trigger | What causes the persona to begin this journey |
| Steps | Every discrete action the user takes — no jumps |
| Emotional state per step | Score or label: frustrated / neutral / confident / delighted |
| Touchpoints | Which system, screen, or channel handles each step |
| Happy path | Full flow from trigger to successful outcome |
| Failure path | At least one — what happens when a step fails |
| Recovery path | How the user gets back on track after a failure |
| Business process link | Which back-office process runs in parallel (if any) |
| Success metric | How a great experience is measured at the end of this journey |

**Violation check:** If a journey has no failure path → it is incomplete. Real users fail. Document it.

---

## Exception Handling Table Standards

Every product spec must include an exception handling table. Format:

| Error Code | Trigger | User-Facing Message | System Behaviour | Retry? |
|-----------|---------|--------------------|--------------------|--------|
| ERR-001   | [what causes this] | [what the user sees — plain language] | [what the system does internally] | Yes/No |

**Rules:**
- Error codes are permanent (like REQ-IDs)
- User-facing messages never expose internal details (no stack traces, no SQL errors)
- Every BDD failure scenario maps to an error code
- HTTP status codes map to: 400 (client error), 401 (unauth), 403 (forbidden), 404 (not found), 409 (conflict), 422 (validation), 429 (rate limit), 500 (server error)

---

## Anti-Persona Rules

Anti-personas prevent scope creep and sharpen product focus.

**Required format:**
```
Anti-Persona: [Name]
Segment:      [Who they are]
Why excluded: [Specific reason — cost to serve, misaligned needs, security risk, etc.]
Risk:         [What bad thing happens if we accidentally build for them]
Signal:       [How to detect when a feature request is coming from this anti-persona]
```

**Every product must define at least one anti-persona.**

Common anti-persona types:
- The power user who wants so many features they make the product unusable for the core persona
- The free-rider who extracts value but generates no revenue
- The edge case whose needs require disproportionate complexity
- The bad actor (fraud, abuse, compliance risk)
