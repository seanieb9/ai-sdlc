# Roadmap Workflow

Generate a human-effort roadmap for an agentic development project. The planning unit is the Human Session (HS) — not story points. The scarce resource is human judgment and attention, not coding hours.

---

## Step 1: Read Project Context

Read in parallel:
- `.sdlc/STATE.md` — project name, type, description, constraints
- `.sdlc/ROADMAP.md` — if exists, this is an update, not a fresh generation

If STATE.md does not exist: tell the user to run `/sdlc:00-start` first to initialise the project before creating a roadmap.

---

## Step 2: Gather Team Setup

Ask the user (AskUserQuestion) — these are the only questions needed:

1. **Team setup:**
   > "Is this a solo project or a microsquad?"
   > If microsquad: "How many engineers? (typically 1 Tech Lead + 1–2 engineers) and is there a BA / Product Lead separate from the engineers?"
   > If 1 BA + 2 engineers: generate parallel thread view (BA thread: phases 1–4, 9, 13; Eng thread: phases 5–8, 11–12) and note that after Phase 3 both threads can run simultaneously.
   > If solo: note that all phases belong to one person and sync points become personal checkpoints.

2. **Session availability:**
   > "How many human sessions can the team commit per week? A session is a focused 60–90 min block of work."
   > If unsure: suggest 2–3 Design sessions + 1 Review session per week as a baseline.

3. **Hard deadline:**
   > "Is there a target completion date or milestone? (or 'no hard deadline')"

4. **Complexity adjustments** (optional — offer only if the project description suggests non-standard scope):
   > "Any phases that will be significantly larger or smaller than default? E.g., very complex data model, skipping VoC, simplified SRE."

---

## Step 3: Calculate Phase Plan

Using the default session estimates from planning-standards.md, adjusted by any complexity inputs from Step 2:

For each phase:
- Assign ownership (Product Lead / Tech Lead / Both / AI)
- Set autonomy level (🤖 Autonomous / 👁 Supervised / ✍ Collaborative / 👥 Human-led)
- Set session estimate (D for Design, R for Review)
- Mark phase gates (⚠️ hard gates, sync points)

Apply complexity adjustments:
- `--skip-voc`: remove Phase 1b from the plan, note it as skipped
- `--simple-sre`: reduce Phase 12 to 0.5D
- `--large-data-model`: increase Phase 5 to 3–4D
- Large number of integrations: increase Phase 6 to 4–5D
- First time in this domain: add 1D to Phase 3 and Phase 5

---

## Step 4: Identify Critical Path

The critical path is always:
```
Phase 3 (Product Spec) → Phase 5 (Data Model) → Phase 6 (Tech Arch) → Phase 8 (Code)
```

Flag the highest-risk gate based on project type:
- Most projects: Phase 5 (Data Model) — wrong model propagates everywhere
- Integration-heavy projects: Phase 6 (Tech Arch) — dependency classification is critical
- Customer-facing products: Phase 3 (Product Spec) — requirement gaps surface late

---

## Step 5: Calculate Effort Summary

Sum all sessions:
- Total Design sessions (D)
- Total Review sessions (R)
- Total Sync points (always 4 for microsquad, 0 for solo)
- Calendar estimate: total D + (R × 0.5) ÷ sessions per week = weeks

Show the distribution:
- Front-half (phases 1–6): what % of total sessions
- Back-half (phases 7–13): what % of total sessions

If front-half < 70% of total: flag this — design phases are being under-invested. The typical distribution is ~80% front, ~20% back.

---

## Step 6: Write ROADMAP.md

Write `.sdlc/ROADMAP.md` using the roadmap template.

Fill in:
- Team section with actual names/roles
- Phase plan with adjusted estimates
- Critical path with project-specific risk note
- Sync points with dates if target completion date was provided
- Effort summary with calendar projection
- Phase log initialised to all ⬜ Not started

If ROADMAP.md already exists (update mode):
- Preserve Phase Log entries
- Update session estimates if changed
- Add a change entry at the bottom of the file with date and reason

---

## Step 7: Update STATE.md

Add to `.sdlc/STATE.md`:
```
## Roadmap
- Team: [Solo | Microsquad — Product: X, Tech: Y]
- Total sessions: [N]D + [N]R
- Sessions/week: [N]
- Target: [date or continuous]
- Last updated: [date]
```

---

## Step 8: Output Summary

Show the user:
```
✅ Roadmap Created: .sdlc/ROADMAP.md

Team:        [Solo | Product: X / Tech: Y]
Effort:      [N]D + [N]R = ~[N] weeks at [N] sessions/week
Critical:    Phase 5 (Data Model) — [risk note]
AI phases:   Phase 8 (Code) and Phase 10 (Test Automation) run autonomously

Next sync:   S1 after Phase 2 (Synthesize)

Note: Update the roadmap as phases complete with /sdlc:roadmap --update
```

---

## Flags

- `--update` — refresh an existing roadmap (preserves phase log, recalculates from current STATE.md)
- `--skip-voc` — exclude Phase 1b from the plan
- `--solo` — force solo mode regardless of team input
- `--simple` — use minimum session estimates for all phases (speed-optimised)
- `--thorough` — use maximum session estimates (quality-optimised)
