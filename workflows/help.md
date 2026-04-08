# SDLC Help

Display the SDLC system guide. If a specific command was provided in $ARGUMENTS, show detailed help for that command.

## If $ARGUMENTS is empty — Show Full Guide:

```
╔══════════════════════════════════════════════════════════════════╗
║           SDLC SYSTEM — Software Development Lifecycle           ║
╠══════════════════════════════════════════════════════════════════╣
║  SESSION                                                         ║
║  1.  /sdlc:00-start <idea>   Entry point — always start here     ║
║  2.  /sdlc:sod               Start of day — orient & plan        ║
║  3.  /sdlc:eod               End of day — commit & checkpoint    ║
║  4.  /sdlc:checkpoint        Save session state                  ║
║  5.  /sdlc:resume            Restore after /clear or compact     ║
║  6.  /sdlc:status            Current state dashboard             ║
║  7.  /sdlc:verify            Quality gate — run after each phase ║
╠══════════════════════════════════════════════════════════════════╣
║  LIFECYCLE PHASES (run in order)                                 ║
║  8.  /sdlc:01-research       Market, competitive & gap research  ║
║  9.  /sdlc:01b-voc           Voice of customer synthesis         ║
║  10. /sdlc:02-synthesize     Combine research + codebase         ║
║  11. /sdlc:03-product-spec   Requirements, BDD, business rules   ║
║  12. /sdlc:03b-personas      Personas — JTBD, empathy, anti      ║
║  13. /sdlc:04-customer-journey  Journey maps & screen flows      ║
║  14. /sdlc:04b-business-process Back-office & operational flows  ║
║  15. /sdlc:05-data-model  ⚠️  Canonical data model — must go first║
║  16. /sdlc:06-tech-arch      Clean arch, C4 model, API specs     ║
║  17. /sdlc:07-plan           Phased execution plan + TODO list   ║
║  18. /sdlc:08-code           Implement tasks (requires plan)     ║
║  19. /sdlc:09-test-cases     MECE GWT test cases                 ║
║  20. /sdlc:10-test-automation Automation scripts from test cases ║
║  21. /sdlc:11-observability  Logging, tracing, metrics           ║
║  22. /sdlc:12-sre            SLOs, runbooks, incident response   ║
║  23. /sdlc:13-review         Cross-cutting quality review        ║
╠══════════════════════════════════════════════════════════════════╣
║  ITERATION & MAINTENANCE                                         ║
║  24. /sdlc:iterate           Scoped feature iteration            ║
║  25. /sdlc:fix               Bug fix / hotfix (lightweight)      ║
║  26. /sdlc:release           Group iterations into a release     ║
║  27. /sdlc:docs              Audit & organise SDLC documents     ║
║  28. /sdlc:decide            Record an architectural decision    ║
╠══════════════════════════════════════════════════════════════════╣
║  BROWNFIELD (existing codebases)                                 ║
║  29. /sdlc:map               Map codebase → CODEBASE_MAP.md      ║
║  30. /sdlc:explore <q>       Answer codebase questions           ║
║  31. /sdlc:assess            Readiness & migration risk score    ║
║  32. /sdlc:gaps              Gap analysis — debt, drift, quality ║
╠══════════════════════════════════════════════════════════════════╣
║  PLANNING & DESIGN AIDS                                          ║
║  33. /sdlc:roadmap           Human session plan for the project  ║
║  34. /sdlc:clarify           Requirements elicitation Q&A        ║
║  35. /sdlc:compare           Design alternatives + trade-offs    ║
║  36. /sdlc:feasibility       Go/No-Go viability assessment       ║
║  37. /sdlc:prototype         Low-fidelity UX flows               ║
║  38. /sdlc:threat-model      STRIDE threat modelling             ║
╠══════════════════════════════════════════════════════════════════╣
║  SCAFFOLDING & INFRA                                             ║
║  39. /sdlc:microservices     Scaffold production-ready service   ║
║  40. /sdlc:infra-design      Dockerfiles, K8s, CI pipeline       ║
║  41. /sdlc:fe-setup          Front-end design system setup       ║
║  42. /sdlc:fe-screen         Generate screen from spec           ║
╠══════════════════════════════════════════════════════════════════╣
║  QUALITY & RELIABILITY                                           ║
║  43. /sdlc:code-quality      Static analysis & security scan     ║
║  44. /sdlc:prr               Production Readiness Review gate    ║
║  45. /sdlc:uat               Stakeholder acceptance test plan    ║
║  46. /sdlc:retro             Project retrospective               ║
╠══════════════════════════════════════════════════════════════════╣
║  TRACKING                                                        ║
║  47. /sdlc:progress          Task completion dashboard           ║
║  48. /sdlc:debt              Technical debt register             ║
║  49. /sdlc:squad             Team workflow dashboard             ║
║  50. /sdlc:maintain          Maintenance & upgrade roadmap       ║
╚══════════════════════════════════════════════════════════════════╝

PHASE GATES (enforced by orchestrator):
  • DATA-MODEL  must exist before: tech-arch, plan, code
  • PLAN        must exist before: code
  • PRODUCT-SPEC must exist before: data-model, test-cases
  • TEST-CASES  must exist before: test-automation

DOCUMENT REGISTRY:
  docs/research/      RESEARCH.md, GAP_ANALYSIS.md, SYNTHESIS.md, VOC.md
  docs/product/       PERSONAS.md, PRODUCT_SPEC.md, CUSTOMER_JOURNEY.md, BUSINESS_PROCESS.md
  docs/data/          DATA_MODEL.md, DATA_DICTIONARY.md
  docs/architecture/  TECH_ARCHITECTURE.md, API_SPEC.md, SOLUTION_DESIGN.md
  docs/qa/            TEST_CASES.md, TEST_AUTOMATION.md
  docs/sre/           OBSERVABILITY.md, RUNBOOKS.md, SLO.md
  docs/review/        REVIEW_REPORT.md
  .claude/ai-sdlc/    state.json (checkpoint, todos, decisions, progress)

QUICK START:
  New project:   /sdlc:00-start "describe your idea here"
  Brownfield:    /sdlc:map  →  /sdlc:00-start
  Resume work:   /sdlc:resume
  Daily start:   /sdlc:sod
```

## If $ARGUMENTS has a command name — Show Command Detail:

Read the command file from `commands/sdlc/[command-name].md` and show:
- What the command does
- When to use it
- What it requires (inputs, predecessor phases)
- What it produces (output files)
- Available flags
- Example usage
