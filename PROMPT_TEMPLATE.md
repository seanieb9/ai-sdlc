# Initial Prompt Template

Use this template with `/sdlc:00-start` to pre-answer all clarifying questions and architecture decision points. The more detail you provide upfront, the further the system runs without interruption.

---

## Full Template

```
/sdlc:00-start "
## Project
Name: [e.g. Payment Processing Service]
Type: [new project | new feature | bug fix | refactor]
Description: [2-3 sentences — what it does and who it serves]

## Key Features (what must be built)
- [Feature 1]
- [Feature 2]
- [Feature 3]

## Users / Personas
- [Primary user type and their goal]
- [Secondary user type if any]

## Non-Functional Requirements
- Latency: p95 < [X]ms for [critical operation]
- Throughput: [N] RPS sustained, [N] RPS peak
- Availability: [99.9% | 99.95% | 99.99%]
- Data volume: ~[N] records/day, [N] retention period
- Compliance: [GDPR | PCI-DSS | HIPAA | SOC2 | none]

## Tech Stack
- Language/Runtime: [e.g. TypeScript / Node.js]
- Database: [e.g. PostgreSQL]
- Cache: [e.g. Redis | none]
- Message broker: [e.g. RabbitMQ | Kafka | none]
- Deployment: [e.g. Kubernetes on AWS | Docker Compose | serverless]

## Deployment Topology
- Architecture: [monolith | microservices | hybrid]
- Team size: [N engineers]
- Existing services to integrate: [list or none]

## External Dependencies
- [Service name]: [what it does] — [CRITICAL | DEGRADABLE | OPTIONAL]
- [Service name]: [what it does] — [CRITICAL | DEGRADABLE | OPTIONAL]

## Security
- Auth: [JWT + OIDC | API keys | session cookies | none]
- AuthZ: [RBAC | ABAC | none]
- Sensitive data: [list any PII, PCI, PHI fields]

## Constraints / Out of Scope
- [Hard constraint, e.g. must use existing auth service]
- [What is explicitly NOT being built]
"
```

---

## Minimum Viable Template

Covers the four orchestrator questions and the two most impactful architecture decisions. Enough to eliminate all early clarifying questions.

```
/sdlc:00-start "
Name: [name]
Type: [new project | new feature | bug fix | refactor]
Description: [what it does and who it serves]
Stack: [language, database, cache, deployment]
Architecture: [monolith | microservices]
NFRs: [latency target], [throughput], [availability]
Compliance: [list or none]
Constraints: [anything that must not be changed or assumed]
"
```

---

## Example (Full)

```
/sdlc:00-start "
## Project
Name: Invoice Service
Type: new project
Description: A B2B invoicing microservice for a SaaS platform serving freelancers
  and agencies. Handles invoice creation, payment tracking, recurring billing,
  and automated reminders. Used by ~5,000 businesses.

## Key Features
- Create, edit, and send invoices (PDF generation)
- Track payment status (unpaid, partial, paid, overdue)
- Recurring invoice schedules (weekly, monthly, custom)
- Automated payment reminder emails
- Basic analytics (revenue by period, outstanding balance)

## Users / Personas
- Freelancer: creates invoices, tracks who owes them money
- Agency admin: manages invoices across multiple clients
- Internal ops: views payment health across all tenants (read-only)

## Non-Functional Requirements
- Latency: p95 < 200ms for invoice CRUD, p95 < 50ms for status reads
- Throughput: 500 RPS sustained, 2000 RPS peak
- Availability: 99.9%
- Data volume: ~10,000 invoices/day, 7-year retention (legal)
- Compliance: SOC2 Type II, GDPR

## Tech Stack
- Language/Runtime: TypeScript / Node.js
- Database: PostgreSQL 16
- Cache: Redis (invoice status hot cache)
- Message broker: RabbitMQ (payment events, reminder jobs)
- Deployment: Kubernetes on AWS EKS

## Deployment Topology
- Architecture: microservices (this is one service in a larger platform)
- Team size: 4 engineers
- Existing services to integrate:
    - auth-service (JWT validation) — provides user identity
    - notification-service (sends emails) — async via RabbitMQ
    - payment-service (Stripe webhook receiver) — publishes PaymentReceived events

## External Dependencies
- PostgreSQL: primary data store — CRITICAL
- Redis: invoice status cache — DEGRADABLE (fall back to DB read)
- RabbitMQ: async events and jobs — DEGRADABLE (queue locally, retry on reconnect)
- auth-service: JWT validation — CRITICAL
- notification-service: email delivery — OPTIONAL (invoice still created if emails fail)
- payment-service: payment status updates — DEGRADABLE (show last known status)

## Security
- Auth: JWT (validated against auth-service JWKS endpoint)
- AuthZ: RBAC — roles: freelancer, agency_admin, ops_readonly
- Sensitive data: bank_account_number (PCI), email (PII), company_name (PII)

## Constraints / Out of Scope
- Must use existing auth-service — no new auth implementation
- PDF generation handled by a shared pdf-service — do not implement locally
- Payment processing is NOT in scope — only receiving payment status events
- Multi-currency support is NOT in scope for v1
"
```
