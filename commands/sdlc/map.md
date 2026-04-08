---
name: sdlc:map
description: Brownfield codebase mapper. Runs a structured analysis of the existing codebase and writes .sdlc/CODEBASE_MAP.md — a persistent, version-controlled index used by /sdlc:explore, /sdlc:02-synthesize, and the orchestrator.
argument-hint: "[--refresh] [--focus <area>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

<objective>
Analyse the existing codebase and write `.sdlc/CODEBASE_MAP.md` — a structured index that replaces the need for code indexing, dependency graphs, and semantic search tools. The map is the foundation for all brownfield work: synthesize reads it, explore uses it, and the orchestrator loads it on startup.

Flags:
- `--refresh` — re-run the full analysis even if CODEBASE_MAP.md already exists
- `--focus <area>` — limit analysis to a specific area (e.g. `--focus auth`, `--focus payments`)

On completion, update `.sdlc/STATE.md` to record that the codebase has been mapped.
</objective>

<execution_context>
@~/.claude/sdlc/workflows/map.md
@~/.claude/sdlc/references/doc-writing-standards.md
</execution_context>
