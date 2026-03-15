# Synthesize Workflow

Synthesize research findings with deep codebase analysis to produce a unified readiness picture before specs are written.

## Step 1: Gather All Inputs

Read in parallel:
- `docs/research/RESEARCH.md`
- `docs/research/GAP_ANALYSIS.md`
- `.sdlc/STATE.md` (project context)
- `.sdlc/CODEBASE_MAP.md` (if exists — brownfield codebase index)

If neither research doc exists: warn the user that research should come first, offer to run `/sdlc:01-research` first.

## Step 2: Codebase Analysis

Unless `--research-only` flag is set, perform codebase analysis:

**If `.sdlc/CODEBASE_MAP.md` exists (brownfield):**
Use the map as the primary source of codebase knowledge. Extract from it:
- Tech stack and architectural pattern
- Domain concepts and services relevant to the research topic
- Existing API endpoints related to the topic
- Data access patterns and existing models
- Known tech debt and hotspot files
- Cross-cutting concerns (auth, logging, error handling)

Avoid re-scanning the entire codebase. Use `/sdlc:explore` queries for specific detail gaps not covered by the map. Only read individual files when the map points to a specific file that needs deeper analysis.

**If no CODEBASE_MAP.md exists (greenfield or map not yet run):**
Perform a targeted scan:
- Glob for top-level directories and key files
- Identify the tech stack (package.json, requirements.txt, go.mod, pom.xml, etc.)
- Identify architectural patterns in use (MVC, hexagonal, layered, etc.)
- Find existing code related to the research topic
- Identify existing data models/schemas
- Find existing API endpoints related to the topic
- Note existing test patterns and coverage
- Identify configuration and environment patterns

Recommend running `/sdlc:map` after synthesis to build a persistent map for future sessions.

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

**Create/update docs/research/SYNTHESIS.md:**

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

Update `.sdlc/STATE.md` — mark Phase 2 complete.

Show user summary:
```
✅ Synthesis Complete

Reuse Opportunities: [N found]
Risk Areas: [N identified]
Recommended Approach: [1-line summary]

File: docs/research/SYNTHESIS.md

Recommended Next: /sdlc:03-product-spec
```
