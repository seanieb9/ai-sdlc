---
name: sdlc:03b-personas
description: Rigorous persona definition using Jobs-to-be-Done, empathy mapping, customer segmentation, and anti-personas. Produces docs/product/PERSONAS.md — the authoritative persona registry used by all downstream phases.
argument-hint: "[persona name or segment] [--new] [--update <name>] [--validate] [--anti-persona]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - Task
  - Agent
  - AskUserQuestion
---

<objective>
Build rigorous, evidence-grounded personas that are genuinely useful — not made-up archetypes.

Every persona must be:
  - Grounded in data (VOC.md, GAP_ANALYSIS.md, RESEARCH.md)
  - Validated against real customer evidence
  - Defined with Jobs-to-be-Done (not just demographics)
  - Accompanied by an empathy map
  - Paired with an anti-persona

Output (single authoritative document, update not recreate):
  - docs/product/PERSONAS.md — full persona registry

Persona components (all required):
  1. Segment — which customer segment this persona represents
  2. Narrative — a day-in-the-life paragraph grounded in research
  3. Jobs-to-be-Done — functional job, emotional job, social job
  4. Gains — what outcomes they want more of
  5. Pains — frustrations, blockers, risks they want to avoid
  6. Current solutions — what they use today and why it falls short
  7. Empathy map — what they Think, Feel, Say, Do
  8. Validation criteria — what real customer data supports this persona
  9. Anti-persona — who this persona is NOT (and why we won't build for them)

Rules:
  - Minimum 2 personas per project, maximum 5 (more = unfocused)
  - Every persona pain must link to evidence in VOC.md or GAP_ANALYSIS.md
  - Anti-personas are mandatory — prevents scope creep
  - Personas are updated when new VoC data arrives, never replaced
  - Primary persona drives data model and product spec decisions
</objective>

<context>
Persona/segment: $ARGUMENTS

Flags:
  --new              Create a brand new persona
  --update <name>    Update a specific named persona with new evidence
  --validate         Audit existing personas against current VoC data
  --anti-persona     Focus on defining anti-personas
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/personas.md
@/Users/seanlew/.claude/sdlc/references/product-standards.md
</execution_context>
