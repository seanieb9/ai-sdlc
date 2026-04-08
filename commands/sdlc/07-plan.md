---
name: sdlc:07-plan
description: Create a detailed, phased execution plan in .sdlc/PLAN.md and .sdlc/TODO.md. Breaks down work into atomic tasks with dependencies. No code without a plan.
argument-hint: "<feature/phase> [--breakdown] [--estimate] [--dependencies]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - WebFetch
---

<objective>
Create a precise, executable plan before any code is written.

Manages:
  - .sdlc/PLAN.md — full execution plan with phases, tasks, dependencies, acceptance criteria
  - .sdlc/TODO.md — current active task list (prioritized, with status)

Plan structure:
  1. Goal — what this plan achieves
  2. Prerequisites — what must be done/exist before starting
  3. Phases — logical groupings of work (data layer → domain → application → API → UI → tests → observability)
  4. Tasks — atomic, completable in one session, with clear done criteria
  5. Dependencies — what blocks what
  6. Risk items — what could go wrong, mitigation
  7. Test strategy — how each phase will be verified

Planning rules:
  - Read DATA_MODEL.md, TECH_ARCHITECTURE.md, PRODUCT_SPEC.md before planning
  - Tasks must be atomic and independently verifiable
  - Data layer always planned before application layer
  - Tests planned alongside implementation (not after)
  - Observability planned as part of each phase, not bolted on at the end
  - Plan phases must match clean architecture layers

TODO.md format:
  - [ ] TASK-001: [description] (Phase N, depends on: TASK-XXX)
  - [x] TASK-002: [description] (DONE - [date])
  - [~] TASK-003: [description] (IN PROGRESS)
</objective>

<context>
Feature/area to plan: $ARGUMENTS

Flags:
  --breakdown    Show task breakdown only (don't write to files yet)
  --estimate     Include effort sizing (S/M/L/XL) per task
  --dependencies Generate dependency graph
</context>

<execution_context>
@~/.claude/sdlc/workflows/plan.md
@~/.claude/sdlc/references/process.md
@~/.claude/sdlc/references/clean-architecture.md
@~/.claude/sdlc/references/doc-writing-standards.md
@~/.claude/sdlc/workflows/verify.md
</execution_context>

<auto_verify>
When all workflow steps above are complete, immediately run the Phase 7 verification checklist from the verify workflow — without waiting for user instruction. Do not ask. Output the full verification result before finishing.
</auto_verify>

