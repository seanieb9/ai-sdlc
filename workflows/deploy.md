# Deploy Workflow

Phase 14 deployment readiness. Verifies CI/CD pipeline health, generates a deployment checklist tailored to the project's architecture, defines smoke tests, and documents the exact rollback procedure. This is a hard gate — no deployment without a clean verification report.

---

## Step 0: Workspace Resolution

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$ARTIFACTS"
```

Then use `$WORKSPACE`, `$STATE`, `$ARTIFACTS` throughout.

---

## Step 1: Gate Check (HARD)

**HARD gate 1:** `$ARTIFACTS/verify/verification-report.md` must exist AND show 0 open CRITICAL findings.

Read the report. If any CRITICAL findings are open: STOP. Output the list of open criticals and tell the user they must be resolved before deployment.

**HARD gate 2 (conditional):** If `$ARTIFACTS/uat/uat-plan.md` exists: check that `phases.uat.signedOffBy` in state.json is not null. If UAT was performed but no sign-off is recorded: WARN. Ask the user to confirm they want to deploy without sign-off before continuing.

Read in parallel (after gates pass):
- `$ARTIFACTS/verify/verification-report.md`
- `$ARTIFACTS/design/tech-architecture.md` — deployment architecture (if exists)
- `$ARTIFACTS/sre/observability.md` — health check and monitoring setup (if exists)
- `$ARTIFACTS/sre/runbooks.md` — existing runbooks (if exists)
- `.claude/ai-sdlc.config.yaml` — environment config, deployment targets

Note the target environment from `$ARGUMENTS` (e.g., staging, production). If not specified: ask "Which environment are you deploying to?"

**Execution mode check:** If state.json `executionMode` is `"yolo"` or `$ARGUMENTS` contains `--yolo`: proceed fully autonomously. Otherwise: INTERACTIVE mode — confirm the checklist before finalizing.

---

## Step 2: CI/CD Verification

Inspect the repository for CI/CD pipeline configuration. Run the following in parallel:

```bash
# Check for common CI/CD config files
ls .github/workflows/*.yml 2>/dev/null
ls .github/workflows/*.yaml 2>/dev/null
ls .gitlab-ci.yml 2>/dev/null
ls Jenkinsfile 2>/dev/null
ls .circleci/config.yml 2>/dev/null
ls .buildkite/pipeline.yml 2>/dev/null
```

For each pipeline file found: read it and verify required jobs exist:

| Job Type | Required | Found | Status |
|----------|----------|-------|--------|
| build    | YES      | [y/n] | ✅/❌ |
| test     | YES      | [y/n] | ✅/❌ |
| lint     | YES      | [y/n] | ✅/❌ |
| security-scan | YES | [y/n] | ✅/❌ |
| coverage-gate | YES | [y/n] | ✅/❌ |
| deploy   | YES      | [y/n] | ✅/❌ |

**If no CI/CD config found:** This is a HARD WARN. Add to checklist as a blocking item:
```
⚠ BLOCKER: No CI/CD pipeline configuration found.
  A pipeline must be configured before production deployment.
  Manual deployment is permitted for non-production environments with explicit acknowledgment.
```

**If required jobs are missing:** Warn per missing job. List what's missing and the risk.

---

## Step 3: Detect Architecture and Deployment Model

Read tech-architecture.md to determine the deployment model:

- **Kubernetes / K8s**: look for `kubectl`, `helm`, `k8s`, Deployment/Service manifests
- **Docker Compose**: look for `docker-compose.yml`
- **Serverless**: look for `serverless.yml`, AWS Lambda, Vercel, Netlify config
- **PaaS**: look for `Procfile`, `app.yaml`, Heroku/Railway/Render config
- **Static**: look for build output + CDN deployment
- **Bare metal / VM**: no container config found

If architecture doc is missing: ask the user "What is the deployment model? (k8s / docker-compose / serverless / paas / static / vm)"

Deployment steps in the checklist will be tailored to the detected model.

---

## Step 4: Generate Deployment Checklist

Produce a complete, executable deployment checklist. Every item must be actionable — no vague entries.

### Pre-flight Checklist

```
Pre-Deploy
──────────
[ ] All CI/CD pipeline jobs passing on the release branch
[ ] Coverage gate meets threshold ([N]% — from config)
[ ] No open CRITICAL findings in verification report
[ ] UAT sign-off obtained: [name] on [date]  (if applicable)
[ ] Environment variables set in [target env]:
    [ ] [VAR_NAME_1] — [description]
    [ ] [VAR_NAME_2] — [description]
    (list all env vars from config/architecture docs)
[ ] Secrets verified in vault/secrets manager:
    [ ] [secret name]
    [ ] [secret name]
[ ] Database migrations ready:
    [ ] Migration files reviewed for destructive changes
    [ ] Rollback migration script prepared
    [ ] Migration tested in [staging/lower env] successfully
[ ] Feature flags configured:
    [ ] [flag name]: [enabled/disabled for this deploy]
[ ] Downstream service owners notified (if breaking API changes)
[ ] On-call rotation aware of this deployment
[ ] Rollback plan reviewed by deployer (see Rollback Procedure section)
```

### Deployment Steps

Tailor steps to the detected deployment model:

**Kubernetes:**
```
Deployment Steps
────────────────
1. [ ] Confirm current rollout status: kubectl rollout status deployment/[name] -n [namespace]
2. [ ] Apply ConfigMaps/Secrets if changed: kubectl apply -f k8s/config/
3. [ ] Run database migrations: kubectl apply -f k8s/jobs/migration.yaml && kubectl wait --for=condition=complete job/migration -n [namespace]
4. [ ] Apply deployment manifest: kubectl apply -f k8s/deployment/[service].yaml
5. [ ] Monitor rollout: kubectl rollout status deployment/[name] -n [namespace] --timeout=5m
6. [ ] Verify pods are ready: kubectl get pods -n [namespace] -l app=[name]
7. [ ] Run smoke tests (see Post-deploy Verification)
```

**Docker Compose:**
```
Deployment Steps
────────────────
1. [ ] Pull latest images: docker compose pull
2. [ ] Run migrations: docker compose run --rm app [migration command]
3. [ ] Apply rolling update: docker compose up -d --no-deps [service]
4. [ ] Verify container health: docker compose ps
5. [ ] Run smoke tests (see Post-deploy Verification)
```

**Serverless:**
```
Deployment Steps
────────────────
1. [ ] Deploy to [target stage]: [deploy command from config]
2. [ ] Verify function deployment: [CLI check command]
3. [ ] Run smoke tests (see Post-deploy Verification)
```

**PaaS / Generic:**
```
Deployment Steps
────────────────
1. [ ] Trigger deployment via CI/CD pipeline on branch [branch]
2. [ ] Monitor deployment logs until completion
3. [ ] Verify deployment success in [platform dashboard]
4. [ ] Run smoke tests (see Post-deploy Verification)
```

### Post-deploy Verification (Smoke Tests)

List key endpoints or health checks to verify after deployment. Source from observability.md (health endpoints) and api-spec.md (key endpoints):

```
Post-Deploy Verification
────────────────────────
[ ] Health check: GET /health/ready → 200 OK
[ ] Health check: GET /health/live → 200 OK
[ ] Key flow: [describe first critical endpoint or action] → [expected response]
[ ] Key flow: [describe second critical endpoint] → [expected response]
[ ] Monitoring dashboard: no alert spike in first 5 minutes
[ ] Error rate: < [threshold]% in first 10 minutes (check [monitoring tool/URL])
[ ] Latency: p95 < [N]ms (check [monitoring tool/URL])
```

### Rollback Procedure

Document the exact steps to revert — command by command. No ambiguity.

**Kubernetes rollback:**
```
Rollback Procedure
──────────────────
1. Trigger immediate rollback: kubectl rollout undo deployment/[name] -n [namespace]
2. Monitor rollback: kubectl rollout status deployment/[name] -n [namespace]
3. Verify previous version running: kubectl get pods -n [namespace]
4. If migration was run and must be reverted:
   kubectl apply -f k8s/jobs/rollback-migration.yaml
   kubectl wait --for=condition=complete job/rollback-migration -n [namespace]
5. Notify stakeholders: [notification channel/procedure]
6. Create incident record: [incident tracking tool/procedure]
```

**General rollback:**
```
Rollback Procedure
──────────────────
1. Revert to previous deployment: [specific revert command]
2. Verify previous version is serving traffic
3. Revert database migration if applicable: [rollback migration command]
4. Notify stakeholders of rollback
5. Create post-mortem issue
```

### Notification Plan

```
Notification
────────────
On success:
  [ ] Notify: [channel/person] that deployment to [env] is complete
  [ ] Update release tracking: [tool]

On failure / rollback:
  [ ] Notify: [on-call channel]
  [ ] Notify: [stakeholder]
  [ ] Open incident: [tool/procedure]
```

---

## Step 5: Write Artifact

Write `$ARTIFACTS/deploy/deployment-checklist.md` using the content generated in Step 4, formatted cleanly:

```markdown
# Deployment Checklist: [Feature / Project Name]
*Date: [ISO date]*
*Branch: [branch]*
*Target environment: [env]*
*Deployed by: _________________*

---

## CI/CD Pipeline Status

| Job | Status |
|-----|--------|
[table from Step 2]

---

## Pre-flight Checklist
[content from Step 4]

---

## Deployment Steps
[content from Step 4]

---

## Post-deploy Verification
[content from Step 4]

---

## Rollback Procedure
[content from Step 4]

---

## Notification Plan
[content from Step 4]

---

## Sign-off

Deployment verified by: _________________  Date: __________
```

---

## Step 6: Update State

Update `$STATE` (state.json):
- Set `phases.deploy.status` = `"completed"`
- Set `phases.deploy.completedAt` = current ISO timestamp
- Set `phases.deploy.artifacts` = `["deployment-checklist.md"]`
- Set `updatedAt` = current ISO timestamp

---

## Step 7: Checkpoint and Auto-Chain

```
Deployment Checklist Complete
══════════════════════════════
CI/CD:       [N] jobs verified / [N] missing
Pre-flight:  [N] checklist items
Smoke tests: [N] checks defined
Blockers:    [N]  ← if > 0, list them

Artifact: $ARTIFACTS/deploy/deployment-checklist.md
```

If `--dry-run` was set: state that no changes were made to state.json and no deployment was initiated.

Auto-chain suggestions:
```
Recommended next steps:
  → Post-deployment maintenance planning: /sdlc:maintain
  → (If generating release notes separately):  /sdlc:release
```
