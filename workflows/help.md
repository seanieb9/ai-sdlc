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
║  9.  /sdlc:02-synthesize     Combine research + codebase         ║
║  10. /sdlc:03-product-spec   Requirements, BDD, business rules   ║
║  11. /sdlc:04-customer-journey  Journey maps & screen flows      ║
║  12. /sdlc:05-data-model  ⚠️  Canonical data model — must go first║
║  13. /sdlc:06-tech-arch      Clean arch, C4 model, API specs     ║
║  14. /sdlc:07-plan           Phased execution plan + TODO list   ║
║  15. /sdlc:08-code           Implement tasks (requires plan)     ║
║  16. /sdlc:09-test-cases     MECE GWT test cases                 ║
║  17. /sdlc:11-observability  Logging, tracing, metrics           ║
║  18. /sdlc:12-sre            SLOs, runbooks, incident response   ║
║  19. /sdlc:13-review         Cross-cutting quality review        ║
╠══════════════════════════════════════════════════════════════════╣
║  ITERATION & RELEASE                                             ║
║  20. /sdlc:iterate           Scoped feature iteration            ║
║  21. /sdlc:fix               Bug fix / hotfix (lightweight)      ║
║  22. /sdlc:release           Group iterations into a release     ║
║  23. /sdlc:deploy            Deploy to environment               ║
╠══════════════════════════════════════════════════════════════════╣
║  BROWNFIELD (existing codebases)                                 ║
║  24. /sdlc:map               Map codebase → CODEBASE_MAP.md      ║
║  25. /sdlc:explore <q>       Answer codebase questions           ║
╠══════════════════════════════════════════════════════════════════╣
║  PROJECT MANAGEMENT                                              ║
║  26. /sdlc:roadmap           Human session plan for the project  ║
║  27. /sdlc:decide            Record an architectural decision    ║
║  28. /sdlc:docs              Audit & organise SDLC documents     ║
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
