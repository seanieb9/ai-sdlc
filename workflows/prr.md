# Production Readiness Review (PRR)

AI-run pre-deployment review. Before any production deployment, run through these checks to confirm the service is safe, observable, operable, and recoverable. The AI performs each check, surfaces findings, and asks the user to confirm before proceeding.

This is NOT a code review. It is an operational review — verifying that what is about to be deployed is genuinely ready for real users.

---

## Step 0: Workspace Resolution
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$ARTIFACTS/prr"
```

---

## Step 1: Pre-Conditions

Read in parallel:
- `$ARTIFACTS/verify/verification-report.md` — REQUIRED. Must show 0 open CRITICAL findings.
- `$ARTIFACTS/sre/runbooks.md` — REQUIRED for production deployments.
- `$ARTIFACTS/sre/observability.md` — REQUIRED.
- `$ARTIFACTS/design/tech-architecture.md` — deployment topology.
- `$ARTIFACTS/design/threat-model.md` — threat model (required if system handles auth or PII).
- `$STATE` — projectAssumptions (team size, compliance, accessibility).

Read projectAssumptions.teamSize from $STATE. Adapt depth:
- `solo-developer`: AI runs every check, presents a clear PASS / NEEDS ATTENTION / BLOCKED summary. User decides whether to proceed.
- `small-team-no-oncall` or larger: same AI-run review, but flag any items the user should discuss with their team before deploying.

If verification-report.md does not exist OR has open CRITICALs: STOP. PRR cannot begin.

---

## Step 2: Runbook Completeness Check

Verify runbooks.md covers these scenarios:
```
[ ] Deployment runbook — step-by-step deploy, with verification commands
[ ] Rollback runbook — exact commands to revert, tested in staging
[ ] SEV1 on-call runbook — "first 5 minutes" procedure
[ ] Database failure runbook — failover or restore procedure
[ ] Service restart runbook — safe restart without data loss
[ ] Key rotation runbook — how to rotate secrets without downtime
```

For each missing runbook: flag as BLOCKING. Runbooks must be written and in runbooks.md before PRR can pass.

---

## Step 3: Observability Completeness Check

Verify these exist and are configured:
```
[ ] /health/live endpoint returns 200 (liveness probe)
[ ] /health/ready endpoint returns 200 with dependency checks
[ ] Structured logging configured — all fields: trace_id, span_id, correlation_id, action, outcome, duration_ms
[ ] RED metrics: rate, error_rate, and duration histograms for all public endpoints
[ ] Error budget dashboard exists (or link to monitoring tool)
[ ] At least 1 P1 alert configured for service down / error rate spike
[ ] No PII in logs (pii-audit report shows 0 violations)
```

For each missing item: flag severity (BLOCKING / WARNING).

---

## Step 4: Resilience Check

Verify resilience design from tech-architecture.md:
```
[ ] All CRITICAL dependencies have circuit breakers configured
[ ] All external calls have explicit timeout values (not framework defaults)
[ ] Retry with backoff configured for transient errors (with max retry cap)
[ ] Graceful SIGTERM handler: in-flight requests drain before shutdown
[ ] Load shedding / rate limiting: system won't accept more than it can handle
[ ] Graceful degradation: system continues serving partial responses when DEGRADABLE deps are down
```

---

## Step 5: Security Check

Verify from threat-model.md and code-quality report:
```
[ ] Threat model exists (if system handles auth or PII) — every threat has a mitigation
[ ] Secrets scan clean (gitleaks: 0 findings)
[ ] Dependency scan: 0 CRITICAL, 0 HIGH CVEs
[ ] Auth endpoints rate-limited
[ ] CORS configured with explicit allowlist (not wildcard *)
[ ] HTTP security headers configured (HSTS, CSP, X-Content-Type-Options)
[ ] All PII fields encrypted at rest and masked in logs
[ ] No debug endpoints exposed in production (health check ok, debug profiling not)
```

---

## Step 6: Scalability + Capacity Check

Verify from NFRs and SRE load test results:
```
[ ] Load test passed at 2x expected peak load (within SLO)
[ ] Database queries reviewed for N+1 anti-patterns
[ ] Database indexes cover all frequent query patterns
[ ] Connection pool size adequate for expected concurrency
[ ] No unbounded memory usage detected under sustained load
[ ] Cost estimate reviewed — acceptable at 2x current load
```

If load test results not available: flag as BLOCKING for production. Permitted for staging deployments.

---

## Step 7: Operational Team Readiness

```
[ ] On-call team briefed on this service/feature (or: solo dev self-brief documented)
[ ] Escalation path documented: who to call if you can't fix it in 30 minutes
[ ] Status page configured (or: "no public status page — internal service only")
[ ] Post-deploy communication plan ready (what to notify, who, when)
[ ] Rollback decision criteria defined: "Rollback if [specific metric] exceeds [specific threshold]"
[ ] Customer support team briefed on new user-facing features (if applicable)
```

---

## Step 8: Data and Compliance Check

Read projectAssumptions.compliance from $STATE:
```
[ ] Data retention policy implemented and automated (if GDPR/HIPAA/CCPA in scope)
[ ] Right-to-erasure procedure tested (if GDPR in scope)
[ ] PII data not leaving its declared data residency region (if applicable)
[ ] Audit log enabled for all sensitive operations (if compliance in scope)
[ ] Backup includes all new tables/entities added in this release
[ ] Backup restore tested within last 7 days
```

If compliance is "none": check only the last two items.

---

## Step 9: Accessibility Check

Read projectAssumptions.accessibility from $STATE:
If "wcag-aa":
```
[ ] Accessibility review completed (axe-core score >= 90)
[ ] Manual screen reader test passed for primary user journey
[ ] All forms have accessible labels
[ ] All interactive elements keyboard accessible
```
If "best-effort": perform automated axe-core check only.
If "not-applicable": skip this section.

---

## Step 10: PRR Summary and User Decision

Compile all findings and present a clear summary to the user. The AI makes a recommendation; the user makes the final call.

**BLOCKING items** — things that make the deployment unsafe right now. List each with what specifically needs to be fixed:
```
BLOCKED: [check] — [exactly what to do to resolve this]
```

**NEEDS ATTENTION** — things that should be addressed but won't cause an immediate incident. The user may choose to deploy anyway and fix these post-deploy:
```
NEEDS ATTENTION: [check] — [recommended action, suggested timeframe]
```

Present the recommendation to the user:

```
PRR Review Complete
══════════════════════════════════════════
Deployment: [branch] → [environment]
Blocking issues:      [N]
Needs attention:      [N]

Recommendation: [READY TO DEPLOY / FIX BEFORE DEPLOYING / NEEDS ATTENTION]

[If blocking issues exist: list them here with fix instructions]
[If needs-attention items exist: list them here]

→ How would you like to proceed?
  1. Fix the blocking issues now (I'll help)
  2. Proceed anyway — I understand the risks  [only valid if no BLOCKING items]
  3. Cancel this deployment
```

Wait for user's response before writing the artifact or updating state.

---

## Step 11: Write PRR Artifact

After the user confirms how to proceed, write `$ARTIFACTS/prr/prr-report.md`:

```markdown
# Production Readiness Review
*Date: [ISO date]*
*Branch: [branch] → [environment]*
*Decision: READY / DEPLOYED WITH KNOWN RISKS / BLOCKED*

## Blocking Issues
[list or "None"]

## Needs Attention
[list or "None"]

## Checklist Summary

| Area | Status | Notes |
|------|--------|-------|
| Runbooks | ✅ / ⚠️ / ❌ | |
| Observability | ✅ / ⚠️ / ❌ | |
| Resilience | ✅ / ⚠️ / ❌ | |
| Security | ✅ / ⚠️ / ❌ | |
| Scalability | ✅ / ⚠️ / ❌ | |
| Data/Compliance | ✅ / ⚠️ / N/A | |
| Accessibility | ✅ / ⚠️ / N/A | |

*Reviewed by AI. User decision: [proceed / fix first / cancelled]*
```

---

## Step 12: Update State

If outcome is APPROVED or APPROVED WITH CONDITIONS:
```json
{
  "phases.prr.status": "completed",
  "phases.prr.completedAt": "<ISO>",
  "phases.prr.outcome": "APPROVED|APPROVED_WITH_CONDITIONS",
  "phases.prr.artifacts": ["prr/prr-report.md"],
  "updatedAt": "<ISO>"
}
```

If REJECTED: set status to "blocked", list blocking items in state.json under `phases.prr.blockers`.

Output:
```
PRR Complete
══════════════════════════════
Outcome: APPROVED | APPROVED WITH CONDITIONS | REJECTED
Blocking items: [N]
Warnings: [N]

Artifact: $ARTIFACTS/prr/prr-report.md

[If APPROVED]: → Ready for the deploy phase (tell Claude to proceed)
[If REJECTED]: → Resolve blocking items, then re-run ask Claude to run the PRR workflow
```
