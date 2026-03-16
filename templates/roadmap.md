# Project Roadmap: [Project Name]
*Last Updated: [ISO date] | Team: [Solo | Microsquad] | Target: [date or Continuous]*

## TL;DR
- Total human effort: [N]D + [N]R + [N] Syncs
- Critical path: Product Spec → Data Model → Tech Architecture → Code
- Highest-risk gate: Phase 5 (Data Model)
- AI-autonomous phases: Phase 8 (Code), Phase 10 (Test Automation)
- Next sync point: [S1 after Phase 2 | current sync name]

## Contents
- [Team](#team)
- [Phase Plan](#phase-plan)
- [Critical Path](#critical-path)
- [Sync Points](#sync-points)
- [Effort Summary](#effort-summary)
- [Phase Log](#phase-log)

---

## Team

| Role | Owner | Phases |
|------|-------|--------|
| Product Lead | [name or "solo"] | 1, 1b, 2, 3, 3b, 4 |
| Tech Lead | [name or "solo"] | 5, 6, 7, 11, 12 |
| Both | | Phase gates, 13 |
| AI (autonomous) | — | 8, 10 |

Available sessions: [N Design + N Review per week]
Target completion: [date or "no hard deadline"]

---

## Phase Plan

| # | Phase | Owner | Autonomy | Sessions | Notes |
|---|-------|-------|----------|----------|-------|
| 1 | Research | Product | 👁 Supervised | 1R | |
| 1b | Voice of Customer | Product | 👥 Human-led | 2D | Only if primary data available |
| 2 | Synthesize | Both | 👁 Supervised | 0.5R | **Sync S1 after** |
| 3 | Product Spec | Product | ✍ Collaborative | 3D | **Gate** |
| 3b | Personas | Product | ✍ Collaborative | 1D | |
| 4 | Customer Journey | Product | ✍ Collaborative | 2D | **Sync S2 after** |
| 5 | Data Model ⚠️ | Tech | ✍ Collaborative | 2D | **Critical gate** |
| 6 | Tech Architecture ⚠️ | Tech | ✍ Collaborative | 3D | **Gate — Sync S3 after** |
| 7 | Plan | Tech | 👁 Supervised | 0.5R | |
| 8 | Code | — | 🤖 Autonomous | 0 | AI runs unattended |
| 9 | Test Cases | Both | 👁 Supervised | 0.5R | |
| 10 | Test Automation | — | 🤖 Autonomous | 0 | AI runs unattended |
| 11 | Observability | Tech | 👁 Supervised | 0.5R | |
| 12 | SRE | Tech | ✍ Collaborative | 1D | |
| 13 | Review | Both | ✍ Collaborative | 1.5D | **Gate — Sync S4 after** |

---

## Critical Path

```
[Phase 3: Product Spec] → [Phase 5: Data Model ⚠️] → [Phase 6: Tech Architecture] → [Phase 8: Code 🤖]
```

The data model is the highest-risk decision in this project.
A wrong data model propagates through architecture, API design, and code.
Invest extra Design sessions here before proceeding.

---

## Parallel Work Windows (Microsquad)

After Phase 3 completes and is pushed, two threads can run simultaneously:

```
Phase 3 (BA) ──────────── PUSH ──┬─────────────────────────────────────────────────
                                  │
   BA thread:                     └─→ Phase 3b (Personas) → Phase 4 (Journey) → free during Phase 8
                                                                                       ↓
   Eng thread:                    └─→ Phase 5 (Data Model) → Phase 6 (Arch) → Phase 7 (Plan) → Phase 8
                                                                                       ↓
                                                            Both threads rejoin: Phase 9, 13
```

**File separation guarantees no conflicts during parallel operation.**
BA writes: PERSONAS.md, CUSTOMER_JOURNEY.md
Eng writes: DATA_MODEL.md, DATA_DICTIONARY.md, TECH_ARCHITECTURE.md, API_SPEC.md, SOLUTION_DESIGN.md

---

## Sync Points

| Sync | After Phase | Owner(s) | Agenda |
|------|------------|---------|--------|
| S1 | 2 — Synthesize | Both | Align on strategic picture before spec work splits the team |
| S2 | 4 — Customer Journey | Both | Product Lead hands off to Tech Lead — journey → data model |
| S3 | 6 — Tech Architecture | Both | Architecture confirmed, unblock code phase |
| S4 | 13 — Review | Both | Final sign-off, production readiness decision |

---

## Effort Summary

| Type | Sessions | Phases |
|------|---------|--------|
| Design (D) | [N] | 1b, 3, 3b, 4, 5, 6, 12, 13 |
| Review (R) | [N] | 1, 2, 7, 9, 11 |
| Sync (S) | 4 | S1–S4 |
| **Total** | **[N]** | |

At [N] sessions/week: estimated [N] weeks of human engagement.
AI execution runs in parallel — not a calendar constraint.

---

## Phase Log

*Status key: ⬜ Not started | 🔄 In Progress | ✅ Complete | N/A Skipped*

| Phase | Status | Sessions Used | Completed | Notes |
|-------|--------|--------------|-----------|-------|
| 1. Research | ⬜ Not started | — | — | |
| 1b. VoC | ⬜ Not started | — | — | Optional — use N/A Skipped if not applicable |
| 2. Synthesize | ⬜ Not started | — | — | |
| 3. Product Spec | ⬜ Not started | — | — | |
| 3b. Personas | ⬜ Not started | — | — | Optional — use N/A Skipped if not applicable |
| 4. Customer Journey | ⬜ Not started | — | — | |
| 5. Data Model | ⬜ Not started | — | — | |
| 6. Tech Architecture | ⬜ Not started | — | — | |
| 7. Plan | ⬜ Not started | — | — | |
| 8. Code | ⬜ Not started | — | — | |
| 9. Test Cases | ⬜ Not started | — | — | Run twice: after Phase 8, then again after Phase 12 |
| 10. Test Automation | ⬜ Not started | — | — | |
| 11. Observability | ⬜ Not started | — | — | |
| 12. SRE | ⬜ Not started | — | — | |
| 13. Review | ⬜ Not started | — | — | |
