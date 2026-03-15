# Test Cases
*Last Updated: {{DATE}}*
*Total: 0 | P0: 0 | P1: 0 | P2: 0*

---

## Coverage Matrix

| Source ID | Source (brief) | TC-IDs | Layers | Status |
|-----------|---------------|--------|--------|--------|
| REQ-001 | {{brief req description}} | TC-001 | Unit, E2E | ✅ |
| BR-001 | {{brief business rule}} | TC-002 | Unit | ✅ |
| NFR-001 | {{NFR description}} | TC-003 | Performance | ✅ |
| ADR-001 | {{ADR title — tech commitment}} | TC-004 | Resilience | ✅ |
| API:POST /resource | {{endpoint description}} | TC-005 | Contract | ✅ |
| OBS-001 | {{observability commitment}} | TC-006 | Observability | ✅ |

---

## Unit Tests

### {{Domain Entity / Service Name}}

**TC-001: {{Entity}}: {{Rule being tested}}**
- Layer: Unit
- Priority: P0
- Requirement: REQ-{{NNN}} / BR-{{NNN}}

```
Given  {{System state / object created in state X}}
When   {{Method called with Y}}
Then   {{Expected return value / state change}}
  And  {{Secondary assertion}}
Does NOT: {{What should not happen}}
```

Notes: {{Edge cases, test data requirements}}

---

## Integration Tests

### {{Repository / Adapter Name}}

**TC-{{NNN}}: {{Repository}}: {{Scenario}}**
- Layer: Integration
- Priority: P1
- Requirement: {{source}}

```
Given  {{Database state / external system state}}
When   {{Repository method called}}
Then   {{Data persisted / returned correctly}}
  And  {{Transaction behavior verified}}
```

---

## Contract Tests

### {{API Resource Group}}

**TC-{{NNN}}: POST /{{resource}}: valid payload returns 201**
- Layer: Contract
- Priority: P0
- Requirement: API_SPEC.md: POST /{{resource}}

```
Given  {{Authentication state}}
  And  {{Valid request payload}}
When   POST /api/v1/{{resource}} is called
Then   Response status is 201
  And  Response body matches schema: { "id": UUID, "status": string }
  And  Response header includes Location: /api/v1/{{resource}}/{id}
```

**TC-{{NNN}}: POST /{{resource}}: missing required field returns 422**
```
Given  {{Valid authentication}}
When   POST /api/v1/{{resource}} with missing {{required_field}}
Then   Response status is 422
  And  Response body: { "code": "VALIDATION_ERROR", "fields": [{"field": "{{field}}", "message": "..."}] }
```

---

## E2E Tests

### {{Journey Name}}

**TC-{{NNN}}: Journey: {{Persona}} — {{Happy Path Name}}**
- Layer: E2E
- Priority: P0
- Requirement: CUSTOMER_JOURNEY.md + REQ-{{NNN}}

```
Given  {{System state, test data, persona context}}
When   {{Journey step 1}}
  And  {{Journey step 2}}
  And  {{Journey step N}}
Then   {{Final state: what the user achieved}}
  And  {{Data persisted correctly in DB}}
  And  {{Events/notifications sent}}
  And  {{Audit trail present}}
```

---

## Performance Tests

### {{NFR Group: e.g., "Order Service Throughput"}}

**TC-{{NNN}}: NFR-{{NNN}}: {{Scenario — steady-state | spike | soak}}**
- Layer: Performance
- Priority: P1
- Source: NFR-{{NNN}} / PRODUCT_SPEC.md §Performance

```
Given  System at {{N}} concurrent users / {{RPS}} sustained load
When   {{Scenario type}} load pattern applied for {{duration}}
Then   p95 latency ≤ {{X}}ms
  And  p99 latency ≤ {{Y}}ms
  And  Error rate ≤ {{N}}%
  And  Throughput ≥ {{N}} RPS
```

Notes: k6 script at `tests/performance/{{scenario}}.js`

---

## Resilience Tests

### {{Dependency Name — e.g., "Payment Service (CRITICAL)"}}

**TC-{{NNN}}: Resilience: {{Dependency}} — {{failure mode: timeout | down | slow | 500}}**
- Layer: Resilience
- Priority: P0
- Source: ADR-{{NNN}} / TECH_ARCHITECTURE.md dependency classification

```
Given  {{Dependency}} is {{timeout after 5s | returning 503 | down}}
  And  {{N}} requests sent to {{use case / endpoint}}
When   {{N+1}}th request is made
Then   Circuit breaker is OPEN
  And  Response is 503 with Retry-After header
  And  circuit_breaker_state{dependency="{{dep}}"} == "open" metric emitted
Does NOT: Propagate raw error to caller
Does NOT: Hang indefinitely (must return within connect_timeout + read_timeout)
```

**TC-{{NNN}}: Resilience: {{Dependency}} DEGRADABLE — fallback returned on failure**
- Layer: Resilience
- Priority: P0
- Source: ADR-{{NNN}} / resilience-patterns.md

```
Given  {{Dependency}} is down
When   {{Use case}} is called
Then   Fallback value returned: {{e.g., stale cache, default, empty list}}
  And  degradation_event metric emitted
Does NOT: Return error to caller
Does NOT: Fail the primary operation
```

---

## Observability Tests

### {{Service/Feature Name}}

**TC-{{NNN}}: Observability: {{use case}} — structured log fields**
- Layer: Observability
- Priority: P1
- Source: OBS-{{NNN}} / OBSERVABILITY.md

```
Given  Valid {{use case}} request with trace context header
When   {{Use case}} executes successfully
Then   Log line at INFO level emitted containing:
  - trace_id: matches W3C traceparent format
  - service: "{{service-name}}"
  - event: "{{event.name}}"
  - {{domain field}}: present and non-null
Does NOT: Contain email, password, card_number, or other PII
```

**TC-{{NNN}}: Observability: {{endpoint}} — RED metrics emitted**
- Layer: Observability
- Priority: P1
- Source: OBS-{{NNN}} / OBSERVABILITY.md

```
Given  {{N}} requests made to {{endpoint}}
When   /metrics is scraped
Then   http_requests_total{method="{{METHOD}}", path="{{path}}", status="{{code}}"} == N
  And  http_request_duration_seconds_bucket present with correct le buckets
```

---

## Security Tests

### {{API Resource Group}}

**TC-{{NNN}}: Security: {{endpoint}} — unauthenticated request rejected**
- Layer: Security
- Priority: P0
- Source: PRODUCT_SPEC.md §Auth / TECH_ARCHITECTURE.md §Security

```
Given  No Authorization header
When   {{METHOD}} /api/v1/{{resource}} is called
Then   Response status is 401
  And  Response body: { "code": "UNAUTHORIZED" }
Does NOT: Return any resource data
Does NOT: Reveal internal implementation in error message
```

**TC-{{NNN}}: Security: {{endpoint}} — insufficient role rejected**
- Layer: Security
- Priority: P0
- Source: PRODUCT_SPEC.md §RBAC

```
Given  Authenticated user with role "{{insufficient_role}}"
When   {{METHOD}} /api/v1/{{resource}} is called
Then   Response status is 403
  And  Response body: { "code": "FORBIDDEN" }
```

**TC-{{NNN}}: Security: {{endpoint}} — IDOR: user cannot access other user's resource**
- Layer: Security
- Priority: P0
- Source: OWASP API Top 10 - Broken Object Level Authorization

```
Given  User "user-A" is authenticated
  And  Resource "{{resource-id}}" belongs to "user-B"
When   GET /api/v1/{{resource}}/{{resource-id}} is called as user-A
Then   Response status is 404 (not 403 — don't confirm resource existence)
```

---

## Deprecated Test Cases
<!-- Never delete — mark deprecated -->
<!-- ~~TC-NNN~~: Deprecated {{date}} — {{reason}} -->
