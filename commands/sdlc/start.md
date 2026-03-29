---
name: sdlc:start
description: Universal entry point — bootstraps new projects, resumes existing work, routes to the right phase. Also accepts: morning, done, save, roadmap, verify, status, help.
argument-hint: "[idea or command] [--auto] [--lightweight] [--emergency] [--intent <type>] [--phase <phase>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Universal SDLC entry point. Handles: new projects, feature additions, bug fixes, daily start/end, status checks, and mid-project navigation.

20-phase lifecycle across 6 tiers:
  ASSESS:   feasibility
  DISCOVER: research → voc → synthesize
  DEFINE:   idea → personas → journey → business-process → prototype
  BUILD:    data-model → design → plan → build
  VERIFY:   test-cases → test-gen → observability → sre → verify → uat
  SHIP:     deploy → maintain → retro

Intent routing: new-project (full lifecycle) | new-feature (idea→deploy) | bug-fix (plan→deploy) | refactor (synthesize→verify) | documentation (idea only)
</objective>

<context>
Input: $ARGUMENTS

Flags:
  --auto            Skip review pauses between phases
  --lightweight     Skip data-model and design phases for small changes
  --emergency       Production incident mode: plan→build→verify→deploy→retro
  --intent <type>   Explicit intent: new-project | new-feature | bug-fix | refactor | documentation
  --phase <phase>   Jump directly to a specific phase
  --force <phase>   Override gate check for named phase (reason required)
</context>

<execution_context>
@~/.claude/sdlc/workflows/orchestrate.md
@~/.claude/sdlc/workflows/workspace-resolution.md
@~/.claude/sdlc/references/process.md
</execution_context>
