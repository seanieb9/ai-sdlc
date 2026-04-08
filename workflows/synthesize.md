# Synthesize Workflow

Synthesize research findings with deep codebase analysis to produce a unified readiness picture before specs are written.

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

## Step 1: Gather All Inputs

Read in parallel:
- `$ARTIFACTS/research/research.md`
- `$ARTIFACTS/research/gap-analysis.md`
- `$STATE` (project context — read and parse JSON)
- `.claude/ai-sdlc/codebase/architecture.md` (if exists — brownfield codebase index)

If neither research doc exists: warn the user that research should come first, offer to run `/sdlc:01-research` first.

## Step 2: Codebase Analysis

Unless `--research-only` flag is set, perform codebase analysis:

**If `.claude/ai-sdlc/codebase/architecture.md` exists (brownfield):**
Use the map as the primary source of codebase knowledge. Extract from it:
- Tech stack and architectural pattern
- Domain concepts and services relevant to the research topic
- Existing API endpoints related to the topic
- Data access patterns and existing models
- Known tech debt and hotspot files
- Cross-cutting concerns (auth, logging, error handling)

Avoid re-scanning the entire codebase. Use `/sdlc:explore` queries for specific detail gaps not covered by the map. Only read individual files when the map points to a specific file that needs deeper analysis.

**If no architecture.md exists (greenfield or map not yet run):**
Perform a targeted scan:
- Glob for top-level directories and key files
- Identify the tech stack (package.json, requirements.txt, go.mod, pom.xml, etc.)
- Identify architectural patterns in use (MVC, hexagonal, layered, etc.)
- Find existing code related to the research topic
- Identify existing data models/schemas
- Find existing API endpoints related to the topic
- Note existing test patterns and coverage
- Identify configuration and environment patterns

Recommend running `/sdlc:map` after synthesis to build a persistent map at `.claude/ai-sdlc/codebase/architecture.md` for future sessions.

**What to capture (regardless of source):**
- Existing capabilities that overlap with research findings (reuse opportunities)
- Existing patterns to follow (consistency matters)
- Technical debt or limitations that affect the proposed feature
- Integration points (how new work will connect to existing)
- Risk areas (complex existing code that changes could break)

## Step 3: Synthesis Analysis

Cross-reference research vs codebase:

**Reuse matrix:**
| Research Need | Existing Capability | Gap | Effort |
|---|---|---|---|
| [need from research] | [what exists] | [what's missing] | [S/M/L] |

**Risk assessment:**
- What existing components will be touched?
- What are the data model implications?
- What integrations need to change?
- What could break?

**Approach recommendation:**
- Extend existing? Build new? Replace?
- Build order (dependencies)
- Technical approach rationale

## Step 4: Write Synthesis Document

**Create/update $ARTIFACTS/research/synthesis.md:**

```
# Synthesis: [Topic]
*Last Updated: [date]*

## Summary
[3-5 sentence synthesis of research + codebase reality]

## Research Says We Need
[Key requirements from research, prioritized]

## What the Codebase Already Provides
[Existing capabilities relevant to this work]

## Gap Between Current State and Target
[Precise delta — what needs to be built/changed]

## Reuse Opportunities
[What existing code/patterns to leverage]

## Risk Areas
[Components, data models, integrations at risk]

## Recommended Approach
[Build order, key decisions, rationale]

## Readiness Assessment
- Data model impact: [HIGH/MEDIUM/LOW]
- Existing code impact: [HIGH/MEDIUM/LOW]
- New infrastructure needed: [YES/NO — what]
- Breaking changes risk: [HIGH/MEDIUM/LOW]
```

## Step 5: Update State and Output

Update `$STATE` (state.json) — mark Phase 2 complete.

Show user summary:
```
✅ Synthesis Complete

Reuse Opportunities: [N found]
Risk Areas: [N identified]
Recommended Approach: [1-line summary]

File: $ARTIFACTS/research/synthesis.md

Recommended Next: /sdlc:03-product-spec
```
