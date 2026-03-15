---
name: sdlc:explore
description: >
  Codebase explorer for brownfield projects. Reads CODEBASE_MAP.md first, then executes targeted grep. Answers "where is X", "what calls Y", "what does Z depend on", and "show me all X" without reading entire files.
  AUTO-TRIGGER — invoke this skill when the user asks a question about the existing codebase structure, location, or behaviour.
  Trigger patterns (any of these):
  - Location questions: "where is X handled?", "where is X implemented?", "which file does X?"
  - Caller questions: "what calls X?", "who uses X?", "what depends on X?"
  - Dependency questions: "what does X depend on?", "what does X import?", "what does X use?"
  - Pattern questions: "show me all X", "find all X", "list all X"
  - Convention questions: "how is X done here?", "how are errors handled?", "how is logging done?"
  - Change impact: "if I change X what breaks?", "what uses this field?", "what would be affected by X?"
  - Understanding: "explain what X does", "how does X work?", "walk me through X"
  Do NOT trigger on questions about SDLC phase progress, requirements, or general design discussions.
  Do NOT trigger if .sdlc/CODEBASE_MAP.md does not exist — tell the user to run /sdlc:map first.
argument-hint: "<question about the codebase>"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Edit
---

<objective>
Answer codebase questions with minimal file reads. Strategy: read the map first, grep second, read files last and minimally.

Requires `.sdlc/CODEBASE_MAP.md` to exist. If it does not exist, stop and tell the user to run `/sdlc:map` first.

Query types handled:
- **Location** — "where is payment processing?", "where is auth handled?"
- **Callers** — "what calls OrderService?", "who uses this function?"
- **Dependencies** — "what does UserService depend on?", "what does this module import?"
- **Pattern** — "show me all API endpoints", "find all database queries"
- **Convention** — "how are errors handled here?", "how is logging done?"
- **Change impact** — "if I change this field, what breaks?"
- **Understanding** — "explain what OrderService does"

After answering, offer the most likely follow-up actions. If the exploration reveals something not in CODEBASE_MAP.md, update the map.
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/explore.md
</execution_context>
