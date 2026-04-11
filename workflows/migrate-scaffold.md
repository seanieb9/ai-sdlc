# Migration Scaffold Workflow

Auto-scaffolds database migration stubs for every entity and field defined in data-model.md. Produces forward and rollback migration SQL (or NoSQL equivalents), ordered by FK dependency, ready to drop into any migration runner.

**Triggered after:** data-model phase

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/data-model"
MIGRATIONS_DIR="$PHASE_ARTIFACTS/migrations"
mkdir -p "$MIGRATIONS_DIR"
```

---

## Step 1: Read Data Model and Config

Read `$ARTIFACTS/data-model/data-model.md`.

For each entity, extract:
```
Entity name: [e.g. Payment]
Table/collection name: [snake_case — e.g. payments]
Fields:
  - name: [field_name]
    type: [string/integer/decimal/boolean/uuid/timestamp/text/jsonb/enum/etc.]
    nullable: [yes/no]
    default: [value or none]
    unique: [yes/no]
    indexed: [yes/no]
Relationships:
  - type: [belongs_to / has_many / many_to_many]
    target: [OtherEntity]
    fk_column: [e.g. user_id]
    on_delete: [CASCADE / SET NULL / RESTRICT]
Constraints: [unique indexes, check constraints, composite indexes]
```

Also read `.claude/ai-sdlc.config.yaml`. Extract:
- `database` — e.g. `postgresql`, `mysql`, `mongodb`, `sqlite`
- `idStrategy` — if present: `uuid` or `bigserial`; default to `uuid` if not set

If data-model.md does not exist:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "data-model.md not found" }` and output `⏭️ migrate-scaffold — skipped: data-model.md not found`
- If interactive: inform the user and stop.

---

## Step 2: Delta Check

Glob `$MIGRATIONS_DIR/*.sql`. If migration files already exist, this is a delta migration run.

Read existing migration filenames to determine which entities were already scaffolded (filenames follow the pattern `NNN_create_<table>_table.sql`). Only scaffold entities and fields NOT already represented in existing migration files.

If all entities are already scaffolded → treat as completed with no new output:
- If `--auto-chain`: output `⏭️ migrate-scaffold — skipped: all entities already scaffolded`
- If interactive: inform the user and stop.

Determine next sequence number: `max(existing NNN) + 1`.

---

## Step 3: Generate Migration Stubs

### Dependency Ordering

Sort entities so that referenced tables are created before tables with foreign keys pointing to them. If circular dependencies exist, note them with `-- TODO: resolve circular FK dependency` and scaffold in arbitrary order.

### SQL Databases (postgresql / mysql / sqlite)

For each entity, generate two migration files:

**Forward: `NNN_create_<table>_table.sql`**
```sql
-- Migration: NNN_create_payments_table
-- Entity: Payment
-- TODO: verify field types and constraints before running

BEGIN;

CREATE TABLE payments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),   -- or BIGSERIAL if idStrategy=bigserial
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    amount      NUMERIC(12, 2) NOT NULL,
    currency    VARCHAR(3) NOT NULL DEFAULT 'USD',
    status      VARCHAR(32) NOT NULL DEFAULT 'pending',       -- TODO: consider ENUM type
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
-- TODO: add composite index if queries filter by (user_id, status)

COMMIT;
```

**Rollback: `NNN_create_<table>_table.rollback.sql`**
```sql
-- Rollback: NNN_create_payments_table

BEGIN;
DROP TABLE IF EXISTS payments;
COMMIT;
```

Rules:
- Always include `id`, `created_at`, `updated_at` — add if not in data model
- `id` type: `UUID PRIMARY KEY DEFAULT gen_random_uuid()` for uuid strategy, `BIGSERIAL PRIMARY KEY` for bigserial
- Mark every assumption with `-- TODO: verify ...`
- Add a `-- Indexes` section — include all flagged indexes plus any FK columns
- Use `TIMESTAMPTZ` for timestamps (PostgreSQL), `DATETIME` for MySQL, `TEXT` for SQLite
- Use `NUMERIC(precision, scale)` for money — never FLOAT

### NoSQL Databases (mongodb)

```javascript
// Migration: NNN_create_payments_collection
// Entity: Payment
// TODO: verify schema and indexes before running

db.createCollection("payments", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "amount", "currency", "status", "createdAt"],
      properties: {
        userId:    { bsonType: "string", description: "Reference to users collection" },
        amount:    { bsonType: "decimal", description: "Payment amount — TODO: confirm decimal precision" },
        currency:  { bsonType: "string", maxLength: 3 },
        status:    { bsonType: "string", enum: ["pending", "completed", "failed"] },
        metadata:  { bsonType: "object" },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

db.payments.createIndex({ userId: 1 });
db.payments.createIndex({ status: 1 });
```

Rollback (same file, commented section):
```javascript
// Rollback:
// db.payments.drop();
```

---

## Step 4: Write Artifact Files

Write one migration file per entity to `$MIGRATIONS_DIR/`.

Also write `$MIGRATIONS_DIR/README.md`:
```markdown
# Database Migrations
*Generated: [date] | Total migrations: [N]*

Run migrations in the order listed below. Do not skip.

| # | File | Entity | Depends On |
|---|------|--------|------------|
| 001 | 001_create_users_table.sql | User | — |
| 002 | 002_create_payments_table.sql | Payment | users |
[one row per migration, ordered by dependency]

## Running Migrations

Integrate with your migration runner (Flyway, Liquibase, golang-migrate, Alembic, etc.).
Each .sql file is idempotent — run `IF NOT EXISTS` checks are included where applicable.

## Rollback

Each migration has a matching `.rollback.sql` file. Run in reverse order.
```

---

## Step 5: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "migrate-scaffold",
  "triggeredAfter": "data-model",
  "status": "completed",
  "artifact": "<MIGRATIONS_DIR>/README.md",
  "summary": "<N> migration stubs created for entities: <entity-list>",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 6: Output

If `--auto-chain`:
```
✅ migrate-scaffold — <N> migrations scaffolded [<MIGRATIONS_DIR>/]
```

If interactive:
```
✅ Migration Scaffold Complete

Migrations created: [N]
  [list: NNN_create_<table>_table.sql for each entity]

Database: [database type] | ID strategy: [uuid/bigserial]

Assumptions made (review before running):
  • [any TODO notes that were flagged — e.g. enum vs varchar, decimal precision]

Artifacts: [MIGRATIONS_DIR]/
  README.md — run order and dependency map
  [N] forward migrations
  [N] rollback migrations

Next step: Review TODOs, integrate with your migration runner, then run sdlc:08-code.
```
