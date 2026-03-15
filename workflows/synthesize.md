# Synthesize Workflow

Synthesize research findings with deep codebase analysis to produce a unified readiness picture before specs are written.

## Step 1: Gather All Inputs

Read in parallel:
- `docs/research/RESEARCH.md`
- `docs/research/GAP_ANALYSIS.md`
- `.sdlc/STATE.md` (project context)

If neither research doc exists: warn the user that research should come first, offer to run `/sdlc:01-research` first.

## Step 2: Codebase Analysis

Unless `--research-only` flag is set, perform deep codebase scan:

**Structure mapping:**
- Glob for top-level directories and key files
- Identify the tech stack (package.json, requirements.txt, go.mod, pom.xml, etc.)
- Identify architectural patterns in use (MVC, hexagonal, layered, etc.)

**Relevant code analysis:**
- Find existing code related to the research topic
- Identify existing data models/schemas
- Find existing API endpoints related to the topic
- Note existing test patterns and coverage
- Identify configuration and environment patterns

**What to capture:**
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
