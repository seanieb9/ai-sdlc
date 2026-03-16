---
name: sdlc:fe-screen
description: Generate a screen from SCREEN_SPEC.md. Applies design tokens via the configured component library, wires API contracts from API_SPEC.md via TanStack Query hooks, implements all four states (loading/empty/error/success), enforces WCAG 2.1 AA accessibility, and extracts shared components. Run during Phase 8 for each [fe] task in TODO.md.
argument-hint: "<screen-name-or-route>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

<objective>
Generate a single screen from the front-end spec. Every screen must:
  - Implement all four states: loading (skeleton), empty, error (with retry), success
  - Wire only to API contracts from API_SPEC.md — no direct DB or business logic
  - Use only token-based styles — no hardcoded colors, spacing, or font sizes
  - Pass WCAG 2.1 AA — all interactive elements labelled, 44×44pt touch targets
  - Extract any component appearing in 2+ screens to components/ui/

Process:
  1. Identify screen from $ARGUMENTS — match against SCREEN_SPEC.md routes/names
  2. Read screen spec: template type, data requirements, navigation flows, states, components
  3. Plan file structure (screen file, hook file, shared components)
  4. Create/update TanStack Query hooks — typed to API_SPEC.md schemas
  5. Generate screen code applying the correct template pattern
  6. Implement accessibility attributes and testIDs on all interactive elements
  7. Extract shared components to components/ui/
  8. Update COMPONENT_LIBRARY.md custom components table
  9. Output summary with files written and next screen

Gate: SCREEN_SPEC.md must exist — run /sdlc:fe-setup first.
Gate: DESIGN_TOKENS.md must exist — run /sdlc:fe-setup first.
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/fe-screen.md
@/Users/seanlew/.claude/sdlc/references/frontend-standards.md
</execution_context>
