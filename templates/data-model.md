# Canonical Data Model
*Last Updated: {{DATE}} | Version: 1.0.0*
*⚠️ FOUNDATION: All architecture, APIs, and code derive from this document.*
*⚠️ Changes to existing entities require impact analysis and review.*

---

## Change History

| Version | Date | Change | Breaking? |
|---------|------|--------|-----------|
| 1.0.0 | {{DATE}} | Initial model | — |

---

## Bounded Contexts

| Context | Description | Owner |
|---------|-------------|-------|
| {{Context Name}} | {{What this context owns}} | {{Team/service}} |

---

## {{Context Name}} Context

### Overview
{{2-3 sentences about this bounded context's responsibility}}

### Aggregates

```mermaid
erDiagram
    {{ENTITY}} {
        uuid id PK
        {{field}} {{type}}
        timestamp created_at
        timestamp updated_at
    }
```

### Entities

#### {{EntityName}}
- **Bounded Context:** {{context}}
- **Aggregate Root:** Yes / No
- **Description:** {{business meaning}}

| Field | Type | Nullable | Unique | Constraints | Business Meaning |
|-------|------|----------|--------|-------------|-----------------|
| id | UUID | No | Yes (PK) | Immutable | System identifier |
| created_at | TIMESTAMPTZ | No | No | Set by system | Creation time (UTC) |
| updated_at | TIMESTAMPTZ | No | No | Auto-updated | Last modification (UTC) |

**Invariants:**
- {{BR-NNN: Rule that must always be true}}

**Lifecycle States:**
```
{{STATE_A}} → {{STATE_B}} → {{STATE_C}}
```

**Relationships:**
- Has-many {{RelatedEntity}} via {{field}} (CASCADE | RESTRICT)
- Belongs-to {{ParentEntity}} via {{foreign_key_field}}

---

## Domain Events

| Event | Trigger | Published By | Consumers |
|-------|---------|-------------|-----------|
| {{EventName}} | {{What causes it}} | {{Aggregate}} | {{Who reacts}} |

---

## Cross-Context References

| Context A | References | Context B | Via |
|-----------|-----------|-----------|-----|
| {{Context}} | {{EntityName}}.id | {{Context}} | Foreign key (no FK constraint) |

---

## Invariants Summary

| ID | Rule | Enforced By |
|----|------|------------|
| BR-001 | {{Rule text}} | {{Entity/service}} |

---

## Deprecated Entities/Fields
<!-- Never delete — only deprecate -->
<!-- {{Entity.field}}: Deprecated {{date}} — Reason: {{reason}} -->
