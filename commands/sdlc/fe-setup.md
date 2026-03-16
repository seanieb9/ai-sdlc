---
name: sdlc:fe-setup
description: Front-end design system setup — configure design tokens (3 levels: none/brand/full), select component library, and derive SCREEN_SPEC.md from the customer journey. Creates the foundation for all screen generation. Run after Phase 6 (Tech Architecture) when the stack includes a front-end.
argument-hint: "[--level none|brand|full] [--base tamagui|nativewind|unistyles]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

<objective>
Configure the front-end design system foundation before planning begins.

Process:
  1. Read TECH_ARCHITECTURE.md (confirm FE stack), CUSTOMER_JOURNEY.md, API_SPEC.md, PERSONAS.md
  2. Determine design system level — ask ONE question if not specified via flag
  3. Build design token set (defaults / derive from brand / ingest from file)
  4. Configure component library and token mapping
  5. Derive SCREEN_SPEC.md from journey steps — each interaction step = one screen
  6. Identify shared components (appears in 2+ screens)
  7. Write DESIGN_TOKENS.md, COMPONENT_LIBRARY.md, SCREEN_SPEC.md
  8. Update STATE.md, output summary

Gate: TECH_ARCHITECTURE.md must exist with a ## Frontend Architecture section.
Gate: CUSTOMER_JOURNEY.md must exist — screens derive from journey steps.
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/fe-setup.md
@/Users/seanlew/.claude/sdlc/references/frontend-standards.md
@/Users/seanlew/.claude/sdlc/templates/design-tokens.md
@/Users/seanlew/.claude/sdlc/templates/screen-spec.md
@/Users/seanlew/.claude/sdlc/references/doc-writing-standards.md
</execution_context>
