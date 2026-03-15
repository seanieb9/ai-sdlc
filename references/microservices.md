# Microservices Standards Reference

## Service Design Principles

### The Non-Negotiables
1. **One bounded context per service** — service boundaries follow domain boundaries, never technical ones (don't split a domain object across services)
2. **Own your data** — each service has its own database schema/instance; no shared databases across service boundaries
3. **Design for failure** — every service call can and will fail; handle it explicitly
4. **Smart endpoints, dumb pipes** — business logic lives in services, not in the message broker or API gateway
5. **Evolutionary design** — services must be independently deployable; if you can't deploy one service without deploying another, the boundary is wrong

### When NOT to use microservices
- Team < 5 engineers: start with a modular monolith, extract services when you have proven scaling bottlenecks
- Domain not yet stable: microservices ossify boundaries — get the domain model right first
- No independent scaling requirements: shared load doesn't justify the operational overhead
- No independent deployment cadence: if services always deploy together, they're a distributed monolith

### Service sizing
- A service should be the smallest unit that can be independently:
  - Deployed without coordinating with other teams
  - Scaled independently
  - Maintained by a team of 2–5 engineers
- Too small = chatty network calls, distributed monolith overhead
- Too large = back to a monolith — split when a bounded context is clearly independent

---

## Directory Structure (per service)

```
{service-name}/
├── src/
│   ├── domain/               ← entities, value objects, domain services, repository interfaces
│   ├── application/          ← use cases, command/query handlers, port interfaces
│   ├── infrastructure/       ← repository implementations, adapters, migrations
│   └── delivery/             ← HTTP controllers, event consumers, composition root
├── tests/
│   ├── unit/                 ← domain + application tests (no I/O)
│   ├── integration/          ← infrastructure tests (real DB, test containers)
│   ├── contract/             ← API contract tests (consumer-driven or provider)
│   └── e2e/                  ← end-to-end journey tests
├── migrations/               ← DB migration files (timestamped, up+down)
├── Dockerfile                ← multi-stage production build
├── Dockerfile.dev            ← development image with hot reload
├── docker-compose.yml        ← local development stack (service + all dependencies)
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── hpa.yaml
│   │   └── pdb.yaml
│   └── overlays/
│       ├── staging/
│       └── production/
├── .github/workflows/
│   ├── ci.yml                ← build, test, lint, scan, push image
│   └── cd.yml                ← deploy to environment on merge/tag
└── README.md                 ← local setup, env vars, runbook links
```

---

## Docker Build Standards

### Multi-stage Dockerfile (Node.js example — adapt for language)

```dockerfile
# ─── Stage 1: Dependencies ───────────────────────────────────────────────────
FROM node:22-alpine AS deps
WORKDIR /app

# Copy only package files first — cache this layer
COPY package.json package-lock.json ./
RUN npm ci --only=production && cp -R node_modules /app/prod_modules
RUN npm ci  # install dev deps for build

# ─── Stage 2: Build ──────────────────────────────────────────────────────────
FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build     # compile TypeScript, bundle, etc.
RUN npm test          # fail the build if tests fail — tests run in Docker

# ─── Stage 3: Production image ───────────────────────────────────────────────
FROM node:22-alpine AS production
WORKDIR /app

# Security: run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy only what's needed at runtime
COPY --from=deps /app/prod_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json

# Build args for version injection (visible in /health/ready response)
ARG APP_VERSION=unknown
ARG GIT_COMMIT=unknown
ENV APP_VERSION=$APP_VERSION
ENV GIT_COMMIT=$GIT_COMMIT

EXPOSE 3000

# Graceful shutdown: give in-flight requests time to complete
STOPSIGNAL SIGTERM
CMD ["node", "dist/main.js"]
```

### Docker best practices
- **Base image**: use official language images on alpine/slim — minimal attack surface
- **Non-root user**: always add a dedicated user, never run as root
- **Layer caching**: copy dependency manifests first, source code second — keeps the expensive `npm ci` layer cached
- **No secrets in images**: never `COPY .env` or `ARG SECRET_KEY` — inject at runtime via environment
- **Image scanning**: scan for CVEs in CI before pushing (Trivy, Snyk, Grype)
- **Image tags**: never use `latest` in deployment manifests — always use a digest or `{version}-{git-sha}`
- **`.dockerignore`**: exclude `node_modules/`, `.git/`, `*.env`, test files, CI configs

```
# .dockerignore
node_modules/
.git/
*.env
.env.*
coverage/
.nyc_output/
dist/          # excluded from build stage context — built inside Docker
*.test.ts
*.spec.ts
k8s/
.github/
```

---

## Local Development with Docker Compose

```yaml
# docker-compose.yml — local development stack
version: '3.9'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
      - "9229:9229"    # Node.js debugger port
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://dev:dev@postgres:5432/order_service_dev
      REDIS_URL: redis://redis:6379
      RABBITMQ_URL: amqp://dev:dev@rabbitmq:5672
      LOG_LEVEL: debug
    volumes:
      - ./src:/app/src    # hot reload — mount source
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: order_service_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    ports:
      - "5672:5672"
      - "15672:15672"    # management UI
    environment:
      RABBITMQ_DEFAULT_USER: dev
      RABBITMQ_DEFAULT_PASS: dev
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

---

## Kubernetes Deployment Standards

### Deployment

```yaml
# k8s/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  labels:
    app: order-service
    version: "1.0.0"
spec:
  replicas: 2               # minimum 2 for availability; HPA scales up from here
  selector:
    matchLabels:
      app: order-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # one extra pod during rollout
      maxUnavailable: 0     # never take pods down before new ones are ready → zero-downtime
  template:
    metadata:
      labels:
        app: order-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: order-service

      # Pod anti-affinity: spread across nodes — don't put all pods on one node
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: order-service
                topologyKey: kubernetes.io/hostname

      # Graceful shutdown: wait for in-flight requests before termination
      terminationGracePeriodSeconds: 30

      containers:
        - name: order-service
          image: registry.example.com/order-service:1.0.0-abc1234    # never use :latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 3000
            - name: metrics
              containerPort: 9090

          # Resource requests/limits — ALWAYS set both
          # Requests: what the scheduler reserves; Limits: hard cap
          resources:
            requests:
              cpu: 100m        # 0.1 vCPU
              memory: 128Mi
            limits:
              cpu: 500m        # 0.5 vCPU — prevent a runaway process starving the node
              memory: 256Mi    # OOMKilled if exceeded — set higher than typical working set

          # Environment: non-sensitive config from ConfigMap
          envFrom:
            - configMapRef:
                name: order-service-config

          # Sensitive values from Secrets (never in ConfigMap)
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: order-service-secrets
                  key: database_url
            - name: RABBITMQ_URL
              valueFrom:
                secretKeyRef:
                  name: order-service-secrets
                  key: rabbitmq_url

          # Probes — all three serve different purposes
          startupProbe:             # allow slow startup before liveness kicks in
            httpGet:
              path: /health/startup
              port: http
            failureThreshold: 30   # 30 × 2s = 60 seconds to start
            periodSeconds: 2

          livenessProbe:            # is the process alive? restart if not
            httpGet:
              path: /health/live
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            failureThreshold: 3
            timeoutSeconds: 2

          readinessProbe:           # is it ready for traffic? remove from LB if not
            httpGet:
              path: /health/ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
            timeoutSeconds: 2

          # Graceful shutdown hook
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 5"]  # wait for LB to drain before SIGTERM
```

### Service

```yaml
# k8s/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
    - name: http
      port: 80
      targetPort: http
    - name: metrics
      port: 9090
      targetPort: metrics
  type: ClusterIP    # internal only — access via Ingress or API gateway
```

### ConfigMap (non-sensitive config)

```yaml
# k8s/base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
data:
  NODE_ENV: production
  LOG_LEVEL: info
  LOG_FORMAT: json
  PORT: "3000"
  METRICS_PORT: "9090"
  OTEL_SERVICE_NAME: order-service
  OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4318
```

### Horizontal Pod Autoscaler

```yaml
# k8s/base/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70    # scale up when avg CPU > 70%
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60     # wait 60s before scaling up again
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60              # add max 2 pods per minute
    scaleDown:
      stabilizationWindowSeconds: 300    # wait 5 minutes before scaling down
```

### Pod Disruption Budget (maintenance safety)

```yaml
# k8s/base/pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service
spec:
  minAvailable: 1    # always keep at least 1 pod running during node drains/upgrades
  selector:
    matchLabels:
      app: order-service
```

### Kustomize overlays

```yaml
# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
patches:
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 4
    target:
      kind: Deployment
      name: order-service
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources/requests/memory
        value: 256Mi
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: 512Mi
    target:
      kind: Deployment
      name: order-service
images:
  - name: registry.example.com/order-service
    newTag: "${IMAGE_TAG}"    # injected by CI/CD
```

---

## Secrets Management

**Never:**
- Store secrets in container images
- Store secrets in ConfigMaps
- Commit secrets to git (even encrypted)
- Pass secrets as build args

**In Kubernetes:**
- Use Kubernetes Secrets (base64 encoded, not encrypted by default) → enable encryption at rest in etcd
- Better: use External Secrets Operator to sync from AWS Secrets Manager / GCP Secret Manager / HashiCorp Vault
- Mount secrets as environment variables or volume mounts — not both

**External Secrets Operator pattern (recommended):**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: order-service-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend         # or aws-secrets-manager, gcp-secrets-manager
    kind: ClusterSecretStore
  target:
    name: order-service-secrets  # creates this K8s Secret
  data:
    - secretKey: database_url
      remoteRef:
        key: order-service/production
        property: database_url
```

---

## CI/CD Pipeline

### GitHub Actions — CI

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/order-service

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: order_service_test
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 3s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/order_service_test
      - uses: codecov/codecov-action@v4     # upload coverage report

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
      image_digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix={{branch}}-
            type=semver,pattern={{version}}

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            APP_VERSION=${{ github.ref_name }}
            GIT_COMMIT=${{ github.sha }}

      - name: Scan image for CVEs
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
          severity: CRITICAL,HIGH
          exit-code: 1    # fail CI on critical/high CVEs
```

### GitHub Actions — CD

```yaml
# .github/workflows/cd.yml
name: CD

on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v3

      - name: Configure kubeconfig
        run: echo "${{ secrets.KUBECONFIG_STAGING }}" | base64 -d > kubeconfig.yaml

      - name: Deploy to staging
        env:
          KUBECONFIG: kubeconfig.yaml
          IMAGE_TAG: main-${{ github.event.workflow_run.head_sha }}
        run: |
          cd k8s/overlays/staging
          kustomize edit set image registry.example.com/order-service=*:$IMAGE_TAG
          kubectl apply -k .
          kubectl rollout status deployment/order-service -n staging --timeout=5m

      - name: Run smoke tests
        run: npm run test:smoke -- --base-url=https://staging.api.example.com

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production    # requires manual approval in GitHub environments
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        env:
          IMAGE_TAG: main-${{ github.event.workflow_run.head_sha }}
        run: |
          cd k8s/overlays/production
          kustomize edit set image registry.example.com/order-service=*:$IMAGE_TAG
          kubectl apply -k .
          kubectl rollout status deployment/order-service -n production --timeout=10m
```

---

## Graceful Shutdown Implementation

Every service must handle SIGTERM gracefully — stop accepting new requests, finish in-flight ones, close DB connections:

```typescript
// src/delivery/server.ts
const server = app.listen(PORT)

process.on('SIGTERM', async () => {
  logger.info('shutdown.started', { signal: 'SIGTERM' })

  // 1. Stop accepting new connections
  server.close(async () => {
    try {
      // 2. Wait for in-flight requests to complete (handled by server.close)
      // 3. Close DB pool
      await db.pool.end()
      // 4. Close message broker connection
      await messageBroker.close()
      // 5. Flush any pending telemetry
      await tracer.shutdown()

      logger.info('shutdown.completed')
      process.exit(0)
    } catch (err) {
      logger.error('shutdown.failed', { error: String(err) })
      process.exit(1)
    }
  })

  // Safety net: force exit after grace period
  setTimeout(() => {
    logger.error('shutdown.timeout_forced')
    process.exit(1)
  }, 25000)   // 5 seconds less than terminationGracePeriodSeconds
})
```

---

## Health Endpoints — Standard Implementation

All three endpoints required (referenced from Kubernetes probe config above):

```typescript
// GET /health/live — is the process alive?
// Returns 200 always unless the process is in a broken state (e.g. event loop stuck)
router.get('/health/live', (req, res) => {
  res.status(200).json({ status: 'alive' })
})

// GET /health/ready — is it ready to serve traffic?
// Checks DB connection and any critical dependencies
router.get('/health/ready', async (req, res) => {
  const checks = await Promise.allSettled([
    db.query('SELECT 1'),                    // DB reachable
    redis.ping(),                            // cache reachable
  ])

  const failed = checks
    .map((r, i) => ({ name: ['db', 'redis'][i], ok: r.status === 'fulfilled' }))
    .filter(c => !c.ok)

  if (failed.length > 0) {
    return res.status(503).json({ status: 'unavailable', failing: failed.map(f => f.name) })
  }

  res.status(200).json({ status: 'ready' })
})

// GET /health/startup — for slow-starting services (one-time check)
router.get('/health/startup', async (req, res) => {
  // Check migrations have run
  const migrated = await db.migrationsComplete()
  if (!migrated) {
    return res.status(503).json({ status: 'starting', reason: 'migrations_pending' })
  }
  res.status(200).json({ status: 'started', version: process.env.APP_VERSION })
})
```

---

## Inter-Service Communication Standards

### Synchronous (REST/gRPC)
- Always set explicit timeouts — never rely on system defaults
- Implement circuit breaker (e.g. Opossum for Node.js, resilience4j for Java)
- Use correlation IDs and pass them in headers (`X-Correlation-ID`)
- Accept `application/json`, return `application/json`
- Document all service-to-service calls in TECH_ARCHITECTURE.md

```typescript
// Service client with timeout + circuit breaker
const breaker = new CircuitBreaker(
  (orderId: string) => fetch(`http://inventory-service/api/v1/stock/${orderId}`, {
    signal: AbortSignal.timeout(2000),   // 2s timeout
    headers: { 'X-Correlation-ID': correlationId }
  }),
  { timeout: 2000, errorThresholdPercentage: 50, resetTimeout: 10000 }
)
```

### Asynchronous (Events)
- Follow the event envelope standard (see code workflow Step 4e)
- Services must not depend on the internal data shape of another service
- Use correlation IDs from the event envelope for distributed tracing

---

## Service Mesh (Istio/Linkerd — optional but recommended at scale)

When to adopt:
- 5+ services in production
- mTLS between services is a compliance requirement
- Need traffic management (canary, weighted routing, retries at mesh level)

What it handles automatically (no code changes):
- mTLS between all service-to-service calls
- Automatic retries and circuit breaking at the proxy level
- Distributed tracing injection (Jaeger/Zipkin)
- Traffic metrics (RED) without application instrumentation

What still requires code:
- Business-level error handling
- Application-level timeouts (set shorter than mesh-level timeouts)
- Business correlation IDs (not provided by the mesh)

---

## API Gateway Standards

Use an API gateway as the single ingress for external traffic:

Responsibilities of the gateway:
- TLS termination
- Authentication (JWT validation / API key verification)
- Rate limiting (per client, per endpoint)
- Request routing to upstream services
- Response caching (read-heavy endpoints)
- Request/response logging for audit

NOT the gateway's responsibility (keep in services):
- Business logic
- Authorization (who can do what — services own this)
- Data transformation beyond protocol translation

Recommended: Kong, AWS API Gateway, Nginx with OpenResty, Traefik

---

## Environment Parity

Local dev, staging, and production must be as similar as possible:

| Concern | Local | Staging | Production |
|---------|-------|---------|------------|
| DB engine | Same version (Docker) | Same as prod | PostgreSQL 16 |
| OS | Alpine via Docker | Alpine | Alpine |
| Config injection | `.env` file | K8s ConfigMap | K8s ConfigMap |
| Secrets | `.env` file | External Secrets | External Secrets |
| Message broker | Docker Compose | Managed service | Managed service |
| Observability | Jaeger local | Full stack | Full stack |

Never test against a different DB engine than production. SQLite in dev, PostgreSQL in prod causes bugs that only appear in production.
