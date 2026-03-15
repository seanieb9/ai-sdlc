---
name: sdlc:roadmap
description: >
  Agentic project roadmap — human session planning for microsquad or solo development.
  Plans human effort (Design Sessions, Review Sessions, Sync Points) not story points.
  The coding phases are AI-autonomous; the planning focuses on the design phases where
  human judgment is irreplaceable.
  AUTO-TRIGGER — invoke this skill when the user asks about planning, timeline, effort,
  team coordination, or how long the project will take.
  Trigger patterns: "how long will this take?", "how should we plan this?", "who does what?",
  "can you give us a roadmap?", "how many sessions will this take?", "let's plan the project"
  Do NOT trigger if .sdlc/STATE.md does not exist.
  Optional — individual developers can skip this entirely and work phase by phase.
argument-hint: "[--update] [--skip-voc] [--solo] [--simple] [--thorough]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - AskUserQuestion
---

<objective>
Generate or update .sdlc/ROADMAP.md — a human-effort plan for completing this project.

This is NOT traditional project planning. It does not estimate coding hours or assign story points. It identifies:
  1. Which phases require human judgment (Design Sessions)
  2. Which phases AI runs autonomously and human reviews the output (Review Sessions)
  3. Who in the microsquad owns each phase
  4. Where the team must sync before proceeding
  5. The critical path through the design phases

Flags:
  --update      Refresh an existing roadmap — preserves phase log, recalculates estimates
  --skip-voc    Exclude Phase 1b (VoC) — no primary customer data available
  --solo        Force solo mode — all phases owned by one person, no syncs
  --simple      Use minimum session estimates (speed-optimised)
  --thorough    Use maximum session estimates (quality-optimised)

Output: .sdlc/ROADMAP.md
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/roadmap.md
@/Users/seanlew/.claude/sdlc/references/planning-standards.md
@/Users/seanlew/.claude/sdlc/templates/roadmap.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>
