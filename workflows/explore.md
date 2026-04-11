# Explore Workflow

Answer "where is X", "what calls Y", "what does Z depend on", and "show me all X" questions about the codebase — without reading entire files.

Strategy: **read the map first, grep second, read files last and minimally.** The CODEBASE_MAP.md is the index — use it to narrow scope before touching source code.

---

## Step 1: Read the Map

Read `.claude/ai-sdlc/codebase/architecture.md` in full.

If it does not exist: stop and tell the user to run /sdlc:00-start (handles brownfield mapping automatically) first. The explore command requires the map.

From the map, extract:
- Architecture pattern and layer locations
- Domain concept → file mappings
- Search recipes section (project-specific grep patterns)
- Hotspot files to be aware of

---

## Step 2: Classify the Query

Classify the user's question into a query type — this determines the search strategy:

| Query type | Examples | Strategy |
|-----------|---------|---------|
| **Location** | "where is payment processing?", "where is auth handled?" | Use domain map + grep for class/function names |
| **Callers** | "what calls OrderService?", "who uses this function?" | Grep for the symbol name across source files |
| **Dependencies** | "what does UserService depend on?", "what does this module import?" | Read the specific file's imports |
| **Pattern** | "show me all API endpoints", "find all database queries" | Use search recipes from map |
| **Convention** | "how are errors handled here?", "how is logging done?" | Read cross-cutting concerns section from map, spot-read 1-2 examples |
| **Change impact** | "if I change this field, what breaks?" | Grep for all usages, check API routes + tests |
| **Understanding** | "explain what OrderService does" | Read the specific file + its direct dependencies only |

---

## Step 3: Execute Targeted Search

Based on the query type, run the minimum searches needed:

**For Location queries:**
1. Check domain concepts table in CODEBASE_MAP.md — may already have the answer
2. If not: grep for the concept name across source dirs
   ```bash
   grep -rn "<concept>" src/ --include="*.ts" | grep -v ".test." | head -20
   ```
3. Return file:line references

**For Caller queries:**
```bash
grep -rn "<SymbolName>" src/ --include="*.ts" --include="*.js" \
  | grep -v "class <SymbolName>\|interface <SymbolName>" \
  | grep -v ".test." | head -30
```

**For Dependency queries:**
Read only the target file's import section (first 30 lines usually):
```bash
head -40 <target-file>
```

**For Pattern queries:**
Use the search recipes from CODEBASE_MAP.md directly — these are already tailored to this project.

**For Convention queries:**
Read 1-2 representative examples of the convention in action (short reads, top of file only if possible).

**For Change impact queries:**
```bash
# Find all usages of the symbol
grep -rn "<symbol>" src/ --include="*.ts" | grep -v ".test." | head -30
# Find test coverage
grep -rn "<symbol>" src/ --include="*.test.ts" | head -15
# Find API exposure
grep -rn "<symbol>" src/ --include="*.ts" | grep -i "controller\|route\|handler" | head -10
```

**For Understanding queries:**
1. Read the file (the specific one from the map, not exploratory)
2. Identify its direct imports
3. Read only the imported files that are internal (not third-party)
4. Stop after 2 levels of depth — don't recurse into the whole tree

---

## Step 4: Synthesise the Answer

Answer the question directly with:
- The specific file(s) and line numbers
- A brief explanation of what's happening there
- Any cross-references that are immediately relevant (e.g. "this calls X which lives at Y")
- If it's a convention question: a concrete example from the actual code

**Do not:**
- Read files speculatively "just to check"
- Return raw grep output without explanation
- Read test files when answering about production code (unless the question is about tests)
- Recurse into third-party library code

---

## Step 5: Offer Follow-Up

After answering, offer the most likely follow-up:

```
Answer: [precise answer with file:line refs]

Related:
• To see callers: ask Claude your codebase question directly "what calls [X]"
• To see full context: read [file]:[line range]
• To understand dependencies: ask Claude your codebase question directly "what does [X] depend on"
```

---

## Step 6: Update Map if New Knowledge Found

If the exploration revealed something not in `.claude/ai-sdlc/codebase/architecture.md` (e.g. a pattern, a hidden dependency, a convention):

Add it to the relevant section of `.claude/ai-sdlc/codebase/architecture.md` immediately so it's there for next time.

Example: if you found that auth is actually checked in 3 different places, not 1, update the Cross-Cutting Concerns section.
