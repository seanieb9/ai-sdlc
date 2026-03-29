# Release Workflow

Collects completed ITER-NNN and FIX-NNN manifests, determines the next version, categorizes changes, generates a CHANGELOG.md entry in Keep a Changelog format, and marks the included manifests as released.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

---

## Step 1: Collect Completed Iterations and Fixes

**Find all manifests:**
```bash
ls .claude/ai-sdlc/ITERATIONS/ITER-*.md 2>/dev/null | sort
ls .claude/ai-sdlc/ITERATIONS/FIX-*.md 2>/dev/null | sort
```

Read each manifest file. Identify those with `Status: completed` and `Status: released` (already released items are excluded from this release).

**Filter to unreleased completed items:**
- Include: `Status: completed`
- Exclude: `Status: released`, `Status: in-progress`, `Status: pending`

**If no completed unreleased items exist:**
Output: "No completed unreleased iterations or fixes found. Complete at least one /sdlc:iterate or /sdlc:fix before releasing."
STOP.

**Build the release inventory:**

| ID | Type | Description | Breaking Change | Hotfix |
|----|------|-------------|----------------|--------|
<one row per item>

Display this table to the user before proceeding.

---

## Step 2: Determine Version

**Parse $ARGUMENTS** for an explicit version string (e.g., "1.2.0", "2.0.0-beta.1").

**If explicit version in $ARGUMENTS:** use it. Validate semver format (MAJOR.MINOR.PATCH). If invalid: warn and ask user to correct.

**If --major, --minor, or --patch flag:** read current version, then increment accordingly.

**Read current version from (in priority order):**
1. `package.json` → `.version` field
2. `pyproject.toml` → `[tool.poetry] version` or `[project] version`
3. `Cargo.toml` → `[package] version`
4. `.claude/ai-sdlc/workflows/$BRANCH/state.json` → `.releaseVersion` field (if present)
5. CHANGELOG.md → parse the most recent `## [X.Y.Z]` heading
6. If none found: assume current version is `0.0.0`

**If no flags and no explicit version:** infer from the change inventory:
- Any `Breaking Change: true` → MAJOR bump (unless currently at 0.x.x, then MINOR)
- Any ITER with `type: new` or `type: enhancement` → MINOR bump
- Only FIX items and ITER with `type: nfr` or `type: data` → PATCH bump

**Display version decision:**
```
Current version: <X.Y.Z or "not found — starting at 0.1.0">
Proposed version: <X.Y.Z>
Reason: <explicit | --major/--minor/--patch | inferred from changes>
```

Use AskUserQuestion: "Proceed with version <X.Y.Z>? Or enter a different version:"

---

## Step 3: Categorize Changes

Organize the unreleased completed items into Keep a Changelog categories:

**Breaking Changes** (show only if any `Breaking Change: true`):
- All ITER items with `Breaking Change: true`

**Added** (new capabilities):
- ITER items with `Type: new`

**Changed** (enhancements to existing):
- ITER items with `Type: enhancement`
- ITER items with `Type: ux`
- ITER items with `Type: data`

**Performance** (non-functional improvements):
- ITER items with `Type: nfr`

**Fixed** (bug fixes):
- All FIX items with `Type: bug-fix`
- All FIX items with `Type: maintenance`

**Security** (security-related fixes):
- FIX items whose description contains keywords: security, auth, vulnerability, CVE, XSS, injection, exposure, credential

**Hotfixes** (emergency production fixes):
- All FIX items with `Hotfix: true`

---

## Step 4: Generate CHANGELOG Entry

Compose the CHANGELOG entry in strict Keep a Changelog format:

```markdown
## [<VERSION>] - <YYYY-MM-DD>

### Breaking Changes
- <description> (<ITER-NNN>)

### Added
- <description> (<ITER-NNN>)

### Changed
- <description> (<ITER-NNN>)

### Performance
- <description> (<ITER-NNN>)

### Fixed
- <description> (<FIX-NNN>)

### Security
- <description> (<FIX-NNN>)

### Hotfixes
- <description> [HOTFIX] (<FIX-NNN>)
```

Rules:
- Omit any section that has no entries
- Each line is one sentence in the past tense describing what changed from the user's perspective
- Include the manifest ID in parentheses at the end of each line
- Do not include internal implementation details — write as a user-facing changelog

**Display the composed entry to the user for review.**

---

## Step 5: Git Tag Recommendation

Generate the recommended git commands:

```
Recommended git tag commands:
  git tag -a v<VERSION> -m "Release v<VERSION>"
  git push origin v<VERSION>

Or if tagging a specific commit:
  git tag -a v<VERSION> <commit-sha> -m "Release v<VERSION>"
```

For hotfix releases, also show:
```
If this is a hotfix on a release branch:
  git checkout <release-branch>
  git cherry-pick <fix-commit-sha>
  git tag -a v<VERSION> -m "Hotfix release v<VERSION>"
```

---

## Step 6: Write CHANGELOG.md

Use AskUserQuestion: "Write this changelog entry to CHANGELOG.md? (yes/no)"

If yes:
- Check if CHANGELOG.md exists
- If CHANGELOG.md does not exist: create it with the standard header:
  ```markdown
  # Changelog

  All notable changes to this project will be documented in this file.

  The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
  and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

  ```
- If CHANGELOG.md exists: read it, then insert the new entry immediately after the header (before any existing `## [x.y.z]` section)

**Write the updated CHANGELOG.md.**

---

## Step 7: Update Release Version in State

Update state.json:
- Set `releaseVersion: "<VERSION>"`
- Set `lastReleasedAt: "<ISO timestamp>"`
- Update `updatedAt`

---

## Step 8: Mark Items as Released

For each ITER-NNN.md and FIX-NNN.md included in this release:
- Change `Status: completed` → `Status: released`
- Add `Released: <VERSION>` field
- Add `ReleasedAt: <ISO timestamp>` field

---

## Step 9: Final Output

```
Release v<VERSION> Complete

Included:
  ITER items: <count> (<list of IDs>)
  FIX items:  <count> (<list of IDs>)
  Breaking changes: <yes/no>

CHANGELOG.md: <updated | skipped>

Git tag:
  git tag -a v<VERSION> -m "Release v<VERSION>"
  git push origin v<VERSION>

Next:
  Run the git tag command above to create the version tag.
  Deploy per your deployment workflow.
  Run /sdlc:start or /sdlc:iterate to begin the next iteration.
```
