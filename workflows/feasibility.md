# Feasibility Workflow

Phase 0 viability assessment. Before any research or design investment, determine whether the idea is worth pursuing. A clear verdict — GO, GO-WITH-CONDITIONS, or NO-GO — with explicit reasoning is the only acceptable output.

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

## Step 1: Pre-Flight Gate Check

Check that `.claude/ai-sdlc.config.yaml` exists. If missing: STOP and tell the user to initialize the project first (run `/sdlc:00-start`).

Read in parallel (if they exist):
- `$ARTIFACTS/research/research.md` — prior market/competitive research to incorporate
- `$STATE` — project context, any prior decisions

Note the idea from `$ARGUMENTS`. If not provided, check state.json `projectName` and `description`. If neither exists, ask the user: "What is the idea or feature you want to assess?"

**Execution mode:** INTERACTIVE — confirm direction before writing the document.

---

## Step 2: Market Viability Assessment

Analyze the following dimensions. Use prior research (if available) as primary source; otherwise reason from the description and known domain knowledge.

**Problem validation:**
- Is there a real, recurring problem being solved?
- Who experiences this problem? How frequently? How painfully?
- What do users do today without this solution? (workarounds, cost of status quo)

**Market sizing:**
- Total Addressable Market (TAM): entire market if 100% captured
- Serviceable Addressable Market (SAM): realistic portion given scope
- Serviceable Obtainable Market (SOM): realistic first-year target
- Growth trajectory: is this market growing, flat, or shrinking?

**Target users:**
- Primary persona(s)
- Early adopter profile (who would pay/use first)
- Champions vs. blockers (who helps adoption, who resists)

---

## Step 3: Technical Risk Assessment

Evaluate the hardest technical challenges:

**Difficulty tiers:**
- **Novel/unproven tech**: requires technology that does not yet exist or is experimental → HIGH risk
- **Hard but solved**: requires significant engineering but is well-understood in the industry → MEDIUM risk
- **Commodity**: standard CRUD, known patterns, widely available libraries → LOW risk

For each major technical component, assign a risk tier and note:
- The specific challenge
- Whether the team has prior experience
- Available alternatives or mitigations

**Build vs. Buy analysis:**
For each non-commodity component, assess:
- Build: full control, high cost, maintenance burden
- Buy/SaaS: faster, vendor dependency, cost at scale
- Open source: free, community risk, integration effort

State a clear recommendation (Build / Buy / Open Source) per component with rationale.

---

## Step 4: Competitive Landscape

Identify who else solves this problem today:

**Direct competitors:** products that solve the same problem for the same user
**Indirect competitors:** alternative approaches (manual processes, adjacent tools)
**Potential entrants:** who could easily enter this space (big platform players)

For each competitor:
- What they do well
- What they do poorly (the gap this idea could exploit)
- Their business model

**Moat analysis:**
What would prevent a competitor from copying this in 6 months?
Classify: network effects / proprietary data / switching costs / brand / patents / none

**Build vs. Buy verdict** (at the product level): Is there an existing solution that could be licensed or white-labeled rather than built?

---

## Step 5: Resource Assessment

**Scope estimate:**
- Small: 1-2 engineers, ≤4 weeks
- Medium: 2-4 engineers, 4-12 weeks
- Large: 4-8 engineers, 3-6 months
- XL: 8+ engineers or >6 months

**Critical dependencies:**
- External APIs, data sources, or platforms the idea depends on
- Regulatory or compliance requirements (GDPR, HIPAA, PCI, etc.)
- Third-party integrations that must be negotiated

**Blockers (must resolve before build):**
- Legal/IP issues
- Data access requirements
- Partnership requirements
- Infrastructure prerequisites

---

## Step 6: Produce Verdict

Based on the four dimensions, assign one of:

- **GO**: All four dimensions look favorable. Recommend proceeding to research.
- **GO-WITH-CONDITIONS**: One or more dimensions have concerns that are manageable with mitigations. List conditions that must be resolved.
- **NO-GO**: One or more dimensions represent a fundamental blocker. Explain why and what would need to change for a future re-evaluation.

The verdict must be supported by explicit evidence from the four dimensions — not opinion.

---

## Step 7: Write Artifact

Write `$ARTIFACTS/feasibility/feasibility.md`:

```markdown
# Feasibility Assessment: [Idea Name]
*Date: [ISO date]*
*Branch: [branch]*

---

## Executive Summary
[2-3 sentence plain-language summary of the verdict and primary reasoning]

## Verdict: [GO | GO-WITH-CONDITIONS | NO-GO]

**Reasoning:**
[3-5 bullet points explaining the verdict, referencing specific findings below]

**Conditions (if GO-WITH-CONDITIONS):**
- [ ] [Condition 1 — what must be resolved and by when]
- [ ] [Condition 2]

---

## Market Analysis

### Problem Validation
[Findings]

### Market Sizing
| Metric | Estimate | Basis |
|--------|----------|-------|
| TAM    | [value]  | [source or reasoning] |
| SAM    | [value]  | [source or reasoning] |
| SOM    | [value]  | [source or reasoning] |

### Target Users
[Primary personas, early adopter profile]

---

## Technical Risk

| Component | Risk Tier | Challenge | Build vs Buy | Notes |
|-----------|-----------|-----------|--------------|-------|
| [component] | HIGH/MED/LOW | [description] | Build/Buy/OSS | [rationale] |

---

## Competitive Landscape

| Competitor | Type | Strength | Weakness | Moat Risk |
|------------|------|----------|----------|-----------|
| [name]     | Direct/Indirect | [what they do well] | [gap] | [HIGH/MED/LOW] |

**Our moat:** [classification and explanation]

---

## Resource Assessment

**Scope:** [Small/Medium/Large/XL]

**Critical Dependencies:**
- [dependency]: [risk level and mitigation]

**Blockers (must resolve before build):**
- [blocker]: [resolution path]

---

## Recommended Next Steps

[ ] [Step 1 — e.g., "Validate problem with 5 user interviews before committing to build"]
[ ] [Step 2]
[ ] [Step 3]

**If GO: continue to** `/sdlc:01-research`
```

---

## Step 8: Update State

Update `$STATE` (state.json):
- Set `phases.feasibility.status` = `"completed"`
- Set `phases.feasibility.completedAt` = current ISO timestamp
- Set `phases.feasibility.artifacts` = `["feasibility.md"]`
- Set `updatedAt` = current ISO timestamp

---

## Step 9: Checkpoint

Present the verdict and summary to the user.

Run quality gate check:
- [ ] Verdict is one of: GO / GO-WITH-CONDITIONS / NO-GO
- [ ] All four dimensions have content
- [ ] At least one Recommended Next Step is listed
- [ ] No `[TBD]` or `[placeholder]` strings remaining

Then offer:

```
Feasibility assessment complete.

Verdict: [GO | GO-WITH-CONDITIONS | NO-GO]

Artifact: $ARTIFACTS/feasibility/feasibility.md

Next steps:
  → Continue to research:  /sdlc:01-research
  → Stop here and review first (come back when ready)
```

If GO-WITH-CONDITIONS: remind the user to resolve the listed conditions before continuing.
If NO-GO: do not suggest continuing. Offer to save the assessment for future reference.
