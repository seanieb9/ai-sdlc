---
name: sdlc:voc
description: Voice of Customer — synthesize primary customer data (interview transcripts, support tickets, NPS/CSAT responses, churn notes, sales calls) into prioritized, evidence-backed pain points and opportunities.
argument-hint: "[topic/feature] [--interviews] [--tickets] [--nps] [--guided]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - Agent
  - AskUserQuestion
---

<objective>
Synthesize first-party customer data into evidence-backed findings. This is stronger signal than inferred pain from public forums.

Handles any combination of primary sources:
  - Customer interview transcripts (uploaded or pasted)
  - Support ticket exports
  - NPS/CSAT open-text responses
  - Churn interview notes
  - Sales call notes / CRM exports
  - User testing session notes
  - In-app feedback submissions

Output (update existing, never recreate):
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/voc.md — themed findings with verbatim evidence, frequency counts, severity ratings
  - .claude/ai-sdlc/workflows/<branch>/artifacts/research/gap-analysis.md — enriched with primary-source evidence

If no primary data is available: use --guided flag to get a structured interview/survey framework to collect it first.

Methodology:
  1. Ingest all provided data sources
  2. Code themes (open coding → affinity grouping)
  3. Count frequency per theme (how many customers mention this)
  4. Rate severity (how much does this hurt them: 1-5)
  5. Extract verbatim quotes as evidence
  6. Map themes to Jobs-to-be-Done (functional, emotional, social)
  7. Prioritize by frequency × severity
  8. Identify unmet needs (pain with no current solution)
</objective>

<context>
Topic/data: $ARGUMENTS

Flags:
  --interviews   Focus on interview transcript analysis
  --tickets      Focus on support ticket theme analysis
  --nps          Focus on NPS/CSAT open-text analysis
  --guided       No data yet — generate collection framework (interview guide, survey template)
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/voc.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
@/Users/seanlew/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 1b verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

