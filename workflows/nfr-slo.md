# NFR SLO Workflow

Derives complete SLO definitions from the SLO candidates identified in nfr-analysis.md and scaffolds them into slo-definitions.md, with alert rule skeletons ready for Prometheus/Alertmanager or equivalent.

**Triggered after:** nfr-analysis skill completes. This workflow is called inline at the end of `workflows/nfr-analysis.md` after Step 6 (Update State), or can be invoked independently from orchestrate.md. The sub-chain is: idea phase → nfr-analysis → nfr-slo.

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/nfr-analysis"
OBS_ARTIFACTS="$ARTIFACTS/observability"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Read NFR Analysis and Extract SLO Candidates

Read `$PHASE_ARTIFACTS/nfr-analysis.md`.

Find the `## SLO Candidates for Observability Phase` section. Extract every row:
```
NFR-ID: [e.g. NFR-001]
Proposed SLO metric: [e.g. "http_request_duration_seconds p95"]
Target: [e.g. "< 200ms"]
Error budget: [e.g. "0.5% = ~3.6h/month"]
```

If the section does not exist or contains no rows:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "No SLO candidates in nfr-analysis.md" }` and output `⏭️ nfr-slo — skipped: no SLO candidates found in nfr-analysis.md`
- If interactive: inform the user and stop.

---

## Step 2: Delta Check Against Existing SLOs

Check if `$OBS_ARTIFACTS/observability.md` exists. If it does, scan it for any `SLO-NNN:` blocks already defined. Track which NFR-IDs already have SLOs.

Only generate SLO definitions for NFR-IDs not already represented.

Check if `$PHASE_ARTIFACTS/slo-definitions.md` already exists. If so, append to it rather than overwrite. Track the highest existing `SLO-NNN` number to continue the sequence.

---

## Step 3: Generate SLO Definition Blocks

For each SLO candidate, derive a complete SLO definition. Assign sequential `SLO-NNN` identifiers (SLO-001, SLO-002, …).

Use the NFR category to infer the right metric type:

| NFR Category | Metric type | Prometheus metric example |
|---|---|---|
| Performance | Latency histogram | `http_request_duration_seconds` |
| Availability | Success rate / uptime | `http_requests_total{status!~"5.."}` |
| Scalability | Throughput / queue depth | `http_requests_total`, `queue_depth` |
| Resilience | Error rate / circuit state | `http_requests_total{status=~"5.."}` |
| Security | Auth failure rate | `auth_failures_total` |

**Error budget calculation rules:**
- 99.9% target = 0.1% budget = 43.8 min/month downtime allowed
- 99.5% target = 0.5% budget = 3.65 hours/month
- 99.0% target = 1.0% budget = 7.3 hours/month
- 95.0% target = 5.0% budget = 36.5 hours/month

**Burn rate alert thresholds:**
- 2x burn rate = budget consumed 2x faster than allowed → page (warning)
- 5x burn rate = critical, exhausting budget rapidly → page immediately (critical)
- 14.4x burn rate = budget gone in 1 hour → immediate escalation

**SLO definition block format:**
```
SLO-001: API Response Latency (derived from NFR-001)
NFR source: NFR-001
Metric: http_request_duration_seconds p95
Target: < 200ms over rolling 30-day window
Measurement window: rolling 30-day
Error budget: 99.5% target = 0.5% = ~3.65 hours/month
Burn rate alert thresholds:
  - 2x burn rate → warning (budget consumed in ~15 days)
  - 5x burn rate → critical (budget consumed in ~6 days)

Alert rule skeleton:
  - alert: SLO_001_LatencyBurnRateCritical
    expr: |
      (
        rate(http_request_duration_seconds_bucket{le="0.2"}[1h])
        / rate(http_request_duration_seconds_count[1h])
      ) < 0.995
    for: 2m
    labels:
      severity: critical
      slo: SLO-001
    annotations:
      summary: "SLO-001 burn rate critical — p95 latency exceeding 200ms"
      runbook: "TODO: link to runbook"

  - alert: SLO_001_LatencyBurnRateWarning
    expr: |
      (
        rate(http_request_duration_seconds_bucket{le="0.2"}[6h])
        / rate(http_request_duration_seconds_count[6h])
      ) < 0.995
    for: 15m
    labels:
      severity: warning
      slo: SLO-001
    annotations:
      summary: "SLO-001 burn rate warning — p95 latency trend exceeding budget"
      runbook: "TODO: link to runbook"
```

Generate one complete block per SLO candidate.

---

## Step 4: Write Artifact Files

Write `$PHASE_ARTIFACTS/slo-definitions.md` (create or append):

```markdown
# SLO Definitions
*Generated: [date] | Derived from: nfr-analysis.md | SLOs defined: [N]*

> These SLOs are derived from NFR candidates. Implement alert rules using Prometheus/Alertmanager,
> Datadog SLO tracking, or equivalent. Each SLO-NNN maps back to an NFR-NNN in nfr-analysis.md.

## SLO Summary

| SLO-ID | NFR Source | Metric | Target | Error Budget |
|--------|-----------|--------|--------|-------------|
[one row per SLO]

---

[full SLO definition blocks from Step 3]
```

If `$OBS_ARTIFACTS/observability.md` already exists, append the following section to it:

```markdown
## SLOs (Auto-generated from NFR Analysis)

> Source: nfr-analysis/slo-definitions.md — [N] SLOs derived from NFRs.
> Incorporate these into your observability stack. Alert rules are in slo-definitions.md.

[SLO summary table]
```

If observability.md does not yet exist, add a note in slo-definitions.md:
```
> NOTE: observability.md not yet created. Incorporate these SLOs when running sdlc:11-observability.
```

---

## Step 5: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "nfr-slo",
  "triggeredAfter": "nfr-analysis",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/slo-definitions.md",
  "summary": "<N> SLO definitions generated with alert rule skeletons from <M> NFR candidates",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 6: Output

If `--auto-chain`:
```
✅ nfr-slo — <N> SLOs defined with alert rules [<PHASE_ARTIFACTS>/slo-definitions.md]
```

If interactive:
```
✅ NFR SLO Definitions Complete

SLOs generated: [N]
  [list: SLO-NNN — metric — target]

Error budgets calculated: [N]
Alert rule skeletons: [N] (critical + warning per SLO)

Artifacts:
  • [PHASE_ARTIFACTS]/slo-definitions.md — full SLO blocks + Prometheus alert skeletons
  [if observability.md exists:]
  • [OBS_ARTIFACTS]/observability.md — SLO summary section appended

Next step: Review alert rule expressions against your actual metric names, then implement
in your observability stack. Run sdlc:11-observability to complete the observability phase.
```
