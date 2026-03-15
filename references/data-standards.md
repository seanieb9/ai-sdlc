# Data Modeling Standards Reference

## Canonical Data Model Principles

The canonical data model is the **single source of truth** for all data in the system. Every other artifact derives from it.

**Rules:**
1. Define ONCE, reference everywhere
2. Evolve, never replace — use versioning and deprecation
3. Every entity must be owned by a bounded context
4. No duplicated entities across contexts — share by reference (ID) only
5. External standards take precedence over internal naming preferences

---

## Universal Field Standards

### Every Entity Must Have

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID v4 | Primary key. Immutable. System-generated. Never expose sequential IDs. |
| `created_at` | TIMESTAMP WITH TIME ZONE | Immutable. UTC. Set by system at creation. |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Updated by system on every write. |
| `deleted_at` | TIMESTAMP WITH TIME ZONE | NULL = active. Soft deletes for auditable entities. |

### Stateful Entities Must Have

| Field | Type | Notes |
|-------|------|-------|
| `status` | ENUM | All possible states documented in DATA_MODEL.md |
| `version` | INTEGER | Optimistic locking. Increment on every update. |

### Auditable Entities Must Have

| Field | Type | Notes |
|-------|------|-------|
| `created_by` | UUID FK | Who created it. |
| `updated_by` | UUID FK | Who last modified it. |

---

## Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Entity names | PascalCase (singular) | `Order`, `CustomerProfile` |
| Table names | snake_case (plural) | `orders`, `customer_profiles` |
| Field names | snake_case | `customer_id`, `total_amount` |
| Enum values | SCREAMING_SNAKE_CASE | `ORDER_PLACED`, `PAYMENT_FAILED` |
| Junction tables | `[entity1]_[entity2]s` | `order_products` |
| FK fields | `[referenced_entity]_id` | `customer_id` → references `customers.id` |
| Boolean fields | `is_[adjective]` or `has_[noun]` | `is_active`, `has_payment_method` |

---

## Type Standards

| Data Type | Use | Standard |
|-----------|-----|----------|
| ID | UUID v4 | RFC 4122 |
| Currency amount | DECIMAL(19, 4) | Never float for money |
| Currency code | CHAR(3) | ISO 4217 |
| Country code | CHAR(2) | ISO 3166-1 alpha-2 |
| Language | VARCHAR(10) | BCP 47 |
| Phone number | VARCHAR(20) | E.164 format (+1234567890) |
| Email | VARCHAR(254) | RFC 5321 |
| Date | DATE | ISO 8601 |
| Datetime | TIMESTAMP WITH TIME ZONE | ISO 8601, always UTC |
| Duration | INTEGER (milliseconds) | or ISO 8601 duration |
| URL | VARCHAR(2083) | RFC 3986 |
| IP address | INET / VARCHAR(45) | Supports IPv6 |
| Postal code | VARCHAR(20) | Country-specific |
| Percentage | DECIMAL(5, 4) | 0.0000 to 1.0000 (not 0-100) |
| Coordinates | DECIMAL(9, 6) | WGS84 |

---

## Domain-Specific Standards

### Financial / Payments
- **ISO 20022** for payment messages and financial data
- **PCI-DSS** for cardholder data (never store PAN, CVV in plain text)
- **ISO 4217** for currency codes
- Transaction IDs: provider-generated, store as VARCHAR(255)
- Amount: always store in lowest denomination (cents, not dollars) OR use DECIMAL(19,4)

### Identity / Authentication
- **OpenID Connect** for identity tokens
- **OAuth 2.0** for authorization
- **SCIM 2.0** for user provisioning
- Never store passwords — store bcrypt/argon2 hashes only
- Session tokens: opaque, random, 256-bit minimum

### Healthcare (if applicable)
- **FHIR R4** for clinical data
- **HL7** for messaging
- **HIPAA** data residency and encryption requirements
- PHI fields: encrypted at rest, logged on access

### E-Commerce
- **GS1** for product identifiers (GTIN/EAN/UPC)
- Product variants: parent + variant model
- Inventory: track at SKU level

---

## Relationship Rules

| Relationship | Rule |
|-------------|------|
| One-to-Many | FK on the "many" side. CASCADE on delete only if the child has no meaning without parent. |
| Many-to-Many | Always via explicit junction entity (not implicit join table). Junction entity has its own ID and timestamps. |
| Optional FK | Nullable FK field. `ON DELETE SET NULL` if parent can be deleted. |
| Cross-context | Reference by ID only. Never embed cross-context entity. No FK constraint across bounded contexts. |

---

## Data Model Versioning

Version format: `MAJOR.MINOR.PATCH`
- PATCH: new optional fields, new indexes, new enum values (backward compatible)
- MINOR: new entities, new optional relationships
- MAJOR: breaking changes (removed fields, type changes, required field added, cardinality changes)

**Breaking changes require:**
1. Impact analysis documented
2. Migration strategy defined
3. API versioning strategy updated
4. Explicit user confirmation

---

## Domain-Driven Design Quick Reference

**Bounded Context:** A logical boundary within which a domain model applies. Each context has its own ubiquitous language. Contexts communicate via events or APIs, never shared DB tables.

**Aggregate:** A cluster of entities treated as a unit for data changes. Has one Aggregate Root. Consistency guaranteed within an aggregate, eventual consistency between aggregates.

**Aggregate Root rules:**
- Only the aggregate root has a repository
- External objects reference the aggregate only by the root's ID
- Invariants that span multiple entities in an aggregate are enforced by the aggregate root

**Domain Events:** Facts that happened. Past tense. `OrderPlaced`, `PaymentFailed`. Published after a state change. Other bounded contexts react to them.
