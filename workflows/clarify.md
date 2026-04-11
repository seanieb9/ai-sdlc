# Clarify Workflow

Structured requirements elicitation session. Asks targeted questions across functional, edge-case, NFR, and scope dimensions. Assigns REQ-NNN and NFR-NNN IDs. Produces a clarify-brief.md artifact ready to feed into the product spec phase (tell Claude to proceed).

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

Create the output directory:
```bash
mkdir -p "$ARTIFACTS/clarify"
```

---

## Step 1: Load Existing ID Sequences

Read the following files in parallel (if they exist):
- `$ARTIFACTS/idea/prd.md`
- `$ARTIFACTS/clarify/clarify-brief.md`

**Determine starting ID numbers:**
- Scan existing prd.md and clarify-brief.md for the highest REQ-NNN number. Next REQ ID = highest + 1 (or REQ-001 if none exist).
- Scan for the highest NFR-NNN number. Next NFR ID = highest + 1 (or NFR-001 if none exist).
- Scan for the highest BR-NNN number. Next BR ID = highest + 1 (or BR-001 if none exist).

Record: `$NEXT_REQ`, `$NEXT_NFR`, `$NEXT_BR`.

---

## Step 2: Opening Context

Output to the user:

```
CLARIFY: <feature or problem statement from $ARGUMENTS>

I'll ask structured questions to capture requirements before writing the product spec.
This session will produce REQ-IDs, NFR-IDs, and a clarify-brief.md artifact.

There are 4 question groups. Answer each as thoroughly as you can.
```

If $ARGUMENTS is empty: ask the user to provide the feature or problem statement first before proceeding.

---

## Step 3: Functional Requirements Elicitation

Use AskUserQuestion with the following questions as a single grouped prompt:

```
GROUP 1: Functional Requirements

Please answer each of the following:

1. What are the primary actions the system must support for this feature?
   (List each action on its own line, e.g., "User can create a payment", "Admin can refund a payment")

2. Who performs each action? (User roles, system actors, external services)

3. What is the success condition for each action?
   (What does "done" look like from the actor's perspective?)

4. Are there any actions that must happen automatically (without user trigger)?
   (e.g., "System sends confirmation email after payment")

5. Are there any ordering or sequencing constraints?
   (e.g., "Step B cannot happen before step A completes")
```

Record the user's answers verbatim. Do not parse yet — continue to next question group.

---

## Step 4: Edge Cases and Business Rules

Use AskUserQuestion:

```
GROUP 2: Edge Cases and Business Rules

1. What happens when input is invalid or missing?
   (e.g., required fields empty, wrong data format)

2. What happens when a dependency is unavailable?
   (e.g., payment gateway is down, third-party API times out)

3. What are the limits and maximums?
   (e.g., max file size, max items per page, rate limits)

4. Are there any business rules that must always be enforced?
   (e.g., "Cannot refund more than the original amount", "User must be verified before posting")

5. What happens when a business rule is violated?
   (Error message? Silent rejection? Redirect?)

6. Are there any time-based rules?
   (e.g., "Sessions expire after 30 minutes", "Offers valid for 24 hours only")
```

Record answers verbatim.

---

## Step 5: Non-Functional Requirements

Use AskUserQuestion:

```
GROUP 3: Non-Functional Requirements

For each applicable dimension, provide a specific numeric target:

1. Performance: What response time is acceptable for the primary actions?
   (e.g., "API must respond in < 200ms at p95 under 100 concurrent users")

2. Throughput: What volume must the system handle?
   (e.g., "Must process 500 transactions per minute")

3. Availability: What uptime is required?
   (e.g., "99.9% monthly uptime", "Max 4 hours planned downtime per year")

4. Security: Are there specific security requirements?
   (e.g., "PCI-DSS compliance", "All PII must be encrypted at rest", "MFA required for admin actions")

5. Compliance: Are there regulatory requirements?
   (e.g., GDPR, HIPAA, SOC 2, ISO 27001)

6. Scalability: Is there a growth target to design for?
   (e.g., "Must scale to 10x current volume within 18 months")

7. Data retention: How long must data be kept?
   (e.g., "Transaction records retained for 7 years", "Session data purged after 90 days")

Skip any that don't apply.
```

Record answers verbatim.

---

## Step 6: Scope and Deferred Items

Use AskUserQuestion:

```
GROUP 4: Scope Boundaries

1. What is explicitly OUT OF SCOPE for this feature or version?
   (List items that have been discussed but deliberately excluded)

2. What is deferred to a future version?
   (List capabilities that are planned but not in this iteration)

3. Are there any open questions or decisions not yet made?
   (e.g., "Payment provider TBD", "Localization strategy to be decided")

4. Are there any assumptions this feature makes?
   (e.g., "Assumes users are authenticated", "Assumes PostgreSQL as the database")

5. Are there any known constraints?
   (e.g., "Must integrate with existing legacy auth system", "Cannot change the existing data schema")
```

Record answers verbatim.

---

## Step 7: Assign IDs and Structure Requirements

Now process all answers from Steps 3–6 to extract and assign IDs.

**Functional Requirements (REQ-NNN):**
For each distinct action or behavior identified in Step 3, assign a REQ-ID:

| ID | Actor | Action | Success Condition | Priority |
|----|-------|--------|------------------|----------|
| REQ-NNN | <who> | <what> | <outcome> | Must Have / Should Have / Could Have |

Use MoSCoW prioritization. "Must Have" for core actions, "Should Have" for important but not blocking, "Could Have" for nice-to-have.

**Business Rules (BR-NNN):**
For each rule, constraint, or enforcement identified in Step 4:

| ID | Rule Statement | Violation Response | Source |
|----|---------------|-------------------|--------|
| BR-NNN | <rule> | <what happens on violation> | <edge case Q#> |

**Non-Functional Requirements (NFR-NNN):**
For each NFR from Step 5, assign an NFR-ID with a mandatory numeric threshold:

| ID | Category | Requirement | Numeric Threshold | Measurement Method |
|----|----------|-------------|------------------|-------------------|
| NFR-NNN | Performance | API response time | < 200ms p95 | Load test at 100 RPS |
| NFR-NNN | Availability | Uptime | 99.9% monthly | Synthetic monitoring |

**Rules for NFRs:**
- Every NFR must have a numeric threshold (no "fast", "scalable", or "high availability" without numbers)
- Every NFR must have a measurement method (how will we know if this is met?)

---

## Step 8: Open Questions Log

From Step 6 answers, extract all open questions and unknowns:

| # | Question | Owner | Due By | Blocks |
|---|---------|-------|--------|--------|
| Q-001 | <question> | <person or "TBD"> | <date or "before build"> | <REQ-ID or "—"> |

---

## Step 9: Write clarify-brief.md

Write `$ARTIFACTS/clarify/clarify-brief.md`:

```markdown
# Requirements Brief: <feature/problem statement>
*Elicited: <ISO date> | Branch: <$BRANCH>*

## Summary
<2–3 sentence overview of what is being built and why>

## Functional Requirements

| ID | Actor | Action | Success Condition | Priority |
|----|-------|--------|------------------|----------|
<REQ table rows>

## Business Rules

| ID | Rule Statement | Violation Response |
|----|---------------|-------------------|
<BR table rows>

## Non-Functional Requirements

| ID | Category | Requirement | Numeric Threshold | Measurement Method |
|----|----------|-------------|------------------|--------------------|
<NFR table rows>

## Assumptions
<list from Step 6 Q4>

## Known Constraints
<list from Step 6 Q5>

## Out of Scope
<list from Step 6 Q1>

## Deferred to Future Version
<list from Step 6 Q2>

## Open Questions
| # | Question | Owner | Blocks |
|---|---------|-------|--------|
<Q table rows>
```

---

## Step 10: Update state.json

Update `$STATE`:
- Set `phases.clarify.status = "completed"`
- Set `phases.clarify.completedAt = "<ISO timestamp>"`
- Add artifact: `$ARTIFACTS/clarify/clarify-brief.md`
- Update `updatedAt`

---

## Step 11: Final Output

```
CLARIFY Complete: <feature/problem statement>

Requirements captured:
  REQ-IDs: <count> (<REQ-NNN to REQ-NNN>)
  BR-IDs:  <count> (<BR-NNN to BR-NNN>)
  NFR-IDs: <count> (<NFR-NNN to NFR-NNN>)
  Open questions: <count>

Artifact: $ARTIFACTS/clarify/clarify-brief.md

Next: Run the product spec phase (tell Claude to proceed) to turn this brief into a full product spec.
     The idea phase will read clarify-brief.md automatically.
```
