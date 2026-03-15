# Product Specification: {{FEATURE/PROJECT NAME}}
*Last Updated: {{DATE}} | Version: 1.0.0*
*⚠️ This is the authoritative requirements document. All tests and implementations trace to this.*

---

## 1. Overview

### Purpose
{{What this feature/system does and why it exists}}

### Scope
{{What is explicitly included}}

### Out of Scope
{{What is explicitly NOT included — prevents scope creep}}

### Success Metrics
- {{Metric 1: specific, measurable, e.g., "p99 checkout completion < 3s"}}
- {{Metric 2}}

---

## 2. Personas and Roles

*See docs/product/CUSTOMER_JOURNEY.md for full persona definitions.*

| Persona | Role | Primary Goal |
|---------|------|-------------|
| {{Name}} | {{Role}} | {{Goal}} |

---

## 3. Business Rules

<!-- BR-IDs are permanent. Never renumber. Only deprecate. -->

**BR-001:** {{Clear declarative statement of business rule}}
- Rationale: {{Why this rule exists}}
- Exception handling: {{What happens if violated}}
- Related: REQ-{{NNN}}

---

## 4. Functional Requirements

<!-- REQ-IDs are permanent. Never renumber. Only deprecate. -->
<!-- MoSCoW: MUST | SHOULD | COULD | WON'T -->

### MUST (Non-negotiable)

**REQ-001:** {{Clear, testable requirement statement}}
- Priority: MUST
- Rationale: {{Business driver}}
- Source: {{GAP_ANALYSIS.md | business | compliance | technical}}
- Acceptance: {{Specific, measurable acceptance criterion}}

### SHOULD (High value, include if feasible)

### COULD (Nice to have, deprioritized)

### WON'T (Explicitly out of scope)
- {{Item 1: brief reason why out of scope}}

---

## 5. Non-Functional Requirements

**NFR-001:** Performance: {{Specific metric and threshold, e.g., "API p99 response < 500ms at 1000 concurrent users"}}
**NFR-002:** Availability: {{e.g., "99.9% uptime per calendar month"}}
**NFR-003:** Security: {{e.g., "All PII encrypted at rest with AES-256"}}
**NFR-004:** Scalability: {{e.g., "Handle 10x current load without architecture changes"}}
**NFR-005:** Compliance: {{e.g., "GDPR: user data deletion within 30 days of request"}}

---

## 6. Exception Handling

**EH-001:** {{Scenario/trigger}}
- Trigger: {{What causes this exception state}}
- Expected behavior: {{What the system does}}
- User message: {{Clear, non-technical message shown to user}}
- Error code: {{Machine-readable code, e.g., INVALID_PAYMENT_METHOD}}
- Recovery path: {{Can user recover? How?}}
- Logging level: ERROR | WARN

---

## 7. BDD Scenarios

### {{Feature Area}}

**SCENARIO: {{Title}}**
- Priority: P0
- Requirement: REQ-{{NNN}}

```
Given {{precondition}}
  And {{additional precondition}}
When  {{action}}
Then  {{expected outcome}}
  And {{secondary outcome}}
```

---

## 8. API Intent (High Level)
*Full OpenAPI spec in docs/architecture/API_SPEC.md*

| Operation | Who Calls It | Input | Output | Auth |
|-----------|-------------|-------|--------|------|
| {{Create X}} | {{User/Service}} | {{What data}} | {{What returned}} | {{Auth req}} |

---

## 9. Acceptance Criteria

The feature is complete when:
- [ ] All MUST requirements implemented and tested
- [ ] All P0 BDD scenarios pass
- [ ] NFR-001 (performance) verified under load
- [ ] Security review passed
- [ ] Zero P0 bugs open

---

## 10. Open Questions

| # | Question | Owner | Due | Status |
|---|---------|-------|-----|--------|
| 1 | {{Question}} | {{Name}} | {{Date}} | Open |

---

## Deprecated Requirements
<!-- Never delete — mark deprecated with reason -->
<!-- ~~REQ-NNN~~: Deprecated [date] — [reason] -->
