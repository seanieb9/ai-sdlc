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

## What NOT to Plan

- **Don't estimate AI execution time** — it's not a bottleneck
- **Don't assign story points to code tasks** — the tasks exist for tracking, not for estimating
- **Don't plan sprints around code phases** — code completes when the AI finishes, not when a sprint ends
- **Don't create tickets for AI work** — AI tasks live in `.sdlc/TODO.md`, not a project management tool
- **Do plan around human review cycles** — the cadence is: human designs → AI executes → human reviews → next phase
