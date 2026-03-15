# Agentic Planning Standards

## The Fundamental Shift

Traditional planning measures **coding effort** because developers write every line manually. In agentic development, coding is largely automated. The scarce resource is **human judgment and attention** — not coding hours.

This means:
- Story points are the wrong unit (they measure what AI now does)
- Sprint velocity is the wrong metric (AI velocity is near-constant)
- The planning question is not "how many lines of code" but "how many human decisions"

The right unit is the **Human Session (HS)**: a focused block of human work.

---

## Human Session Types

| Type | Symbol | Duration | Definition |
|------|--------|----------|------------|
| **Design** | D | 60–90 min | Human drives, AI assists. Creative, judgment-heavy work. Requires full attention. |
| **Review** | R | 30–45 min | AI ran, human validates output, approves or redirects. Can be async. |
| **Sync** | S | 30 min | Microsquad alignment — phase handoff, blocker resolution, decision agreement. |

A session is not a time estimate — it is a unit of **focused human engagement**. One Design session means one block of uninterrupted thinking, not necessarily one hour.

---

## AI Autonomy Levels

Every SDLC phase has a natural autonomy level. This determines whether a human needs to be present or can review asynchronously.

| Level | Symbol | Meaning | Human role |
|-------|--------|---------|------------|
| **Autonomous** | 🤖 | AI runs completely unattended | None during execution — review output when done |
| **Supervised** | 👁 | AI runs, human monitors and may redirect | Light presence — check in, not drive |
| **Collaborative** | ✍ | Human drives, AI drafts and challenges | Active — this is Design Session territory |
| **Human-led** | 👥 | Primarily human work, AI supports | Full attention — AI cannot substitute judgment here |

### Default autonomy by phase

| Phase | Autonomy | Reason |
|-------|----------|--------|
| 1. Research | 👁 Supervised | AI can research, but human must validate relevance and quality |
| 1b. VoC | 👥 Human-led | Requires real customer conversations — AI cannot invent primary data |
| 2. Synthesize | 👁 Supervised | AI synthesises, human reviews strategic framing |
| 3. Product Spec | ✍ Collaborative | Requirements require human product judgment — what to build and why |
| 3b. Personas | ✍ Collaborative | Personas require real customer knowledge to ground |
| 4. Customer Journey | ✍ Collaborative | Empathy and UX judgment — human-driven |
| 5. Data Model | ✍ Collaborative | Architectural data decisions have long-term consequences |
| 6. Tech Architecture | ✍ Collaborative | ADRs and design decisions require human accountability |
| 7. Plan | 👁 Supervised | AI breaks down tasks, human validates ordering and risk |
| 8. Code | 🤖 Autonomous | AI implements to plan — human reviews at completion |
| 9. Test Cases | 👁 Supervised | AI derives tests, human checks coverage completeness |
| 10. Test Automation | 🤖 Autonomous | AI writes scripts — human runs and reviews |
| 11. Observability | 👁 Supervised | AI generates spec, human validates thresholds and OBS-IDs |
| 12. SRE | ✍ Collaborative | SLOs and runbooks require operational judgment |
| 13. Review | ✍ Collaborative | Quality gate — human judgment on acceptability |

---

## Default Session Estimates

These are starting estimates. Adjust based on project complexity.

| Phase | Default | Range | Scaling factors |
|-------|---------|-------|----------------|
| 1. Research | 1R | 0.5–2R | More R if domain is unfamiliar |
| 1b. VoC | 2D | 1–4D | Scales with amount of primary data to synthesise |
| 2. Synthesize | 0.5R | 0.5–1R | Flat — AI does the work |
| 3. Product Spec | 3D | 2–6D | Scales with feature complexity and stakeholder count |
| 3b. Personas | 1D | 1–2D | More if no prior customer research exists |
| 4. Customer Journey | 2D | 1–3D | More if multiple personas with divergent journeys |
| 5. Data Model | 2D | 1–4D | Scales with domain complexity and entity count |
| 6. Tech Architecture | 3D | 2–5D | More for distributed systems, integrations, or novel patterns |
| 7. Plan | 0.5R | 0.5R | Flat — AI breaks it down, human spot-checks |
| 8. Code | 0 | 0 | AI autonomous |
| 9. Test Cases | 0.5R | 0.5–1R | More if 8-layer coverage is sparse |
| 10. Test Automation | 0 | 0 | AI autonomous |
| 11. Observability | 0.5R | 0.5R | Flat |
| 12. SRE | 1D | 0.5–2D | More for high-availability or compliance-driven systems |
| 13. Review | 1.5D | 1–3D | Scales with finding severity from earlier phases |

**Default total: ~16D + ~3R + syncs**

The front-half of the lifecycle (phases 1–6) accounts for ~80% of human session cost. This is by design — poor decisions here propagate through everything downstream.

---

## Microsquad Ownership Model

A microsquad is 2–3 people with blurred roles. Default ownership split:

| Role | Default phases | Can delegate to |
|------|---------------|----------------|
| **Product Lead** | 1, 1b, 2, 3, 3b, 4 | Tech Lead for domain research |
| **Tech Lead** | 5, 6, 7, 11, 12 | Product Lead for plan review |
| **Both** | Phase gates (verify), 13 (final review) | — |
| **Neither (AI)** | 8, 10 | Monitor only |

For solo developers: all roles belong to one person. Sync points become personal reflection checkpoints. Use the session estimates as personal time planning.

---

## Sync Points

Sync points are mandatory microsquad alignments at phase handoffs. They prevent the product and tech threads from diverging.

| Sync | Trigger | Duration | Agenda |
|------|---------|----------|--------|
| S1 | After Phase 2 (Synthesize) | 30 min | Align on strategic picture before spec work splits the team |
| S2 | After Phase 4 (Customer Journey) | 45 min | Product Lead hands off to Tech Lead — journey → data model handoff |
| S3 | After Phase 6 (Tech Architecture) | 30 min | Architecture confirmed, unblock code phase |
| S4 | After Phase 13 (Review) | 30 min | Final sign-off, production readiness decision |

Skip a sync only if both roles are the same person (solo developer).

---

## Critical Path

The critical path in agentic development is always through the design phases — not the code.

```
Product Spec (Phase 3)
  └─→ Data Model (Phase 5)   ← highest-risk gate
        └─→ Tech Architecture (Phase 6)
              └─→ Code (Phase 8)   ← AI autonomous from here
```

**The data model is the highest-risk gate.** A wrong data model invalidates architecture decisions and forces code rewrites. More Design sessions here is always the right trade-off.

**The product spec is the highest-leverage phase.** Every requirement left vague here becomes a decision made during coding — by AI, without human judgment.

---

## Project Sizing

Use these as rough calibration points:

| Project type | Design Sessions | Review Sessions | Calendar (2D/week) |
|-------------|----------------|----------------|-------------------|
| Single feature | 8–12D | 2–3R | 4–6 weeks |
| New service | 15–20D | 3–4R | 8–10 weeks |
| Platform / major product | 25–35D | 5–6R | 13–18 weeks |

These are **human effort** estimates. AI execution time is additive but not a planning constraint — Claude runs overnight, on weekends, in parallel.

---

## Microsquad Collaboration Protocol (1 BA + 2 Engineers)

### The sync mechanism: Git

All `.sdlc/` and `docs/` files live in the git repository. Git is the only sync layer needed — no external project management tool required.

**Three rules:**
1. `git pull` before every session
2. `git push` after every phase verification passes
3. Never edit a file that another person is actively working on this session

---

### Phase threading: BA and engineers can work in parallel

Design phases are single-owner. But after Phase 3 (Product Spec) completes, the BA thread and engineering thread write to **different files** and can run simultaneously:

```
Phase 3: Product Spec  (BA — completes, pushes)
    │
    ├── BA thread (continues):
    │     Phase 3b: Personas      → PERSONAS.md
    │     Phase 4:  Journey       → CUSTOMER_JOURNEY.md
    │     (free during Phase 8)
    │     Phase 9:  Test Cases    → TEST_CASES.md (review)
    │     Phase 13: Review        → REVIEW_REPORT.md
    │
    └── Engineering thread (starts after Phase 3 push):
          Phase 5:  Data Model    → DATA_MODEL.md, DATA_DICTIONARY.md
          Phase 6:  Tech Arch     → TECH_ARCHITECTURE.md, API_SPEC.md, SOLUTION_DESIGN.md
          Phase 7:  Plan          → PLAN.md, TODO.md (assigns tasks to both engineers)
          Phase 8:  Code          → source code (both engineers, task-assigned)
          Phase 11: Observability → OBSERVABILITY.md
          Phase 12: SRE           → RUNBOOKS.md, SLO.md
```

No file conflicts during parallel operation — each thread owns distinct documents.

---

### Handoff protocol

A handoff is: **verify passes → commit → push → notify → other person pulls**.

| Handoff | After | Who → Who | Signal |
|---------|-------|----------|--------|
| H1 | Phase 2 (Synthesize) | BA → Eng (awareness) | Push SYNTHESIS.md — engineers read before Phase 5 |
| H2 | Phase 3 (Product Spec) | BA → Eng (unblocks) | Push PRODUCT_SPEC.md — engineers can start Phase 5 |
| H3 | Phase 6 (Tech Arch) | Eng → BA (rejoins) | Push arch docs — BA reviews before Phase 9 |
| H4 | Phase 7 (Plan) | Tech Lead → Both engineers | Push PLAN.md + TODO.md — code phase begins |
| H5 | Phase 8 (Code) | Both engineers → verify | All TODO [x] — run verify, BA rejoins |
| H6 | Phase 13 (Review) | Both | Final sign-off, push REVIEW_REPORT.md |

Notification is a message (Slack, chat, in-person): *"Phase N verified and pushed. Pull when ready."*

---

### TODO.md task assignment for two engineers

During Phase 7 (Plan), the Tech Lead assigns every code task to one of the two engineers in `TODO.md`.

**Task format with assignee:**
```
- [ ] TASK-NNN: [description] | [S/M/L] | @[assignee] | depends: [TASK-IDs or none]
```

**Assignee values:**
- `@eng1`, `@eng2` — assigned to a specific engineer
- `@unassigned` — either engineer can pick it up

**Rules:**
- Only pick up tasks assigned to you or `@unassigned`
- When you start a task: change `[ ]` to `[~]` and push **immediately** — this is a live lock
- When done: change `[~]` to `[x]` and push
- Never work on the same TASK-ID as the other engineer simultaneously

**Layer ordering as the primary conflict-prevention mechanism:**
The clean architecture layer sequence (data → domain → application → infrastructure → delivery) means lower layers are prerequisites for upper layers. Both engineers can parallelize within the same layer only if their tasks touch different files.

---

### The in-progress flag `[~]`

```
[ ]  = not started
[~]  = I am working on this right now — push this change immediately on pickup
[x]  = done
```

The `[~]` flag is a **live signal**, not just a status. The protocol:
1. Pick up a task → immediately change `[ ]` to `[~]` in TODO.md → `git push`
2. The other engineer sees `[~]` when they pull → skips that task → picks the next available
3. Complete → change `[~]` to `[x]` → `git push`

If two engineers accidentally pick up the same task (both see `[ ]` before either pushes): the second engineer to push resolves by picking a different task. No lost work — both implementations should be reviewed, the better one kept.

---

### BA role during Phase 8 (Code)

Phase 8 is AI-autonomous. The BA has no blocking tasks. Recommended use of this window:

| Activity | Benefit |
|----------|---------|
| Prepare test scenario inputs for Phase 9 | Reduces Phase 9 Design session time |
| Review committed code (non-blocking) | Catches requirement mismatches early |
| Answer requirement questions from engineers | Unblocks faster than async back-and-forth |
| Draft acceptance criteria for Phase 13 | Pre-work for final review |

The BA is **available** during Phase 8, not idle. Engineers can pull the BA into a quick session if a requirement is ambiguous — this is far cheaper than discovering the misunderstanding at Phase 13.

---

### Tech Lead vs second engineer responsibilities

| Responsibility | Tech Lead | Second Engineer |
|---------------|-----------|----------------|
| Phase 5 (Data Model) | Leads — drives decisions | Reviews, challenges |
| Phase 6 (Tech Arch) | Leads — writes ADRs | Reviews, raises concerns |
| Phase 7 (Plan) | Owns — creates PLAN.md + assigns tasks | Reviews task breakdown |
| Phase 8 (Code) | Works assigned tasks | Works assigned tasks |
| Phase 11 (Observability) | Leads | Reviews |
| Phase 12 (SRE) | Leads | Reviews |

Both engineers run `/sdlc:verify` after their respective phases. Both have equal authority to raise blockers at any phase gate.

---

- **Don't estimate AI execution time** — it's not a bottleneck
- **Don't assign story points to code tasks** — the tasks exist for tracking, not for estimating
- **Don't plan sprints around code phases** — code completes when the AI finishes, not when a sprint ends
- **Don't create tickets for AI work** — AI tasks live in `.sdlc/TODO.md`, not a project management tool
- **Do plan around human review cycles** — the cadence is: human designs → AI executes → human reviews → next phase
