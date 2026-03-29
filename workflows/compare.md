# Compare Workflow

Generate 2–3 concrete design alternatives for a decision, analyze against existing architecture and NFR constraints, build a trade-off matrix, make a recommendation, and produce a formal Architecture Decision Record (ADR).

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

Create the output directory:
```bash
mkdir -p "$ARTIFACTS/design"
```

If $ARGUMENTS is empty: output "Please provide a design decision to compare. Example: /sdlc:compare 'message queue vs direct HTTP calls for async processing'" and STOP.

---

## Step 1: Load Design Context

Read the following files in parallel (if they exist):
- `$ARTIFACTS/design/tech-architecture.md`
- `$ARTIFACTS/data-model/data-model.md`
- `$ARTIFACTS/idea/prd.md`
- `$ARTIFACTS/design/solution-design.md`

Extract key context:
- **Existing architectural decisions:** read any ADRs already present in solution-design.md or `$ARTIFACTS/design/adr-*.md`. Note decision numbers to determine next DEC-NNN ID.
- **NFR constraints:** extract all NFR-IDs from prd.md with their numeric thresholds. These are hard constraints the alternatives must respect.
- **Tech stack:** extract the named technologies (language, framework, database, message broker, cloud provider) from tech-architecture.md.
- **Scale targets:** extract throughput, latency, and availability NFRs specifically.

**Determine next ADR number:**
```bash
ls "$ARTIFACTS/design/adr-"*.md 2>/dev/null | wc -l
```
Next ADR number = count + 1 (e.g., ADR-001). Also read state.json `decisions` array for next DEC-NNN number.

---

## Step 2: Understand the Decision

**Parse the decision from $ARGUMENTS.** Extract:
- What is the subject being decided? (e.g., "message queue technology", "caching strategy", "API gateway approach")
- What is the context/trigger? (why is this decision needed now?)
- What are the options already in the user's mind (if named in $ARGUMENTS)?

**If the decision is ambiguous:** use AskUserQuestion:
"To generate the best alternatives for '<decision>', I need a bit more context:
1. What is driving this decision? (performance problem, new requirement, architectural constraint?)
2. Are there options you've already considered or want to make sure are included?
3. Are there options that are already ruled out (and why)?"

---

## Step 3: Generate 2–3 Alternatives

Based on the decision subject, tech stack, and NFR constraints, generate 2–3 concrete, realistic alternatives.

**Rules for alternatives:**
- Each alternative must be specific and named (not "Option A: use a queue" but "Option 1: AWS SQS with FIFO queue and Lambda consumer")
- Each must be genuinely different in approach — not minor variations of the same approach
- Each must be plausible given the existing tech stack (don't propose Kafka if the team is on SQLite and has no streaming infrastructure)
- At least one alternative should be the "simplest viable" approach
- At least one should be the "industry standard / widely-used" approach

For each alternative, define:
1. **Name:** short descriptive label
2. **Description:** 2–4 sentences explaining the approach
3. **How it works:** concrete technical description (what components, what flow, what libraries/services)
4. **Key assumptions:** what must be true for this option to work

---

## Step 4: Analyze Each Alternative

For each alternative, score or assess the following dimensions:

### Implementation Complexity
- **Low:** Can be implemented with existing skills and tools, < 1 week
- **Medium:** Requires learning or setup, 1–3 weeks
- **High:** Significant new infrastructure or expertise required, > 3 weeks

### Alignment with Existing Architecture
Score 1–5:
- 5: Fits perfectly, reuses existing patterns and infrastructure
- 3: Compatible but requires new patterns or services
- 1: Major deviation from existing architecture, introduces significant new complexity

### NFR Impact
For each NFR with a numeric threshold from the project:
- Will this alternative meet the threshold? (Yes / Marginal / No)
- Specific analysis for: latency, throughput, availability, security

### Operational Complexity
- **Low:** Managed service or well-understood pattern, minimal ongoing ops burden
- **Medium:** Some monitoring and maintenance required
- **High:** Requires dedicated ops expertise or significant ongoing maintenance

### Migration / Rollback Feasibility
- **Easy:** Can be deployed incrementally, can be rolled back without data loss
- **Medium:** Requires coordinated deployment, rollback possible but complex
- **Hard:** Big-bang deployment required, rollback may require data migration

### Cost Profile
- Relative cost estimate (Low / Medium / High relative to other alternatives)
- Key cost drivers

---

## Step 5: Build Trade-Off Matrix

Compose a Markdown comparison table:

```markdown
## Trade-Off Matrix

| Dimension | <Alt 1 Name> | <Alt 2 Name> | <Alt 3 Name (if present)> |
|-----------|-------------|-------------|--------------------------|
| Implementation Complexity | Low/Med/High | | |
| Arch Alignment (1–5) | | | |
| Latency (NFR-NNN: <Xms) | Meets / Marginal / Fails | | |
| Throughput (NFR-NNN: <X rps) | | | |
| Availability (NFR-NNN: XX.X%) | | | |
| Operational Complexity | | | |
| Migration Feasibility | | | |
| Cost Profile | | | |
| **Overall Score** | **/40** | **/40** | **/40** |
```

**Scoring:** Award 1–5 points per dimension (5 = best). Sum for an overall score. The score is advisory — recommendation may differ if one alternative fails a hard NFR constraint.

---

## Step 6: Make a Recommendation

State the recommended alternative clearly:

```markdown
## Recommendation

**Recommended:** <Alternative Name>

**Rationale:**
<3–5 sentences explaining why this alternative is the best choice given the project's specific context, constraints, and NFRs. Reference specific NFR-IDs and their thresholds. Explain trade-offs accepted.>

**Conditions:** <Any conditions under which the recommendation changes — e.g., "If traffic exceeds X, reconsider Alt 2", "If budget constraint is removed, Alt 3 becomes viable">

**Rejected alternatives:**
- <Alt N>: <1–2 sentence reason for rejection>

**Review trigger:** <What change in requirements, scale, or technology landscape would cause this decision to be revisited?>
```

---

## Step 7: Generate ADR Slug

Create a URL-friendly slug from the decision subject:
- Lowercase, hyphens instead of spaces
- Remove articles (a, an, the)
- Max 40 characters
- Example: "message queue vs direct HTTP" → `message-queue-vs-direct-http`

ADR filename: `adr-NNN-<slug>.md` (e.g., `adr-001-message-queue-vs-direct-http.md`)

---

## Step 8: Write ADR

Write `$ARTIFACTS/design/adr-NNN-<slug>.md`:

```markdown
# ADR-NNN: <Decision Subject>
*Date: <ISO date> | Branch: <$BRANCH> | Status: Accepted*

## Context
<What is the issue we're addressing? What forces are at play — technical, business, team capacity? 2–4 sentences.>

## Alternatives Considered

### Option 1: <Alt 1 Name>
<Description and key characteristics>

**Pros:** <bulleted list>
**Cons:** <bulleted list>

### Option 2: <Alt 2 Name>
<Description and key characteristics>

**Pros:** <bulleted list>
**Cons:** <bulleted list>

### Option 3: <Alt 3 Name> (if present)
<Description and key characteristics>

**Pros:** <bulleted list>
**Cons:** <bulleted list>

## Trade-Off Matrix
<table from Step 5>

## Decision
**We will use: <Alt Name>**

## Rationale
<Rationale from Step 6>

## Consequences

### Positive
- <outcome>

### Negative / Trade-offs Accepted
- <trade-off accepted and why>

### Risks
- <risk> → Mitigation: <how it will be managed>

## Review Trigger
<What change would cause us to revisit this decision?>

## References
- Project NFRs: $ARTIFACTS/idea/prd.md
- Tech Architecture: $ARTIFACTS/design/tech-architecture.md
```

---

## Step 9: Update state.json

Read current `decisions` array from state.json. Append:

```json
{
  "id": "DEC-NNN",
  "adrFile": "adr-NNN-<slug>.md",
  "subject": "<decision subject>",
  "decision": "<alt name chosen>",
  "decidedAt": "<ISO timestamp>",
  "reviewTrigger": "<review trigger text>"
}
```

Also update `phases.design.artifacts` array to include the new ADR file path.
Update `updatedAt`.

---

## Step 10: Final Output

```
COMPARE Complete: <decision subject>

ADR: ADR-NNN — <decision subject>
Decision: <chosen alternative>
Alternatives evaluated: <count>

Artifact: $ARTIFACTS/design/adr-NNN-<slug>.md
Decision ID: DEC-NNN added to state.json

Next:
  Share the ADR with your team for async review.
  Run /sdlc:tech-arch to incorporate this decision into the full architecture.
  Set a calendar reminder for the review trigger: <trigger>
```
