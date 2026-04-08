---
name: sdlc:verify
description: Independent quality gate — verify that a completed SDLC phase produced complete, consistent, correct outputs before the next phase begins. Run after every phase.
argument-hint: "[--phase <N>] [--last] [--all] [--verbose]"
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

<objective>
Independently verify the outputs of one or more completed SDLC phases.

This command does NOT re-run a phase. It inspects the artifacts that phase produced and confirms:
  1. All required output documents exist and are not empty
  2. All mandatory sections are present (no placeholders, no TODOs)
  3. Cross-references between this phase's outputs and prior phase outputs are consistent
  4. The phase gate requirements for the NEXT phase are satisfied

Run this after every phase — before starting the next one.

Phase checklist summary:
  Phase 1  (Research)         → RESEARCH.md complete, GAP_ANALYSIS.md exists, ≥2 competitors analyzed
  Phase 2  (Synthesize)       → SYNTHESIS.md has integrated findings + tech direction
  Phase 3  (Product Spec)     → REQ-IDs, BR-IDs, numeric NFRs, BDD scenarios, error table
  Phase 3b (Personas)         → PERSONAS.md with JTBD, anti-personas
  Phase 4  (Customer Journey) → Happy + failure journeys documented
  Phase 5  (Data Model)       → DATA_MODEL.md + DATA_DICTIONARY.md both complete, all entities have id/timestamps/invariants
  Phase 6  (Tech Arch)        → TECH_ARCHITECTURE.md + API_SPEC.md + SOLUTION_DESIGN.md all complete, ≥3 ADRs, dependency classification, NFR coverage
  Phase 7  (Plan)             → PLAN.md + TODO.md with prioritized tasks
  Phase 8  (Code)             → Clean architecture rule enforced, all entities implemented, P0 tasks done
  Phase 9  (Test Cases)       → All 8 test layers, every REQ/BR/NFR/endpoint/dependency covered
  Phase 10 (Test Automation)  → TC-ID to file map, P0 coverage complete, drift detection documented
  Phase 11 (Observability)    → Logging spec, trace propagation, RED metrics, OBS-IDs
  Phase 12 (SRE)              → Runbooks per CRITICAL dependency, SLOs defined
  Phase 13 (Review)           → REVIEW_REPORT.md complete, all HIGH/CRITICAL findings have TODO items

Output: Verification result printed + `phases.verify` in state.json updated with result.

Flags:
  --phase <N>   Verify a specific phase number
  --last        Verify the most recently completed phase (default if no flag)
  --all         Verify all completed phases in sequence
  --verbose     Show passing checks in addition to failures and warnings
</objective>

<context>
Phase(s) to verify: $ARGUMENTS
</context>

<execution_context>
@~/.claude/sdlc/workflows/verify.md
</execution_context>
