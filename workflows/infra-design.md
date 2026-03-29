# Infra Design Workflow

Generates infrastructure configuration files (Dockerfile, docker-compose, Kubernetes manifests, CI pipeline) based on project config and technical architecture.

---

## Step 0: Workspace Resolution

@/Users/seanlew/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/infra-design"
mkdir -p "$PHASE_ARTIFACTS"
mkdir -p "$PHASE_ARTIFACTS/k8s"
mkdir -p "$PHASE_ARTIFACTS/ci"
```

---

## Step 1: Read Config

Look for `.claude/ai-sdlc.config.yaml` in the project root.

Extract these fields if present:
```
containerRuntime:  [Docker / Podman / none]
orchestrator:      [Kubernetes / ECS / docker-compose / none]
ciPlatform:        [github-actions / gitlab-ci / jenkins / circleci / none]
language:          [node / python / go / java / ruby / other]
framework:         [express / fastapi / gin / spring / rails / other]
port:              [application port number, default 3000]
```

If `.claude/ai-sdlc.config.yaml` does not exist or has no containerRuntime/orchestrator set:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "No containerRuntime or orchestrator in config" }` and output `⏭️ infra-design — skipped: no container config found`
- If interactive: ask the user to specify containerRuntime and orchestrator, then proceed.

---

## Step 2: Read Architecture Artifacts

Read in parallel:
- `$ARTIFACTS/design/tech-architecture.md` — services, dependencies, environment variables, health check endpoints
- `$ARTIFACTS/data-model/data-model.md` — to understand database and storage dependencies (if exists)

Build a services inventory:
```
Service: [name]
Role: [API / Worker / Scheduler / Frontend / Database / Cache / Queue / Other]
Language/Runtime: [from config or architecture]
Port: [from architecture or config]
Environment variables: [list required env vars]
Depends on: [other services]
Health check path: [/health/live or as defined in architecture]
Scaling: [stateless yes/no]
```

Also identify all external dependencies (databases, caches, queues, external APIs) that need to be represented in compose or K8s.

---

## Step 3: Generate Dockerfile (if containerRuntime: Docker or Podman)

Write `$PHASE_ARTIFACTS/Dockerfile`.

Requirements:
- Multi-stage build: `builder` stage for compilation/dependencies, `runtime` stage for final image
- Use specific version tags (not `latest`) — use latest stable LTS versions appropriate to the language
- Non-root user in runtime stage: `RUN addgroup --system app && adduser --system --ingroup app app` (or equivalent for the base image)
- WORKDIR set explicitly
- Copy only the built artifact into the runtime stage (no source code, no dev dependencies)
- HEALTHCHECK instruction using the health endpoint from the architecture
- EXPOSE the application port
- CMD uses exec form (array syntax)

Template by language:

**Node.js:**
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:22-alpine AS runtime
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder --chown=app:app /app/dist ./dist
COPY --from=builder --chown=app:app /app/node_modules ./node_modules
USER app
EXPOSE [PORT]
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:[PORT]/health/live || exit 1
CMD ["node", "dist/index.js"]
```

**Python:**
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime
RUN groupadd --system app && useradd --system --gid app app
WORKDIR /app
COPY --from=builder /install /usr/local
COPY --chown=app:app . .
USER app
EXPOSE [PORT]
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:[PORT]/health/live')" || exit 1
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "[PORT]"]
```

**Go:**
```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/server

FROM gcr.io/distroless/static-debian12 AS runtime
COPY --from=builder /app/server /server
EXPOSE [PORT]
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/server", "-healthcheck"]
USER nonroot:nonroot
CMD ["/server"]
```

Adapt to the actual language/framework from config. Substitute the actual port and health check path.

---

## Step 4: Generate docker-compose.yml (if orchestrator: docker-compose or always alongside Dockerfile for local dev)

Write `$PHASE_ARTIFACTS/docker-compose.yml`.

Requirements:
- Version: `"3.9"` or omit version for newer Docker Compose
- One service per entry in the services inventory
- External dependencies (Postgres, Redis, RabbitMQ, etc.) use official images with pinned versions
- Named volumes for persistent data
- Named network for service isolation
- Environment variables as references to `.env` file (include a `.env.example` comment block)
- Healthcheck on every service that has one defined
- `depends_on` with `condition: service_healthy` where appropriate
- `restart: unless-stopped` for production-like services

Template:
```yaml
# docker-compose.yml
# Copy .env.example to .env and fill in values before running
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: runtime
    ports:
      - "${API_PORT:-3000}:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health/live"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:

networks:
  app-network:
    driver: bridge
```

Adapt to the actual services from the inventory. Remove services not needed.

---

## Step 5: Generate Kubernetes Manifests (if orchestrator: Kubernetes)

Write files under `$PHASE_ARTIFACTS/k8s/`.

For each application service (not managed infrastructure like databases — those would use operators or managed services):

**`$PHASE_ARTIFACTS/k8s/[service]-deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: [service]
  labels:
    app: [service]
    version: "1.0.0"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: [service]
  template:
    metadata:
      labels:
        app: [service]
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: [service]
          image: [service]:latest
          ports:
            - containerPort: [PORT]
          envFrom:
            - configMapRef:
                name: [service]-config
            - secretRef:
                name: [service]-secrets
          livenessProbe:
            httpGet:
              path: /health/live
              port: [PORT]
            initialDelaySeconds: 10
            periodSeconds: 30
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health/ready
              port: [PORT]
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      terminationGracePeriodSeconds: 30
```

**`$PHASE_ARTIFACTS/k8s/[service]-service.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: [service]
spec:
  selector:
    app: [service]
  ports:
    - port: 80
      targetPort: [PORT]
  type: ClusterIP
```

**`$PHASE_ARTIFACTS/k8s/[service]-configmap.yaml`:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: [service]-config
data:
  NODE_ENV: "production"
  PORT: "[PORT]"
  # Add non-sensitive config here
  # Sensitive values go in Secrets
```

**`$PHASE_ARTIFACTS/k8s/[service]-hpa.yaml`:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: [service]
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: [service]
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

**`$PHASE_ARTIFACTS/k8s/[service]-pdb.yaml`:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: [service]
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: [service]
```

Generate files for each application service. Use actual service names, ports, and environment variables from the inventory.

---

## Step 6: Generate CI Pipeline (if ciPlatform set)

**GitHub Actions** — write `$PHASE_ARTIFACTS/ci/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  lint:
    name: Lint & Format Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4  # adapt to language
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run format:check

  test:
    name: Test & Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run build

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm audit --audit-level=high

  docker-build:
    name: Docker Build
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**GitLab CI** — write `$PHASE_ARTIFACTS/ci/.gitlab-ci.yml`:

```yaml
stages:
  - lint
  - test
  - build
  - security

variables:
  NODE_VERSION: "22"

lint:
  stage: lint
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci
    - npm run lint
    - npm run format:check

test:
  stage: test
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci
    - npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

build:
  stage: build
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci
    - npm run build
  needs: [lint, test]

security:
  stage: security
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci
    - npm audit --audit-level=high
```

Generate only the pipeline for the configured ciPlatform. Adapt the language/runtime setup steps to match the config.

---

## Step 7: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "infra-design",
  "triggeredAfter": "design",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/",
  "summary": "Generated: <list of files created>",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 8: Output

If `--auto-chain`:
```
✅ infra-design — generated [Dockerfile, docker-compose.yml, k8s/N manifests, ci/pipeline] [<PHASE_ARTIFACTS>/]
```

If interactive:
```
✅ Infra Design Complete

Files generated:
  [list each file created with its path]

Notes:
  - Copy $PHASE_ARTIFACTS/Dockerfile to project root when ready
  - Copy $PHASE_ARTIFACTS/ci/ci.yml to .github/workflows/ (GitHub Actions)
  - Review resource limits in k8s manifests before applying to production
  - Add Secret manifests separately — never commit secret values to source control

Next: Review generated files and copy to project root structure
```
