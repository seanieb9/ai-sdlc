# NFR Analysis Workflow

Decomposes NFR-NNN entries from the PRD into architectural implications, required patterns, ADR candidates, test layer assignments, and SLO targets.

---

## Step 0: Workspace Resolution

@~/.claude/sdlc/workflows/workspace-resolution.md

After resolution:
```bash
PHASE_ARTIFACTS="$ARTIFACTS/nfr-analysis"
mkdir -p "$PHASE_ARTIFACTS"
```

---

## Step 1: Read PRD and Extract NFRs

Read `$ARTIFACTS/idea/prd.md`.

Search for all NFR-NNN entries. NFRs are typically in a "Non-Functional Requirements" section and follow the pattern `NFR-001`, `NFR-002`, etc.

For each NFR found, extract:
```
NFR-ID: [e.g. NFR-001]
Category: [Performance / Security / Scalability / Resilience / Availability / Maintainability / Compliance / Cost / Other]
Description: [the full NFR statement]
Threshold/Target: [the measurable target, e.g. "p95 < 200ms", "99.9% uptime", "GDPR compliant"]
```

If no NFR-NNN entries are found:
- If `--auto-chain`: log `{ "status": "skipped-condition-not-met", "summary": "No NFR-NNN entries in prd.md" }` and output `⏭️ nfr-analysis — skipped: no NFR entries found in prd.md`
- If interactive: inform the user and ask if they want to proceed anyway, scanning for any non-functional language (e.g. "must be fast", "must be secure").

---

## Step 2: Decompose Each NFR

For each NFR, apply the decomposition rules by category:

### Performance NFRs
Architectural implications:
- Response time targets → identify cache candidates (what data is read frequently and rarely changes?)
- Throughput targets → connection pool sizing, async processing boundaries, pagination strategy
- Query performance → index strategy (flag specific queries that will need indexes), query result caching
- Hot path optimisation → identify the critical path, consider CQRS if read/write patterns diverge significantly

Patterns to consider: Cache-Aside, Read-Through, CQRS, Connection Pooling, Async offloading, CDN for static assets

### Security NFRs
Architectural implications:
- Authentication requirement → choose auth pattern (JWT+OIDC / API Keys / mTLS / Session)
- Data classification → encryption at rest (field-level vs full disk), encryption in transit (TLS 1.3)
- Input validation → validation layer placement (delivery layer, never domain)
- Compliance (GDPR/HIPAA/PCI) → data residency, right-to-erasure design, tokenisation, audit logging

Patterns to consider: Token-based Auth, RBAC/ABAC, Vault for secrets, Field-level encryption, Audit Log pattern

### Scalability NFRs
Architectural implications:
- Horizontal scaling requirement → stateless service design (no local state, sessions externalised)
- Database scaling → read replicas, connection pooling, query optimization, sharding strategy
- Storage scaling → blob storage for large objects (not DB), partitioning strategy
- Event-driven scaling → queue-based load levelling, consumer group scaling

Patterns to consider: Stateless Design, Database Read Replicas, CQRS, Queue-Based Load Levelling, Sharding

### Resilience NFRs
Architectural implications:
- Transient failure handling → retry with exponential backoff + jitter for all external calls
- Cascading failure prevention → circuit breaker on every external dependency
- Resource isolation → bulkhead pattern (separate thread pools / connection pools per dependency)
- Data consistency under failure → outbox pattern for event publishing, saga for distributed transactions

Patterns to consider: Circuit Breaker, Retry+Backoff, Bulkhead, Outbox, Saga, Timeout

### Availability NFRs
Architectural implications:
- Uptime SLO → calculate maximum allowed downtime per month (99.9% = 43.8 min/month)
- Deployment strategy → blue/green or canary (avoid downtime during deploys)
- Health checks → liveness and readiness probes for every service
- Database availability → replication, failover time, connection retry logic
- RTO/RPO → backup frequency, restore procedure, data replication strategy

Patterns to consider: Blue/Green Deploy, Canary Release, Health Check, Active-Passive Replication

### Maintainability NFRs
Architectural implications:
- Code quality → test coverage threshold, static analysis gates in CI
- Documentation → ADR discipline, API documentation generation
- Observability → structured logging, distributed tracing, metrics — needed to diagnose production issues

Patterns: Clean Architecture (dependency rule), Dependency Injection, Repository Pattern

### Compliance NFRs (GDPR / HIPAA / PCI-DSS / SOC2)
Architectural implications:
- GDPR: PII data map, right-to-erasure (soft delete with TTL or hard delete cascade), data residency (region lock), consent management
- HIPAA: PHI encryption at rest and in transit, audit logging for every PHI access, BAA with cloud providers
- PCI-DSS: no card data in logs, tokenisation for card numbers, network segmentation, annual penetration test
- SOC2: access controls, audit logs, vulnerability scanning, change management process

---

## Step 3: Build NFR Analysis Table

For each NFR, produce a structured analysis entry:

```
NFR-ID: [identifier]
Category: [category]
Threshold: [measurable target]
Architectural Pattern Required: [specific pattern(s) from Step 2]
ADR Needed: [yes/no — and if yes: ADR title suggestion]
Test Layer: [Unit / Integration / Contract / Performance / Security / E2E — which layer validates this NFR]
SLO Candidate: [yes/no — and if yes: proposed SLO metric and target]
Design Phase Impact: [High / Medium / Low — how much this NFR will constrain architecture choices]
```

---

## Step 4: ADR Flagging

Identify which NFRs require dedicated ADRs in the design phase. An ADR is needed when:
- The NFR drives a specific technology choice (e.g., "must support 10k concurrent users" → requires a specific database or caching layer decision)
- The NFR creates a cross-cutting concern affecting multiple components (e.g., auth strategy)
- The NFR restricts design options in a non-obvious way (e.g., compliance requirement forcing data residency)

For each NFR needing an ADR, prepare a brief ADR prompt:
```
ADR for NFR-NNN: "[suggested ADR title]"
Driving constraint: [the NFR threshold]
Decision needed: [what architectural choice must be made]
Consider during design phase: [specific question to answer]
```

---

## Step 5: Write Artifact

Write `$PHASE_ARTIFACTS/nfr-analysis.md`:

```markdown
# NFR Analysis
*Generated: [date] | Branch: [branch]*

## NFRs Analysed: [N]

## NFR Decomposition Table

| NFR-ID | Category | Threshold | Architectural Pattern Required | ADR Needed | Test Layer | SLO Candidate |
|--------|----------|-----------|-------------------------------|------------|------------|---------------|
[one row per NFR]

## Detailed Analysis

### [NFR-001: title]
**Threshold:** [target]
**Architectural implications:**
[bullet list from Step 2 decomposition]
**Patterns required:** [list]
**ADR:** [yes — "[suggested title]" / no]
**Test layer:** [which layer + specific test approach]
**SLO:** [yes — "[metric]: [target]" / no]

[repeat for each NFR]

## ADRs Required in Design Phase

| NFR-ID | Suggested ADR Title | Driving Constraint | Decision Needed |
|--------|--------------------|--------------------|-----------------|
[only rows where ADR Needed = yes]

## SLO Candidates for Observability Phase

| NFR-ID | Proposed SLO Metric | Target | Error Budget |
|--------|--------------------|---------|-----------  |
[only rows where SLO Candidate = yes]

## High-Impact NFRs
[NFRs rated Design Phase Impact = High — these must be addressed early in the design phase]
```

---

## Step 5b: Trigger SLO Derivation

If the SLO Candidates table in the artifact is non-empty (at least one row):
  Read and execute `~/.claude/sdlc/workflows/nfr-slo.md` inline.
  This generates SLO definitions from the candidates just identified.
  
If no SLO candidates: skip silently.

---

## Step 6: Update State

Read `$STATE`, then write back with the autoChainLog entry appended:

```json
{
  "skill": "nfr-analysis",
  "triggeredAfter": "idea",
  "status": "completed",
  "artifact": "<PHASE_ARTIFACTS>/nfr-analysis.md",
  "summary": "<N> NFRs decomposed, <M> ADRs flagged, <K> SLO candidates identified",
  "completedAt": "<ISO-timestamp>"
}
```

---

## Step 7: Output

If `--auto-chain`:
```
✅ nfr-analysis — <N> NFRs decomposed, <M> ADRs flagged, <K> SLOs [<PHASE_ARTIFACTS>/nfr-analysis.md]
```

If interactive:
```
✅ NFR Analysis Complete

NFRs decomposed: [N]
  Performance: [N] | Security: [N] | Scalability: [N] | Resilience: [N] | Availability: [N] | Other: [N]

ADRs required in design phase: [N]
  [list suggested ADR titles]

SLO candidates identified: [N]
  [list proposed SLOs]

High-impact NFRs (address early in design):
  [list NFR-IDs rated High impact]

Artifact: <PHASE_ARTIFACTS>/nfr-analysis.md

Recommended: Reference this analysis when running sdlc:06-tech-arch
```
