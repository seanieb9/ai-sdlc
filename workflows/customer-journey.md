# Customer Journey Workflow

Map who uses the system, why they use it, and exactly how. These journeys are the basis for E2E test design and business process documentation.

## Step 1: Pre-Flight

Read:
- `docs/product/PRODUCT_SPEC.md` — personas section, requirements
- `docs/research/GAP_ANALYSIS.md` — customer pain points, frustrations
- `docs/product/CUSTOMER_JOURNEY.md` — existing journeys (if any — update, don't replace)
- `docs/product/PERSONAS.md` — if exists (from Phase 3b); personas defined here take precedence over inline definitions
- `.sdlc/STATE.md` — project context

**PERSONAS.md gate check:**
If `docs/product/PERSONAS.md` does NOT exist (Phase 3b was skipped):
- Define personas inline during Step 2 as usual
- After Step 2 completes, write a minimal `docs/product/PERSONAS.md` from those definitions
- This ensures downstream phases (data model, test cases, tech arch) always have a PERSONAS.md to reference
- Mark `docs/product/PERSONAS.md` in STATE.md document index as created

## Step 2: Define Personas

For each user type identified in PRODUCT_SPEC.md:

```markdown
### Persona: [Name]
*Role: [job title or user type]*

**Background**
[2-3 sentences: who they are, their context, their goals]

**Goals**
- Primary: [what they most want to achieve]
- Secondary: [other goals]

**Frustrations**
- [Pain point from GAP_ANALYSIS.md]
- [Another frustration]

**Tech Comfort**
[Low | Medium | High] — affects how much hand-holding is needed

**How They Measure Success**
[What does a great experience look like for them specifically]
```

## Step 3: Map Journeys

For each persona + key use case combination:

```markdown
### Journey: [Persona] — [Goal/Scenario Name]

**Trigger:** [What causes the user to start this journey]
**Goal:** [What success looks like]
**Pre-conditions:** [What must be true before they start]

#### Steps

| Step | User Action | System Response | Emotional State | Notes |
|------|-------------|-----------------|-----------------|-------|
| 1 | [What they do] | [What happens] | 😐 Neutral | |
| 2 | [Next action] | [Response] | 🙂 Positive | |
| 3 | [Action] | [Response] | 😊 Satisfied | |

**Outcome:** [What the user has achieved]
**Success Indicators:** [Observable proof of success]

#### Failure Path: [Common failure scenario]
| Step | Failure Trigger | System Response | User Impact | Recovery |
|------|----------------|-----------------|-------------|----------|
| 2 | [What goes wrong] | [Error state] | [Frustration] | [How to recover] |
```

Required journeys for every feature:
1. Happy path (primary success scenario)
2. Primary failure path (most common failure)
3. Edge case path (boundary condition)

## Step 4: Business Process Integration

Map how user journeys connect to back-office processes:

```markdown
### Business Process: [Name]

**Initiating Journey:** [Which user journey triggers this]

**Process Steps:**
1. [Automated step]
2. [Human review step — if applicable]
3. [System notification]
4. [State change]

**Actors:** User | [Service] | [External System]
**Process Owner:** [who is responsible for this working]
**SLA:** [how long should this take]
**Failure handling:** [what happens if the process fails]
```

## Step 5: Screen/Interaction Flows

For each significant UI interaction, define the step-by-step flow:

```markdown
### Flow: [Name]
*Related Journey: [journey name]*

Step 1: [Screen/State] → [User sees: X] → [User can do: Y]
Step 2: [Next Screen] → [System validates: Z] → [If valid: proceed | If invalid: show error EH-NNN]
Step 3: [Confirmation] → [System performs: action] → [User sees: success/failure]

Validation rules applied: BR-[NNN], BR-[NNN]
Error states: EH-[NNN] (invalid input), EH-[NNN] (system error)
```

## Step 6: Write Output Document

**Update docs/product/CUSTOMER_JOURNEY.md:**

```markdown
# Customer Journeys
*Last Updated: [date]*

## Personas
[All persona definitions]

## Journeys

### [Persona Name] Journeys
[Journey maps]

## Business Processes
[Process flows]

## Interaction Flows
[Screen flows]

## Journey Coverage Matrix
| Persona | Journey | Happy Path | Failure Path | E2E Test |
|---------|---------|------------|--------------|----------|
| [name] | [journey] | ✅ | ✅ | TC-NNN |
```

## Step 7: Update State

Mark Phase 4 (Customer Journey) complete.

Output:
```
✅ Customer Journeys Complete

Personas: [N]
Journeys mapped: [N]
Business processes: [N]

File: docs/product/CUSTOMER_JOURNEY.md

Recommended Next: /sdlc:04b-business-process (if any business processes were identified)
  → Then: /sdlc:05-data-model ⚠️ (Critical Gate)
```
