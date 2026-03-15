---
name: sdlc:04-customer-journey
description: Define and update customer journeys, personas, emotional maps, and screen flows. Feeds directly into product spec and test case design.
argument-hint: "<persona or journey name> [--new-persona] [--update-flow <name>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

<objective>
Create or update docs/product/CUSTOMER_JOURNEY.md — defining who uses the system, why, and exactly how.

Document structure:
  1. Personas — name, role, goals, frustrations, tech comfort
  2. Journey maps — trigger → steps → outcome, with emotional state per step
  3. Screen/interaction flows — annotated step-by-step flows per persona
  4. Edge cases and failure journeys — what happens when things go wrong
  5. Business process integration — how journey connects to back-office processes
  6. Success metrics — what does a great experience look like, measurably

Principles:
  - Every persona must be grounded in research (reference GAP_ANALYSIS.md)
  - Every journey must have a happy path and at least one failure path
  - Flows must be detailed enough to drive test case design
  - Update existing journeys, never duplicate
</objective>

<context>
Persona or journey: $ARGUMENTS

Flags:
  --new-persona        Add a new persona section
  --update-flow <name> Update a specific named flow
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/customer-journey.md
@/Users/seanlew/.claude/sdlc/references/product-standards.md
</execution_context>

