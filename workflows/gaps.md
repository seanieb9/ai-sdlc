# Gaps Workflow

Spawn 3 parallel read-only agents to systematically identify technical debt, architecture drift, and quality gaps across the codebase. Aggregate findings into a unified gap-analysis.md with TD-NNN entries.

---

## Step 0: Workspace Resolution

Execute the workspace resolution procedure from `workspace-resolution.md`. Variables available after this step: `$BRANCH`, `$WORKSPACE`, `$STATE`, `$ARTIFACTS`.

Create the output directory:
```bash
mkdir -p "$ARTIFACTS/gaps"
```

**Parse $ARGUMENTS for focus area** (optional — limits which directories agents analyze).

---

## Step 1: Check Prerequisites

Check if the codebase map exists:
```bash
[ -f ".claude/ai-sdlc/codebase/architecture.md" ] && echo "exists" || echo "missing"
```

If missing:
```
PREREQUISITE NOT MET: Codebase map not found.

ask Claude to run the gaps workflow relies on the codebase map for accurate analysis.

STOP: Run /sdlc:00-start (handles brownfield mapping automatically) first, then re-run ask Claude to run the gaps workflow.
```
**STOP execution.**

If found: read `.claude/ai-sdlc/codebase/architecture.md` to understand the codebase structure before launching agents.

**Also read state.json technicalDebts array** to get the current highest TD-NNN number (to continue sequencing).

---

## Step 2: Determine Scope

If $ARGUMENTS contains a focus area (e.g., "auth", "payments", "data layer"):
- Limit agent scope to files matching that area in the codebase map
- Output: "Focus mode: analyzing <focus area> subsystem only"

Otherwise: analyze the full codebase.

**Set scope variables for agents:**
- `$SCOPE_DIRS`: comma-separated list of directories to analyze (all source dirs, or focus area dirs)
- `$SOURCE_EXTENSIONS`: file extensions for the project's tech stack (from codebase map)

---

## Step 3: Spawn 3 Parallel Gap Analysis Agents

**Important:** All agents are read-only. They must not modify any files.

Launch all 3 agents simultaneously:

---

### Agent 1: Technical Debt Agent

**Mission:** Find technical debt — code quality problems that slow development velocity.

**Instructions for Agent 1:**

Read the codebase map first to understand the structure. Then analyze source files for:

1. **TODO/FIXME/HACK/XXX/TEMP comments:**
   - Grep for: `TODO|FIXME|HACK|XXX|TEMP|BUG|KLUDGE`
   - For each: record file path, line number, comment text, estimated severity

2. **Complex functions (cyclomatic complexity proxy):**
   - Find functions longer than 50 lines
   - Find deeply nested code (> 4 levels of indentation)
   - Find functions with > 5 parameters
   - Grep for long `if-else` chains (> 5 branches in one block)

3. **Large files:**
   - Find source files > 300 lines
   - Find files that appear to have multiple responsibilities (large class with many unrelated methods)

4. **Duplicated logic:**
   - Find repeated code patterns (similar function bodies, copy-pasted blocks)
   - Look for utility functions that exist in multiple places

5. **Dead code:**
   - Find exported functions/classes that are never imported
   - Find commented-out code blocks

**Output format:** A structured list sorted by severity (HIGH/MEDIUM/LOW) with:
- File path and line number(s)
- Category (todo-comment / complex-function / large-file / duplication / dead-code)
- Specific description
- Recommended action

---

### Agent 2: Architecture Drift Agent

**Mission:** Find architecture violations — places where the code deviates from intended structure.

**Instructions for Agent 2:**

Read the codebase map and tech-architecture.md (if present) to understand the intended architecture. Then check for violations:

1. **Wrong-layer dependencies:**
   - Domain/business logic importing from infrastructure (database clients, HTTP clients, message queues)
   - Use cases directly calling external services without a port/interface
   - Grep for infrastructure imports in domain directories

2. **Fat controllers / fat routes:**
   - Request handlers / controllers that contain business logic directly
   - Route files with database queries
   - Check files in `controllers/`, `routes/`, `handlers/`, `api/` for DB client usage

3. **Missing abstractions / interfaces:**
   - External service calls without interface abstractions (makes testing hard)
   - Direct instantiation of infrastructure dependencies in business logic
   - Grep for `new DatabaseClient(`, `new HttpClient(` inside domain/application directories

4. **Domain logic in infrastructure:**
   - Business rules implemented in SQL queries or stored procedures
   - Validation logic inside repository implementations
   - Transformation logic inside serializers/deserializers

5. **Boundary violations:**
   - Cross-module imports that bypass intended bounded contexts
   - Shared mutable state across modules

**Output format:** A structured list with:
- Violation type
- File path and line number
- Severity (CRITICAL/HIGH/MEDIUM/LOW)
- Description of the violation
- Recommended fix

---

### Agent 3: Quality and Coverage Agent

**Mission:** Find quality gaps — missing error handling, hardcoded values, missing observability, security anti-patterns.

**Instructions for Agent 3:**

Analyze source files for:

1. **Missing error handling:**
   - Async operations without try/catch or error handling
   - Unhandled promise rejections (`.then()` without `.catch()`)
   - Functions that can throw but callers don't handle errors
   - HTTP requests without timeout or error handling

2. **Hardcoded values:**
   - Magic numbers (numeric literals not in constants)
   - Hardcoded URLs, hostnames, port numbers in non-config files
   - Hardcoded environment-specific values (staging URLs, dev credentials)

3. **Missing observability:**
   - Code paths without logging (especially error paths, important state transitions)
   - No request ID / correlation ID propagation
   - No timing/duration instrumentation on external calls

4. **Untested code paths:**
   - Error handling blocks with no corresponding test
   - Edge case branches with no test coverage
   - New files added recently (check git log) without test files

5. **Security anti-patterns:**
   - SQL string concatenation (SQL injection risk): `query += ` or `"SELECT * FROM" + `
   - Unvalidated user input passed directly to: file paths, shell commands, eval
   - Logging sensitive data: email, password, token, credit card patterns in log statements
   - Insecure direct object references (using user-supplied IDs without ownership check)

**Output format:** A structured list with:
- Gap type
- File path and line number
- Severity (CRITICAL/HIGH/MEDIUM)
- Description
- Recommendation

---

## Step 4: Collect and Aggregate Agent Results

Wait for all 3 agents to complete. Collect their outputs.

**Severity classification across all findings:**

| Finding Type | Default Severity |
|-------------|-----------------|
| SQL injection / hardcoded credentials | CRITICAL |
| Wrong-layer dependency in domain | HIGH |
| Fat controller with DB access | HIGH |
| Missing error handling on external call | HIGH |
| TODO comment on security/auth logic | HIGH |
| Large file > 500 lines | MEDIUM |
| Complex function > 80 lines | MEDIUM |
| Dead code | LOW |
| TODO comment (general) | LOW |

Assign TD-NNN IDs sequentially to all findings that qualify as actionable technical debt (not just observations). Continue from the highest existing TD-NNN in state.json.

---

## Step 5: Write gap-analysis.md

Write `$ARTIFACTS/gaps/gap-analysis.md`:

```markdown
# Gap Analysis Report
*Generated: <ISO date> | Branch: <$BRANCH> | Scope: <full codebase | focus area>*

## Executive Summary

| Severity | Technical Debt | Architecture Drift | Quality Gaps | Total |
|----------|---------------|-------------------|-------------|-------|
| CRITICAL | N | N | N | N |
| HIGH | N | N | N | N |
| MEDIUM | N | N | N | N |
| LOW | N | N | N | N |
| **Total** | **N** | **N** | **N** | **N** |

Key findings:
- <top 3 most important findings in plain language>

---

## Technical Debt

| TD-ID | Category | File | Line | Description | Severity | Effort |
|-------|----------|------|------|-------------|----------|--------|
<rows>

### Technical Debt Details

#### <TD-ID>: <title>
**Category:** <category>
**File:** `<path>:<line>`
**Severity:** <CRITICAL/HIGH/MEDIUM/LOW>
**Description:** <what the debt is>
**Impact:** <what it costs to leave it>
**Recommendation:** <what to do>
**Effort:** S/M/L

---

## Architecture Drift

| ID | Violation Type | File | Line | Severity | Description |
|----|---------------|------|------|----------|-------------|
<rows>

### Architecture Drift Details

#### <ID>: <title>
**Violation:** <type>
**File:** `<path>:<line>`
**Severity:** <CRITICAL/HIGH/MEDIUM/LOW>
**Description:** <what the violation is>
**Impact:** <why this matters>
**Fix:** <recommended correction>

---

## Quality Gaps

| ID | Gap Type | File | Line | Severity | Description |
|----|----------|------|------|----------|-------------|
<rows>

### Quality Gap Details

#### <ID>: <title>
**Type:** <gap type>
**File:** `<path>:<line>`
**Severity:** <CRITICAL/HIGH/MEDIUM>
**Description:** <what is missing>
**Risk:** <what can go wrong>
**Recommendation:** <what to add>

---

## Priority Remediation Plan

Top 10 items ordered by: (Severity × Business Impact) / Effort

| Priority | ID | Action | Effort | Severity | Owner |
|----------|----|--------|--------|----------|-------|
| 1 | <TD/drift/gap-ID> | <action> | S/M/L | CRITICAL/HIGH | <team/person> |
...

Estimated total effort for all CRITICAL + HIGH items: <S/M/L/XL>
```

---

## Step 6: Update state.json

For each HIGH or CRITICAL technical debt item, append to the `technicalDebts` array in state.json:

```json
{
  "id": "TD-NNN",
  "description": "<description>",
  "severity": "<CRITICAL|HIGH>",
  "file": "<path:line>",
  "category": "<debt category>",
  "phaseCreated": "gaps",
  "status": "open",
  "recommendation": "<recommended action>",
  "createdAt": "<ISO timestamp>"
}
```

Update `updatedAt`.

---

## Step 7: Final Output

```
GAPS Analysis Complete

Findings:
  CRITICAL: <N> items
  HIGH:     <N> items
  MEDIUM:   <N> items
  LOW:      <N> items

  Technical Debt:     <N> items (TD-NNN to TD-NNN added to register)
  Architecture Drift: <N> violations
  Quality Gaps:       <N> gaps

Artifact: $ARTIFACTS/gaps/gap-analysis.md

Top 3 priorities:
  1. [CRITICAL] <description> — <file>
  2. [HIGH]     <description> — <file>
  3. [HIGH]     <description> — <file>

Next:
  Run ask Claude to run the debt workflow to view and manage the full technical debt register.
  Run /sdlc:fix --maintenance to address debt items.
  Run ask Claude to re-run the assess workflow for a readiness score to track improvement over time.
```
