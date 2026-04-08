# Research Workflow

Conduct deep market, competitive, industry, and customer research. Output to the branch-scoped artifacts directory — always update existing files, never recreate.

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

## Step 1: Pre-Flight

Read existing research (if any):
- `$ARTIFACTS/research/research.md` — note existing sections to update vs add
- `$ARTIFACTS/research/gap-analysis.md` — note existing gaps to enrich
- `$STATE` — understand project context, domain, constraints (read and parse JSON)

If no prior research: create `docs/research/` directory and initialize files with headers only.

Note the topic from `$ARGUMENTS`. If not provided, derive from state.json project description.

Check flags:
- `--deep` → run all research dimensions at maximum depth
- `--competitive-only` → skip market/trends/best-practice sections
- `--customer-only` → skip competitive/analyst sections (prefer the voc workflow (workflows/voc.md) for primary data)

## Step 2: Build Research Query Set

Generate targeted queries across all research dimensions:

### Dimension 1: Market Landscape
- "[topic] market size TAM SAM [current year]"
- "[topic] industry growth forecast CAGR"
- "[topic] market leaders share [current year]"
- "[topic] market segmentation enterprise SMB"
- "[topic] emerging technologies disruption"

### Dimension 2: Deep Competitive Intelligence
- "[topic] top competitors [current year] comparison"
- "[competitor name] pricing tiers enterprise"
- "[competitor name] changelog release notes [year]" (repeat per major competitor)
- "[competitor name] engineering blog"
- "[competitor name] job postings [role]" (signals investment areas)
- "[topic] vs [competitor] features benchmark"
- "site:g2.com [topic]" — aggregated user reviews
- "site:capterra.com [topic] reviews"
- "site:producthunt.com [topic]" — launch momentum
- "[topic] alternatives [current year]"

### Dimension 3: Analyst & Thought Leadership
- "Gartner [topic] magic quadrant [year]"
- "Forrester wave [topic] [year]"
- "IDC [topic] market report [year]"
- "[domain-specific analyst firm] [topic] report" (e.g., CB Insights, a16z, Benedict Evans for tech; KLAS for healthcare; Aite-Novarica for fintech)
- "[topic] thought leaders practitioners [year]"
- "[topic] keynote talk conference [year]" — search YouTube/conference sites
- "site:a16z.com [topic]"
- "site:substack.com [topic] analysis"
- "[topic] research paper arxiv" (if relevant technical domain)

### Dimension 4: Best Practices & Proven Patterns
- "[topic] best practices implementation [year]"
- "[topic] design patterns proven approach"
- "[topic] case study [well-known company] how they built"
- "[topic] architecture patterns lessons learned"
- "[topic] anti-patterns mistakes to avoid"
- "how [company X] scaled [topic]" (repeat for 2-3 well-known players)
- "[topic] open source implementation github stars"

### Dimension 5: Emerging Trends & Future Signals
- "[topic] VC funding investment [current year]"
- "[topic] startup funding crunchbase [year]"
- "[topic] github trending [topic keywords]"
- "[topic] job postings growth trends" (hiring = investment signal)
- "[topic] 2026 2027 predictions trends"
- "[topic] early adopter enterprise pilot"
- "what's next for [topic] [year]"

### Dimension 6: Customer Voice (surface-level — deep VoC goes to the voc workflow (workflows/voc.md))
- "[topic] user complaints reddit"
- "[topic] pain points missing features"
- "what customers want [topic]"
- "[topic] wishlist feature requests"

## Step 3: Execute Research in Parallel

Use the Task tool to run concurrent web searches across all dimensions. Assign one Task per dimension to maximise throughput.

For each significant finding:
- Note the source and date
- Extract the key insight (one sentence)
- Flag relevance to the project (HIGH / MEDIUM / LOW)
- Note the signal type: FACT | OPINION | TREND | SIGNAL

Focus on:
1. Who are the top 3-5 competitors and what is their positioning strategy?
2. What do analysts say about this market and where it's heading?
3. What proven implementation patterns exist — and what has failed?
4. What are the 2-3 year horizon signals (investment, hiring, OSS momentum)?
5. What do customers consistently love vs consistently complain about?

## Step 4: Deep Competitive Analysis

For each of the top 3-5 competitors, build a structured profile:

```
Competitor: [Name]
Positioning: [one-line market position]
Target Segment: [enterprise / SMB / developer / etc.]
Pricing Model: [per seat / usage / flat / freemium / etc.]
Pricing Tiers: [free tier if any | starter | growth | enterprise]
Core Strengths: [2-3 things they do very well]
Known Weaknesses: [2-3 gaps users cite]
Product Velocity: [fast / moderate / slow — based on changelog/release cadence]
Investment Signals: [recent hires, job postings focus areas, blog topics]
Recent Moves: [last 6-12 months: new features, partnerships, acquisitions]
```

Then produce:
- **Positioning Matrix** (2×2): pick the two most differentiating axes for this market and place competitors
- **Feature Matrix**: rows = competitors, columns = key capability areas, cells = ✅ / ❌ / ⚠️ (partial)
- **SWOT per key competitor** (keep brief — 2-3 points per quadrant)

## Step 5: Analyst & Thought Leadership Synthesis

Summarise what the recognised experts say:

- **Analyst Consensus**: where do Gartner/Forrester/domain analysts agree? What are their key recommendations?
- **Contrarian Views**: where do credible practitioners disagree with analyst consensus?
- **Emerging Academic Work**: any research papers or published experiments worth noting?
- **Conference Signal**: what did the last 1-2 major conferences in this domain focus on? What sessions drew attention?
- **Practitioner Blogs**: 2-3 key practitioner-authored posts with their central argument

## Step 6: Best Practices Distillation

Extract from case studies and published implementations:

**Proven Approaches** (with evidence source):
- What architectures / design patterns consistently succeed in this domain?
- Which implementation approaches do companies adopt when scaling?
- What does the "canonical" good implementation look like?

**Known Failure Modes** (with evidence source):
- What approaches consistently underperform or cause problems?
- What does "early decision regret" look like in this domain?
- Which anti-patterns appear across multiple case studies?

**Implementation Sequencing**:
- What do companies typically build first vs defer?
- What are the common "do this before that" lessons?

## Step 7: Emerging Trends Assessment

For each signal found, structure as:

```
Signal: [what was observed]
Source: [VC deal / OSS repo / job posting trend / early adopter adoption]
Strength: [STRONG / MODERATE / WEAK] — based on number and quality of sources
Horizon: [NOW (< 1yr) / NEAR (1-2yr) / FAR (2-3yr+)]
Implication: [what this means for product decisions]
```

Synthesise into a "Next 2 Years" narrative: what is the market likely to look like, and what bets does that suggest making now?

## Step 8: Analyze Existing Codebase (if applicable)

If this is an existing project, run in parallel with web research:
- Use Glob to map existing modules related to the topic
- Use Grep to find existing implementations
- Note: what already exists that could be reused or extended?
- Note: what patterns and conventions are established?
- Note: what are the current limitations relative to competitive baseline?

## Step 9: Synthesize All Findings

Consolidate into five structured sections:

**Market Landscape:**
- Current state: size, growth, key dynamics
- Key trends (3 most important, sourced)
- Technology direction

**Competitive Intelligence:**
- Competitor profiles (from Step 4)
- Positioning matrix
- Feature matrix
- SWOT summary
- Differentiation opportunities

**Analyst & Thought Leadership:**
- Analyst consensus view
- Key practitioner insights
- Contrarian perspectives worth noting

**Best Practices:**
- Proven approaches (sourced)
- Known failure modes (sourced)
- Implementation sequencing lessons

**Emerging Trends:**
- Signal table (from Step 7)
- 2-year narrative
- Product bets implied

**Customer Voice (surface):**
- Top 5 pain points (with sources)
- Most requested features
- What customers love about existing solutions
- → Deep analysis: run voc workflow inline (workflows/voc.md) with primary data

## Step 10: Write Output Documents

**Update $ARTIFACTS/research/research.md:**

```markdown
# Research: [Topic]
*Last Updated: [date]*

## Executive Summary
- [Key finding 1]
- [Key finding 2]
- [Key finding 3]
- [Key finding 4]
- [Key finding 5]

## Market Landscape
[content]

## Competitive Intelligence

### Competitor Profiles
[structured profiles per competitor]

### Positioning Matrix
[2×2 matrix — text description or Mermaid quadrant if supported]

### Feature Matrix
| Capability | [Comp A] | [Comp B] | [Comp C] | Our Position |
|------------|----------|----------|----------|--------------|
| [Feature]  | ✅       | ❌       | ⚠️       | [planned]    |

## Analyst & Thought Leadership
[content with sources]

## Best Practices
[proven approaches + failure modes, sourced]

## Emerging Trends
[signal table + narrative]

## Technical Landscape
[common technical approaches, OSS ecosystem, standards]

## Regulatory & Compliance Notes
[content or "N/A"]

## Sources
[numbered source list with dates accessed]
```

**Update $ARTIFACTS/research/gap-analysis.md:**

```markdown
# Gap Analysis: [Topic]
*Last Updated: [date]*

## Customer Pain Points
[Prioritized list — each with evidence source and severity: CRITICAL/HIGH/MEDIUM]

## Unmet Needs
[What customers want that nobody provides well — with demand evidence]

## Competitive Gaps
[Where ALL competitors fall short — verified across multiple sources]

## Differentiation Opportunities
[Ranked by: impact × feasibility × defensibility]

## Quick Wins
[High customer value, low implementation effort — actionable now]

## Strategic Bets
[Longer-horizon, higher-value opportunities implied by trend signals]

## What NOT to Build
[Anti-patterns and market areas to avoid — with rationale]
```

For both files: add/update sections. Never delete existing content without noting the change.

## Step 11: Update State

Update `$STATE` (state.json):
- Set phase 1 (Research) status to "complete"
- Update document index
- Add key finding to decisions array: `{"date": "[date]", "type": "RESEARCH", "note": "[top finding]"}`

## Step 12: Output Summary

```
✅ Research Complete

Key Findings:
• [Market finding]
• [Competitive insight]
• [Analyst/thought leadership insight]
• [Best practice]
• [Emerging trend signal]

Competitive Landscape:
• Top competitors: [names]
• Strongest differentiation opportunity: [summary]

Best Practice Insights:
• [Key proven approach]
• [Key failure mode to avoid]

Emerging Signals:
• [Top 2-year signal]

Files Updated:
• $ARTIFACTS/research/research.md
• $ARTIFACTS/research/gap-analysis.md

Recommended Next:
• Deep customer data → the voc workflow
• Or proceed to → /sdlc:02-synthesize
```
