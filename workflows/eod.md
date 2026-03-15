# End of Day Workflow

Wrap up the session cleanly. The goal is to leave the project in a known, committed, resumable state so tomorrow starts in seconds — not with archaeology.

---

## Step 1: Read Current State

Read in parallel:
- `.sdlc/NEXT_ACTION.md` — current checkpoint (if any)
- `.sdlc/STATE.md` — phase progress
- `.sdlc/TODO.md` — task list
- Git status: `git status --short` and `git diff --stat HEAD`

---

## Step 2: Reach a Clean Stopping Point

Before saving anything, check:

**Are any tasks left in a broken state?**
- If a file is mid-edit and doesn't compile or has syntax errors → fix it or revert it
- If a use case is half-implemented and would break dependent code → stub it out cleanly (compile-safe)
- Never leave code in a state where `TODO: finish this` is the only thing keeping it together

**Is there a natural stopping point nearby?**
- If 80% through a task: consider finishing it (15 more minutes > a confusing half-done state)
- If just started a large task: consider stopping and committing the prior completed state instead
- Rule: stop at the end of a complete thought, not mid-thought

---

## Step 3: Commit Work in Progress

Check git status. For any modified or new files:

1. Review what changed: `git diff --stat HEAD`
2. Stage relevant files (not temp files, not `.env`)
3. Commit with a clear message describing what's complete — not what's next

Good EOD commit message format:
```
[phase] implement [what was completed]

- [specific thing done]
- [specific thing done]
- Stopped at: [where you are, e.g. "ShortenUrlUseCase done, RedirectUseCase next"]
```

If nothing is worth committing (pure exploration, notes, scratch work): that's fine — say so explicitly in the checkpoint.

---

## Step 4: Save Checkpoint

Run the checkpoint workflow (same as `/sdlc:checkpoint`) with EOD-specific additions:

Write `.sdlc/NEXT_ACTION.md` with:
- Current phase and exact step
- What was completed today (not just the session — frame it as a daily summary)
- The single first action for tomorrow morning
- Any open decisions that need resolving
- Anything discussed verbally that isn't in the documents
- **EOD-specific:** any blockers or dependencies that tomorrow's work depends on

---

## Step 5: Produce EOD Summary

Print the end-of-day summary:

```
╔══════════════════════════════════════════════════════╗
║  END OF DAY: [Project Name]                          ║
║  [date]                                              ║
╠══════════════════════════════════════════════════════╣
║  TODAY'S PROGRESS                                    ║
║  Phase [N]: [Phase Name] — [step reached]            ║
║  Tasks completed: [N]                                ║
║  [bullet list of what was done today]                ║
╠══════════════════════════════════════════════════════╣
║  COMMITTED                                           ║
║  [commit hash + message, or "nothing committed"]     ║
╠══════════════════════════════════════════════════════╣
║  FIRST ACTION TOMORROW                               ║
║  [exact command to run]                              ║
║  [what it will do]                                   ║
╠══════════════════════════════════════════════════════╣
║  BLOCKERS / WATCH OUT FOR                            ║
║  [anything that needs resolving before work can      ║
║   continue — or "None"]                              ║
╠══════════════════════════════════════════════════════╣
║  OPEN DECISIONS                                      ║
║  [unresolved decisions — or "None"]                  ║
╚══════════════════════════════════════════════════════╝

Checkpoint saved → .sdlc/NEXT_ACTION.md
Run /sdlc:sod tomorrow to start your session.
```

---

## Step 6: Update STATE.md

Append to `## Checkpoint Log`:
```
[date] EOD: Phase [N] Step [X] — [what was completed today] → Tomorrow: [first command]
```
