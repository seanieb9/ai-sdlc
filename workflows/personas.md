# Personas Workflow

Build evidence-grounded personas using Jobs-to-be-Done, empathy maps, and anti-personas. These feed every downstream phase — data model, product spec, test cases, and journeys.

## Step 0: Workspace Resolution
Run this bash to determine workspace paths:
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "default")
BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g' | sed 's|[^a-z0-9-]|-|g' | sed 's|-\+|-|g' | sed 's|^-||;s|-$||')
[ -z "$BRANCH" ] && BRANCH="default"
WORKSPACE=".claude/ai-sdlc/workflows/$BRANCH"
STATE="$WORKSPACE/state.json"
ARTIFACTS="$WORKSPACE/artifacts"
mkdir -p "$WORKSPACE/artifacts"
```
Then use $WORKSPACE, $STATE, $ARTIFACTS throughout.

## Step 1: Pre-Flight — Gather Evidence

Read ALL of the following (personas without evidence are fiction):
- `$ARTIFACTS/research/voc.md` — primary customer evidence ← most important input
- `$ARTIFACTS/research/gap-analysis.md` — customer pain points and gaps
- `$ARTIFACTS/research/research.md` — market segments and competitive landscape
- `$ARTIFACTS/research/synthesis.md` — synthesized findings (if exists)
- `$ARTIFACTS/personas/personas.md` — existing personas (update, don't replace)
- `$STATE` — project context, constraints (read and parse JSON)

Assess evidence quality:
- voc.md exists with real data → STRONG (proceed)
- Only gap-analysis.md (inferred from research) → MODERATE (note evidence is secondary)
- No research at all → WEAK (run the research phase (tell Claude to proceed) and the voc workflow first)

Warn the user if evidence is weak. Proceed with explicit caveat.

## Step 2: Identify Customer Segments

Before defining personas, identify distinct customer segments — groups with meaningfully different needs, behaviors, or contexts.

Segment criteria:
- Different primary jobs-to-be-done
- Different contexts or environments
- Different buying behaviors or decision criteria
- Different levels of sophistication/expertise

```
Segment Analysis:

SEGMENT A: [Name]
  Size: [estimated relative size — Large/Medium/Small]
  Distinguishing characteristic: [what makes them distinct]
  Evidence: [VOC themes, RESEARCH data that identifies this segment]
  Strategic priority: PRIMARY | SECONDARY | TERTIARY

SEGMENT B: [Name]
  ...
```

Rules:
- Maximum 4 segments before persona work
- Each segment needs at least one persona
- Focus persona depth on PRIMARY and SECONDARY segments

## Step 3: Define Personas (one per primary segment)

For each primary/secondary segment, build a full persona:

### 3a: Persona Narrative

Write a grounded day-in-the-life narrative (NOT a list of demographics):

```
[Persona Name] is a [role] at [type of company].

[2-3 sentences: their work context, what they're responsible for,
what a typical day looks like related to the problem domain]

When it comes to [product area], [Name]'s primary challenge is [core pain].
They currently [current workaround], which [why it's inadequate].

[Name] measures success by [how they are evaluated]. When [product area]
goes wrong, [the consequences for them personally].
```

Ground every sentence in VOC evidence. If you can't cite a data source, flag it as an assumption.

### 3b: Jobs-to-be-Done

```
PERSONA: [Name]

PRIMARY FUNCTIONAL JOB:
  "When I [trigger situation],
   I want to [action/motivation],
   So I can [desired outcome]"
  Evidence: VOC-[theme], [N] customers

SECONDARY FUNCTIONAL JOBS:
  - [Job 2] (evidence: [source])
  - [Job 3] (evidence: [source])

EMOTIONAL JOB:
  "I want to feel [positive emotion] / avoid feeling [negative emotion]"
  Context: [when/why this emotional job matters]
  Evidence: [VOC quote or theme]

SOCIAL JOB:
  "I want to be seen as [perception] by [audience]"
  Evidence: [source]
```

### 3c: Gains and Pains (Stratified)

```
GAINS (what they want MORE of):
  Essential gains: [outcomes they expect — table stakes]
  Expected gains: [outcomes they hope for]
  Desired gains: [outcomes they'd love but don't expect]
  Unexpected gains: [outcomes that would delight them]

PAINS (what they want to AVOID):
  Blockers: [things that stop them doing the job at all]
    - [Pain] | Severity: 5 | Evidence: "[quote]" — [source]
  Frustrations: [things that annoy or slow them down]
    - [Pain] | Severity: 3 | Evidence: "[quote]" — [source]
  Risks: [potential negative outcomes they fear]
    - [Risk] | Severity: [N] | Evidence: [source]
```

### 3d: Empathy Map

```
EMPATHY MAP: [Persona Name]

THINK & FEEL (inner world — what really matters to them):
  - [What occupies their mind about this domain]
  - [Their main worries and aspirations]
  Evidence: [VOC themes, interview quotes]

SAY & DO (observable behavior — what they say and do in public):
  - [How they describe the problem to others]
  - [Their actual behavior/workarounds]
  Evidence: [VOC quotes, observation]

SEE (environment — what they observe around them):
  - [What solutions they see others using]
  - [What the market looks like from their seat]
  Evidence: [RESEARCH.md context]

HEAR (influences — what others tell them):
  - [What colleagues, managers, peers say]
  - [What industry voices say]
  Evidence: [RESEARCH.md, VOC context]

PAIN (frustrations in the current situation):
  [Top 3 pains from JTBD analysis above]

GAIN (aspirations and desires):
  [Top 3 gains from JTBD analysis above]
```

### 3e: Current Solutions and Their Gaps

```
CURRENT SOLUTIONS: [Persona Name]

Primary tool/approach: [what they use today]
  Why they chose it: [reasoning]
  What works: [genuine strengths]
  What doesn't work: [the gaps — this is the opportunity]
  Switching cost: [HIGH/MEDIUM/LOW] — [what would make them switch]

Workarounds they've built:
  - [Workaround 1] — because [root cause gap]
  - [Workaround 2] — because [root cause gap]
```

### 3f: Validation Criteria

```
VALIDATION: [Persona Name]

This persona is supported by:
  ☑ [N] customer interviews (VOC.md themes: [list])
  ☑ [N] support tickets referencing [themes]
  ☑ Market research segment: [RESEARCH.md reference]

Assumptions not yet validated:
  ⚠ [Assumption 1] — needs validation via [method]
  ⚠ [Assumption 2] — needs validation via [method]

Confidence level: HIGH / MEDIUM / LOW
Refresh trigger: Revisit if VOC data shows >20% of customers don't fit this pattern
```

## Step 4: Define Anti-Personas (MANDATORY)

For each primary persona, define who they are NOT:

```
ANTI-PERSONA: [Name — "The [descriptor]"]
  Relation to [Persona]: This is who [Persona Name] is NOT

  Who they are: [brief description]
  Why we won't build for them:
    - [Reason 1: misaligned with our core value prop]
    - [Reason 2: would distort the product in ways that hurt primary persona]
    - [Reason 3: unit economics / strategic fit]

  The trap: [How we might accidentally build for them — what to watch for]
  Gate question: "Does this feature serve [Anti-Persona] more than [Primary Persona]?" → if yes, reconsider
```

Anti-personas are used in ALL product decisions as a filter. If a feature primarily serves the anti-persona, it goes in the WON'T backlog.

## Step 5: Persona Hierarchy

Establish which persona drives decisions when personas conflict:

```
PERSONA HIERARCHY:
  1. PRIMARY: [Persona Name] — all core decisions optimize for them
  2. SECONDARY: [Persona Name] — considered when not in conflict with primary
  3. TERTIARY: [Persona Name] — nice to support but not at primary's expense

Conflict resolution rule:
  When [Primary Persona] and [Secondary Persona] have conflicting needs,
  we default to [Primary Persona] unless [specific exception condition].
```

## Step 6: Write Output Document

**Create/update $ARTIFACTS/personas/personas.md:**

```markdown
# Personas
*Last Updated: [date]*
*Evidence basis: [N VoC interviews, N tickets, N NPS] | Confidence: HIGH/MEDIUM/LOW*

## Segment Map
[Segment analysis table]

## Persona Hierarchy
[Priority order with conflict resolution rule]

## Personas

### [Persona Name] — [Role/Segment] (PRIMARY)

#### Narrative
[Day-in-the-life paragraph]

#### Jobs-to-be-Done
[JTBD definitions]

#### Gains and Pains
[Stratified table]

#### Empathy Map
[4-quadrant map]

#### Current Solutions and Gaps
[Current tool analysis]

#### Validation
[Evidence citations and assumptions]

---

### Anti-Personas

#### Anti-Persona: [Name]
[Anti-persona definition]

---

## Persona Usage Guide
*How to use these personas in downstream phases:*

- **Data model:** [Primary Persona]'s functional job defines the core entities
- **Product spec:** Requirements must serve [Primary Persona]'s top 3 pains
- **Test cases:** E2E tests simulate [Persona Name]'s primary journey
- **UX/flows:** Optimize for [Primary Persona]'s context: [tech level, environment]
- **Anti-persona gate:** Before adding scope, ask "does this serve [Anti-Persona]?"

## Change Log
| Date | Change | Evidence |
|------|--------|----------|
| [date] | Initial personas created | VOC.md v1 |
```

## Step 7: Update Downstream References

After creating/updating personas.md:

1. Update `$ARTIFACTS/journey/customer-journey.md` — reference personas.md instead of re-defining personas
2. Update `$ARTIFACTS/idea/prd.md` if it exists — persona section should reference personas.md
3. Update `$STATE` — mark Phase 3b complete, update document index

## Step 8: Update State

Mark Personas phase complete in $STATE.

Output:
```
✅ Personas Complete

Personas defined: [N] ([N] primary, [N] secondary)
Anti-personas defined: [N]
Evidence confidence: HIGH/MEDIUM/LOW
Unvalidated assumptions: [N] (flagged in doc)

Files:
• $ARTIFACTS/personas/personas.md

Recommended Next: the customer journey phase (tell Claude to proceed)
(Personas are now the authoritative input — customer-journey will reference them)
```
