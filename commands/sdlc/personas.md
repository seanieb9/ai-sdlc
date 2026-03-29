---
name: sdlc:personas
description: Build evidence-grounded personas using Jobs-to-be-Done, empathy maps, and anti-personas. Feeds every downstream phase.
argument-hint: "[feature/domain] [--update]"
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
Build evidence-grounded personas using Jobs-to-be-Done, empathy maps, and anti-personas. These feed every downstream phase — data model, product spec, test cases, and journeys.

Requires evidence (personas without evidence are fiction):
  - Primary: .claude/ai-sdlc/workflows/<branch>/artifacts/research/voc.md
  - Secondary: gap-analysis.md, research.md

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/personas/personas.md

Persona structure per segment:
  - Narrative (day-in-the-life, grounded in evidence)
  - Jobs-to-be-Done (functional, emotional, social)
  - Gains and Pains (stratified by severity)
  - Empathy Map (Think/Feel, Say/Do, See, Hear)
  - Current Solutions and Gaps
  - Validation criteria (evidence citations + unvalidated assumptions)
  - Anti-persona (who we are NOT building for)
  - Persona hierarchy (conflict resolution rule)
</objective>

<context>
Feature/domain: $ARGUMENTS

Flags:
  --update   Update existing personas (adds evidence, refines based on new data)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/personas.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 3b verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

