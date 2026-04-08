---
name: sdlc:release
description: Group completed iterations and fixes into a versioned release. Generates CHANGELOG entry, git tag recommendation.
argument-hint: "[version] [--major] [--minor] [--patch]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - Agent
---

<objective>
Collect all completed ITER-NNN and FIX-NNN manifests, determine or infer a version number, categorize changes by type, generate a CHANGELOG entry in Keep a Changelog format, and mark the included items as released.

Flags:
- `[version]` — explicit version string (e.g., "1.2.0")
- `--major` — bump the major version (breaking changes)
- `--minor` — bump the minor version (new features)
- `--patch` — bump the patch version (fixes only)
- Omit all flags: infer version from change types found
</objective>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/release.md
@/Users/seanlew/.claude/sdlc/workflows/workspace-resolution.md
</execution_context>
