# Microservices Setup Workflow

Scaffold, containerise, and configure deployment for a microservice. Produces a production-ready service skeleton aligned with the architecture decisions in TECH_ARCHITECTURE.md.

## Step 1: Pre-Flight

Read in parallel:
- `docs/architecture/TECH_ARCHITECTURE.md` — REQUIRED. Service boundaries, tech stack, patterns chosen.
- `docs/architecture/SOLUTION_DESIGN.md` — ADRs for deployment topology, auth strategy, DB choice.
- `docs/data/DATA_MODEL.md` — entities this service owns.
- `.sdlc/STATE.md` — project context, language, constraints.

Determine from `$ARGUMENTS`:
- Service name (kebab-case, e.g. `order-service`)
- Language/framework (if not specified, read from STATE.md or ask)
- Owned bounded context (which entities from DATA_MODEL.md)
- Flags: `--scaffold-only` (no K8s) | `--k8s-only` (no scaffold) | `--ci-only`

If TECH_ARCHITECTURE.md missing: STOP. Architecture must be designed before scaffolding.

---

## Step 2: Confirm Service Spec

Before creating any files, confirm with the user:

```
Service: {service-name}
Language: {language} / {framework}
Owns: {bounded context} — entities: {list from DATA_MODEL.md}
DB: {database type from ADR}
Messaging: {broker type / none}
Port: {HTTP port}
Auth: {JWT/OIDC/API Key/mTLS — from ADR}

Files to create:
  • src/ — clean architecture skeleton
  • Dockerfile + Dockerfile.dev
  • docker-compose.yml (local dev)
  • k8s/base/ — deployment, service, configmap, hpa, pdb
  • k8s/overlays/staging/ + production/
  • .github/workflows/ci.yml + cd.yml
  • migrations/ — initial schema migration
  • README.md — local setup guide

Proceed? (yes/no)
```

---

## Step 3: Scaffold Clean Architecture Skeleton

Create the directory structure and base files following the layer order.

### 3a: Project structure

```
{service-name}/
├── src/
│   ├── domain/
│   │   ├── entities/
│   │   ├── value-objects/
│   │   ├── events/
│   │   ├── services/
│   │   └── repositories/     ← interfaces only
│   ├── application/
│   │   ├── use-cases/
│   │   ├── query-handlers/
│   │   └── ports/            ← external service interfaces
│   ├── infrastructure/
│   │   ├── persistence/      ← repository implementations
│   │   ├── adapters/         ← external service adapters
│   │   ├── messaging/        ← broker publisher + consumer infra
│   │   └── config/
│   └── delivery/
│       ├── http/             ← controllers, middleware, router
│       ├── events/           ← event consumers
│       └── composition-root.ts (or equivalent)
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/
│   └── e2e/
└── migrations/
```

### 3b: Shared kernel files (create once, reference everywhere)

Generate the base exception hierarchy for this service:

```typescript
// src/domain/exceptions.ts
export class DomainException extends Error {
  constructor(message: string, public readonly code: string) {
    super(message)
    this.name = 'DomainException'
  }
}

export class BusinessRuleException extends DomainException {
  constructor(message: string, code: string) {
    super(message, code)
    this.name = 'BusinessRuleException'
  }
}

export class ApplicationException extends Error {
  constructor(message: string, public readonly code: string) {
    super(message)
    this.name = 'ApplicationException'
  }
}

export class NotFoundException extends ApplicationException {
  constructor(message: string) {
    super(message, 'NOT_FOUND')
    this.name = 'NotFoundException'
  }
}

export class ConflictException extends ApplicationException {
  constructor(message: string, code: string) {
    super(message, code)
    this.name = 'ConflictException'
  }
}

export class AuthorizationException extends ApplicationException {
  constructor(message: string) {
    super(message, 'FORBIDDEN')
    this.name = 'AuthorizationException'
  }
}

export class ValidationException extends Error {
  constructor(message: string, public readonly fields: {field: string, message: string}[]) {
    super(message)
    this.name = 'ValidationException'
  }
}

export class InfrastructureException extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'InfrastructureException'
  }
}
```

### 3c: Request context

```typescript
// src/domain/request-context.ts
export class RequestContext {
  constructor(
    public readonly traceId: string,
    public readonly correlationId: string,
    public readonly userId: string | null,
    public readonly roles: string[],
  ) {}

  hasRole(role: string): boolean {
    return this.roles.includes(role)
  }
}
```

### 3d: Entity stubs from DATA_MODEL.md

For each entity owned by this service (read from DATA_MODEL.md):
- Create `src/domain/entities/{EntityName}.ts` with constructor, invariant checks, and domain event collection
- Create `src/domain/repositories/I{EntityName}Repository.ts` with find/save/delete interfaces
- Create `src/domain/events/{EntityName}Events.ts` with all domain events for this entity

### 3e: Health controller stub

```typescript
// src/delivery/http/health.controller.ts
export function createHealthRouter(db: Database, dependencies: Record<string, () => Promise<boolean>>) {
  const router = Router()

  router.get('/health/live', (req, res) => {
    res.status(200).json({ status: 'alive' })
  })

  router.get('/health/ready', async (req, res) => {
    const results = await Promise.allSettled(
      Object.entries(dependencies).map(async ([name, check]) => ({ name, ok: await check() }))
    )
    const failing = results
      .filter(r => r.status === 'rejected' || (r.status === 'fulfilled' && !r.value.ok))
      .map(r => r.status === 'fulfilled' ? r.value.name : 'unknown')

    if (failing.length > 0) {
      return res.status(503).json({ status: 'unavailable', failing })
    }
    res.status(200).json({ status: 'ready' })
  })

  router.get('/health/startup', async (req, res) => {
    const migrated = await db.migrationsComplete()
    if (!migrated) {
      return res.status(503).json({ status: 'starting', reason: 'migrations_pending' })
    }
    res.status(200).json({ status: 'started', version: process.env.APP_VERSION })
  })

  return router
}
```

### 3f: Error handling middleware stub

```typescript
// src/delivery/http/error.middleware.ts
export function errorMiddleware(err: Error, req: Request, res: Response, next: NextFunction) {
  const traceId = (req as any).traceId || 'unknown'

  if (err instanceof ValidationException) {
    return res.status(400).json({ code: 'VALIDATION_ERROR', message: err.message, fields: err.fields, trace_id: traceId })
  }
  if (err instanceof NotFoundException) {
    return res.status(404).json({ code: 'NOT_FOUND', message: err.message, trace_id: traceId })
  }
  if (err instanceof ConflictException) {
    return res.status(409).json({ code: err.code, message: err.message, trace_id: traceId })
  }
  if (err instanceof AuthorizationException) {
    return res.status(403).json({ code: 'FORBIDDEN', message: err.message, trace_id: traceId })
  }
  if (err instanceof DomainException) {
    return res.status(422).json({ code: err.code, message: err.message, trace_id: traceId })
  }
  if (err instanceof InfrastructureException) {
    logger.error('infrastructure_failure', { error: err.message, trace_id: traceId })
    return res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', trace_id: traceId })
  }

  logger.error('unhandled_exception', { error: err.message, stack: err.stack, trace_id: traceId })
  return res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', trace_id: traceId })
}
```

### 3g: Graceful shutdown

```typescript
// src/delivery/server.ts
export function startServer(app: Express, config: ServerConfig): Server {
  const server = app.listen(config.port, () => {
    logger.info('server.started', { port: config.port, version: process.env.APP_VERSION })
  })

  const shutdown = async (signal: string) => {
    logger.info('shutdown.started', { signal })
    server.close(async () => {
      try {
        await config.db.pool.end()
        if (config.broker) await config.broker.close()
        await config.tracer.shutdown()
        logger.info('shutdown.completed')
        process.exit(0)
      } catch (err) {
        logger.error('shutdown.failed', { error: String(err) })
        process.exit(1)
      }
    })
    setTimeout(() => { logger.error('shutdown.timeout'); process.exit(1) }, 25000)
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'))
  process.on('SIGINT', () => shutdown('SIGINT'))

  return server
}
```

### 3h: Initial DB migration

Create `migrations/{timestamp}_create_{entity_table}.sql` for each entity owned by this service, based on DATA_MODEL.md field definitions. Include:
- `up` — CREATE TABLE with all fields, constraints, indexes
- `down` — DROP TABLE
- UUID primary keys (`gen_random_uuid()`)
- `created_at` / `updated_at` TIMESTAMPTZ columns on every table
- `version` INTEGER NOT NULL DEFAULT 0 for optimistic locking on aggregate roots

---

## Step 4: Write Dockerfile

Generate Dockerfile and Dockerfile.dev following the multi-stage build standard from the microservices reference.

Key decisions to fill in:
- Base image version: match language version from STATE.md / TECH_ARCHITECTURE.md
- Build command: from `package.json` scripts or equivalent
- Exposed port: from service spec (Step 2)

Also generate `.dockerignore` with standard exclusions.

---

## Step 5: Write docker-compose.yml

Generate `docker-compose.yml` for local development with:
- The service itself (Dockerfile.dev with hot reload volume mount)
- Database (matching production engine and version)
- Redis (if used for caching or idempotency)
- Message broker (RabbitMQ or Kafka — from ADR)
- Jaeger (for local distributed tracing at `http://localhost:16686`)
- Health checks on every dependency
- Correct `depends_on` with `condition: service_healthy`
- All environment variables with development defaults

---

## Step 6: Write Kubernetes Manifests

Generate `k8s/base/` with all 5 manifests following the standards in the microservices reference:

**deployment.yaml:**
- Fill in service name, image placeholder (`{REGISTRY}/{service-name}:{TAG}`)
- Resource requests/limits appropriate to the service's expected load
- All three probes pointing to health endpoints from Step 3e
- Anti-affinity rules
- Correct terminationGracePeriodSeconds (30s default)
- preStop sleep hook
- envFrom pointing to ConfigMap; secrets via `secretKeyRef`

**service.yaml:**
- ClusterIP type
- HTTP port + metrics port (9090)

**configmap.yaml:**
- All non-sensitive config: LOG_LEVEL, LOG_FORMAT, PORT, OTEL settings, service name

**hpa.yaml:**
- minReplicas: 2, maxReplicas: 10
- CPU target: 70%, Memory target: 80%
- Scale-up stabilization: 60s, scale-down: 300s

**pdb.yaml:**
- minAvailable: 1

Generate `k8s/overlays/staging/kustomization.yaml` and `k8s/overlays/production/kustomization.yaml` with environment-specific patches (replica count, resource limits).

---

## Step 7: Write CI/CD Pipeline

Generate `.github/workflows/ci.yml` and `.github/workflows/cd.yml` following the standards in the microservices reference.

Fill in:
- Correct language/runtime version and setup action
- Test database service (matching production engine)
- Registry URL and image name from TECH_ARCHITECTURE.md
- Smoke test command
- Environment names (staging/production) aligned with GitHub environments config

---

## Step 8: Write README

Generate `README.md` with:

```markdown
# {Service Name}

{One-paragraph description — what this service is responsible for}

## Local Development

**Prerequisites:** Docker, Docker Compose

```bash
# Start all dependencies + service with hot reload
docker compose up

# Run migrations
npm run migrate

# Run tests
npm test

# Run a single test
npm test -- --grep "TC-001"
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| DATABASE_URL | Yes | PostgreSQL connection string |
| REDIS_URL | No | Redis URL (required if caching enabled) |
| RABBITMQ_URL | No | RabbitMQ connection (required if messaging enabled) |
| LOG_LEVEL | No | debug/info/warn/error (default: info) |
| OTEL_EXPORTER_OTLP_ENDPOINT | No | OpenTelemetry collector endpoint |

## Architecture

This service follows clean architecture. See `docs/architecture/TECH_ARCHITECTURE.md`.

Layer dependencies: delivery → application → domain ← infrastructure

## Deployment

Managed by Kustomize overlays in `k8s/overlays/`. CI/CD deploys on merge to `main`.

## Runbooks

See `docs/sre/RUNBOOKS.md` for operational procedures.
```
```

---

## Step 9: Verify Structure

After generating all files, run a self-check:

**Import/dependency rule violations:**
- Scan domain files for any import from application, infrastructure, or delivery
- Scan application files for any import from infrastructure or delivery
- Report any violation — do not leave them to be fixed later

**Missing pieces checklist:**
- [ ] All entities from DATA_MODEL.md have stubs in `src/domain/entities/`
- [ ] All entities have repository interfaces in `src/domain/repositories/`
- [ ] Health endpoints respond to GET (run `docker compose up` mentally)
- [ ] Dockerfile uses non-root user
- [ ] No secrets or `.env` files committed
- [ ] All K8s manifests have resource requests AND limits
- [ ] HPA min >= 2 (single replica = single point of failure)
- [ ] PDB minAvailable >= 1

---

## Step 10: Update State and Docs

Update `.sdlc/STATE.md`:
- Add service to document index
- Note scaffold complete in phase progress

Update `docs/architecture/TECH_ARCHITECTURE.md`:
- Add service to Container diagram if not already present
- Note actual ports, image registry path

Output:
```
✅ {service-name} Scaffold Complete

Files created:
  • src/                           Clean architecture skeleton
  • Dockerfile + Dockerfile.dev    Multi-stage production + dev images
  • docker-compose.yml             Local dev stack
  • k8s/base/ (5 manifests)        Deployment, Service, ConfigMap, HPA, PDB
  • k8s/overlays/staging/          Staging overrides
  • k8s/overlays/production/       Production overrides
  • .github/workflows/ci.yml       Build → test → scan → push
  • .github/workflows/cd.yml       Deploy staging → prod (with approval gate)
  • migrations/{timestamp}_init.sql  Initial schema
  • README.md                      Local setup guide

Entity stubs created:
  • {list entities}

Next steps:
  1. Implement domain entities: /sdlc:08-code --layer domain
  2. Configure secrets in your secrets manager
  3. Create GitHub environments (staging, production) with protection rules
  4. Set KUBECONFIG_STAGING and KUBECONFIG_PRODUCTION secrets in GitHub
```
