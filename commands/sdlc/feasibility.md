---
name: sdlc:feasibility
description: Go/No-Go viability assessment — market size, technical risk, competitive moat, build vs buy
argument-hint: "[idea or feature]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Phase 0 viability assessment. Before investing in research and design, determine whether the idea is worth pursuing.

Assesses four dimensions:
  - Market viability: Is there a real problem? How big is the addressable market? Who are the target users?
  - Technical risk: What are the hardest technical problems? Any novel/unproven tech? Team capability match?
  - Competitive landscape: Who else solves this? What's the moat? Build vs buy analysis.
  - Resource assessment: Rough scope (Small/Medium/Large/XL), critical dependencies, blockers.

Produces a clear verdict: GO / GO-WITH-CONDITIONS / NO-GO with explicit reasoning.

Reads:
  - `.claude/ai-sdlc.config.yaml` — project configuration (required)
  - `$ARTIFACTS/research/research.md` — prior research (if exists)

Outputs:
  - `$ARTIFACTS/feasibility/feasibility.md` — full assessment with verdict
</objective>

<context>
Idea or feature: $ARGUMENTS

Flags:
  (none — use $ARGUMENTS to describe the idea)
</context>

<execution_context>
@~/.claude/sdlc/workflows/feasibility.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the feasibility verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>
