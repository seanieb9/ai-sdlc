---
name: sdlc:debt
description: View and manage the technical debt register — list TD-IDs, add new items, export to markdown.
argument-hint: "[--add <description>] [--resolve <TD-ID>] [--export]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

<objective>
View, add, resolve, and export technical debt items from the state.json technicalDebts register. Provides a clean table view by default and supports inline mutations.

Flags:
- `--add <description>` — add a new technical debt item (will prompt for severity and recommendation)
- `--resolve <TD-ID>` — mark a debt item as resolved
- `--export` — write the full register to $ARTIFACTS/maintain/debt-register.md
</objective>

<execution_context>
@~/.claude/sdlc/workflows/debt.md
@~/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
