# Voice of Customer Workflow

Synthesize primary customer data into prioritized, evidence-backed findings. First-party data beats inferred pain from public forums every time.

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

## Step 1: Assess Available Data

Read existing context:
- `$STATE` — project context (read and parse JSON)
- `$ARTIFACTS/research/research.md` — existing market research (don't duplicate)
- `$ARTIFACTS/research/gap-analysis.md` — existing gaps (we'll enrich these with evidence)
- `$ARTIFACTS/research/voc.md` — existing VoC findings (update, don't replace)

Ask the user (AskUserQuestion) what primary data they have:
1. "What customer data do you have available? (e.g. interview transcripts, support tickets, NPS responses, churn notes, sales call notes)"
2. "Please share/paste the data, or tell me where to find it in the codebase/project."

If `--guided` flag: skip to Step 7 (Collection Framework).
If no data is available and no --guided flag: offer to generate a collection framework or proceed with secondary research only.

## Step 2: Ingest and Catalog Data

For each data source provided:

| Source | Type | Volume | Date Range |
|--------|------|--------|-----------|
| [filename or paste] | interviews/tickets/NPS/other | [N records] | [date range] |

Read all provided files/pasted content. If data is in a structured format (CSV, JSON), parse it. If unstructured (transcripts, notes), read as text.

Note: Do NOT lose any data. Process everything provided.

## Step 3: Open Coding — Extract Raw Themes

Read through all data and extract every distinct customer statement, complaint, request, or observation. For each:

```
RAW-001: "[verbatim quote or close paraphrase]"
  Source: [interview ID / ticket ID / NPS response ID]
  Customer: [anonymized ID or segment if known]
  Data type: [complaint | request | compliment | observation | confusion]
```

Aim to extract every meaningful signal, even weak ones. Don't filter yet.

## Step 4: Affinity Grouping — Identify Themes

Group raw codes into themes. Themes emerge from the data — don't force them into pre-existing categories.

For each theme:
```
THEME: [Name]
  Description: [What this theme is about in 1-2 sentences]
  Raw codes: RAW-001, RAW-005, RAW-012, ...
  Frequency: [N customers mentioned this] / [N total]
  Severity: [1-5] — 1=minor inconvenience, 5=blocks core job
  Evidence strength: [HIGH/MEDIUM/WEAK] — how many distinct sources confirm it
```

Then cluster themes into higher-order categories:
- Workflow/Process pain
- Missing capabilities
- Performance/reliability issues
- Onboarding/learning curve
- Pricing/value perception
- Integration/interoperability
- Trust/security concerns

## Step 5: Jobs-to-be-Done Mapping

For the top themes, map to JTBD:

```
THEME: [Theme name]

Functional Job: [What they are literally trying to accomplish]
  "When I [situation], I want to [motivation], so I can [outcome]"

Emotional Job: [How they want to feel while doing it / how they want to avoid feeling]
  "I want to feel [emotion] / avoid feeling [emotion]"

Social Job: [How they want to be perceived by others]
  "I want others to see me as [perception]"

Current solution: [What they do today]
  Why it falls short: [The gap]

Desired outcome: [What success looks like for them]
```

## Step 6: Prioritize and Synthesize

Build priority matrix:

```
PRIORITY MATRIX
===============
Rank | Theme                | Freq | Severity | Score | Unmet? | Opportunity
-----|----------------------|------|----------|-------|--------|------------
1    | [theme]             | 8/10 | 4        | 32    | YES    | HIGH
2    | [theme]             | 7/10 | 4        | 28    | PARTIAL| MEDIUM
3    | [theme]             | 9/10 | 2        | 18    | NO     | LOW
```

Score = frequency_pct × severity (0-25 scale)
Unmet = is there currently NO good solution to this in the market?

**Highest value opportunities = high score + unmet = YES**

## Step 7 (--guided): Collection Framework

If `--guided` flag or no data available, generate tools to collect VoC data:

### Customer Interview Guide
```markdown
# Customer Interview Guide: [Topic]
*Duration: 45-60 minutes | Objective: [what you're trying to learn]*

## Warm-up (5 min)
1. Tell me about your role and what you're responsible for.
2. How does [product area] fit into your day-to-day work?

## Current Situation (10 min)
3. Walk me through the last time you [relevant task]. What happened?
4. What tools or processes do you use for [task] today?
5. What do you wish was different about how that works?

## Problem Deep Dive (15 min)
6. You mentioned [pain]. Can you tell me more about that?
7. How often does that happen? What's the impact when it does?
8. Have you tried to solve this? What happened?
9. If you could wave a magic wand and fix one thing, what would it be?

## Prioritization (10 min)
10. Of the problems we've discussed, which causes you the most pain?
11. What would change for you if [problem] was solved?

## Wrap-up (5 min)
12. Is there anything else I should know?
13. Who else should I talk to about this?

## Interviewer Notes
- What was most surprising?
- What contradicted existing assumptions?
- Direct quotes to capture:
```

### NPS Open-Text Survey Template
```
"In your own words, what is the primary reason for your score?"
"What is the one thing we could do to improve your experience?"
"What would you lose if you could no longer use [product]?"
```

### Support Ticket Tagging Guide
```
Categories to tag:
  BUG: Product not working as expected
  MISSING_FEATURE: Customer wants capability that doesn't exist
  CONFUSION: Customer doesn't understand how to do something
  PERFORMANCE: Too slow, reliability issues
  INTEGRATION: Connecting with other tools
  BILLING: Pricing, invoicing, plan questions
  SECURITY: Trust, data, permissions concerns
```

## Step 8: Write Output Documents

**Create/update $ARTIFACTS/research/voc.md:**

```markdown
# Voice of Customer
*Last Updated: [date] | Sources: [N interviews, N tickets, N NPS responses]*

## Data Sources
[Source catalog table]

## Priority Matrix
[Full priority matrix]

## Themes

### THEME: [Name] (Score: [N] | Unmet: YES/NO)
*Frequency: [N]/[N] customers | Severity: [N]/5*

**What customers say:**
> "[Verbatim quote 1]" — [Source ID]
> "[Verbatim quote 2]" — [Source ID]

**Functional Job:** [JTBD statement]
**Emotional Job:** [How they want to feel]
**Current workaround:** [What they do today + why it fails]
**Opportunity:** [What solving this unlocks]

[repeat for each theme]

## Key Insights
[3-5 bullet synthesis of the most important findings]

## What This Changes
[How these findings update or validate existing GAP_ANALYSIS.md findings]
```

**Update $ARTIFACTS/research/gap-analysis.md:**
For each existing gap, add primary evidence:
```
[Existing gap] — **Primary evidence: [N customers, severity [N]]** > "[Quote]"
```

## Step 9: Update State

Mark VoC phase complete in $STATE.
Update document index in $STATE with voc.md path.

Output:
```
✅ Voice of Customer Complete

Data processed: [N interviews | N tickets | N NPS responses]
Themes identified: [N]
Top pain (unmet): [theme name] — [N] customers, severity [N]/5

Files:
• $ARTIFACTS/research/voc.md (new)
• $ARTIFACTS/research/gap-analysis.md (enriched with primary evidence)

Recommended Next: the synthesize phase (tell Claude to proceed) or the personas workflow
```
