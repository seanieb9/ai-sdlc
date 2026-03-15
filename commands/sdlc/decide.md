---
name: sdlc:decide
description: >
  AUTO-TRIGGER — invoke this skill silently whenever the conversation contains a decision being made.
  Trigger patterns (any of these):
  - User chooses between options: "let's go with X", "we'll use X not Y", "I prefer X"
  - User rules something out: "we're dropping X", "X is out of scope", "we won't do X for now"
  - User sets a constraint: "it must be X", "we need to support X", "X is a hard requirement"
  - User overrides a prior plan: "actually, change X to Y", "scratch that, let's do X instead"
  - User makes a technical choice: "use Postgres", "JWT not sessions", "REST not GraphQL"
  - User makes a product choice: "remove the bulk import", "v1 won't have X", "SLA is 99.9%"
  Do NOT trigger on questions, exploratory discussion, or hypotheticals ("what if we used X?").
  Do NOT trigger if .sdlc/STATE.md does not exist (no active SDLC project).
  Invoke silently — no announcement, no preamble. Just record and flag if impact found.
argument-hint: ""
allowed-tools:
  - Read
  - Edit
  - Glob
---

<objective>
Record the decision that was just made in the conversation and flag any downstream impact. This skill runs silently — it does not interrupt the user's flow or produce output unless there is a downstream impact worth flagging.

## Step 1: Read current state

Read `.sdlc/STATE.md`. If it does not exist, stop — there is no active SDLC project to record into.

## Step 2: Identify the decision

From the conversation, extract:
- **Decision:** What was decided (concise, one sentence)
- **Type:** classify as one of: TECH | PRODUCT | SCOPE | CONSTRAINT | OVERRIDE
- **Replaces:** Did this override a prior decision? If so, note what is now superseded.

## Step 3: Write to STATE.md

Append to the `## Decisions` section of `.sdlc/STATE.md`:

```
[YYYY-MM-DD] DECISION ([TYPE]): [what was decided] BECAUSE: [reason if stated, otherwise omit]
```

If this overrides a prior decision, mark the old one superseded:
```
[YYYY-MM-DD] DECISION (TECH): Use Postgres for primary storage BECAUSE: team familiarity
[YYYY-MM-DD] SUPERSEDED by above: Use MongoDB for primary storage
```

## Step 4: Assess downstream impact

Based on decision type, check which phases may be affected:

| Decision type | Phases to check |
|--------------|----------------|
| TECH | Data model (entity/field implications), Tech architecture (ADR needed), Plan (task changes), Code (implementation changes) |
| PRODUCT | Product spec (requirement update needed), Test cases (scenario update needed), Customer journey (flow changes) |
| SCOPE | Product spec (Won't list update), Test cases (remove covered scenarios), Plan (remove tasks) |
| CONSTRAINT | NFRs in product spec (numeric threshold changed), SLOs (if availability/perf), Observability |
| OVERRIDE | All phases touched by the original decision |

Check which of those phase documents currently exist (glob for them). For each that exists, assess whether the decision creates a stale or inconsistent state.

## Step 5: Output (only if impact found)

If no downstream impact: record silently, produce no output.

If downstream impact exists, append a single compact notice at the end of your current response:

```
> Decision recorded: [one-line summary]
> Impact: [Phase N] [doc name] may need updating — [one sentence why]
```

Maximum 3 impact lines. Do not interrupt the conversation with a full report. Flag only — do not auto-update other documents unless the user asks.
</objective>
