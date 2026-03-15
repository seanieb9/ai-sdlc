# SDLC Help

Display the SDLC system guide. If a specific command was provided in $ARGUMENTS, show detailed help for that command.

## If $ARGUMENTS is empty — Show Full Guide:

```
╔══════════════════════════════════════════════════════════════════╗
║  SDLC SYSTEM — Enterprise Software Development Lifecycle         ║
╠══════════════════════════════════════════════════════════════════╣
║  ENTRY POINT                                                     ║
║  /sdlc:00-start <idea>    Orchestrator — always start here       ║
║  /sdlc:sod                Start of day — orient, plan, brief     ║
║  /sdlc:eod                End of day — commit, checkpoint, wrap  ║
║  /sdlc:checkpoint         Save session state before /clear       ║
║  /sdlc:resume             Resume instantly after /clear          ║
║  /sdlc:verify [--phase N] Quality gate — run after every phase   ║
║  /sdlc:status          Show current state dashboard              ║
╠══════════════════════════════════════════════════════════════════╣
║  DISCOVERY & RESEARCH                                            ║
║  /sdlc:01-research        Market, competitive, customer research
  /sdlc:01b-voc           Primary customer data synthesis (interviews, tickets, NPS)     ║
║  /sdlc:02-synthesize      Combine research + codebase analysis      ║
╠══════════════════════════════════════════════════════════════════╣
║  SPECIFICATION                                                   ║
║  /sdlc:03b-personas       Rigorous personas (JTBD, empathy maps, anti-personas)
  /sdlc:03-product-spec    Requirements, BDD, business rules         ║
║  /sdlc:04-customer-journey Personas, journey maps, flows            ║
╠══════════════════════════════════════════════════════════════════╣
║  DESIGN (in this order)                                          ║
║  /sdlc:05-data-model  ⚠️  Canonical data model — critical gate      ║
║  /sdlc:06-tech-arch       Clean architecture, C4, API specs         ║
╠══════════════════════════════════════════════════════════════════╣
║  EXECUTION                                                       ║
║  /sdlc:07-plan            Phased execution plan + TODO list         ║
║  /sdlc:08-code            Implement tasks (requires plan)           ║
╠══════════════════════════════════════════════════════════════════╣
║  QUALITY                                                         ║
║  /sdlc:09-test-cases      MECE GWT test cases (reads req + code)    ║
║  /sdlc:10-test-automation Automation scripts from test cases        ║
║  /sdlc:13-review          Cross-cutting quality review              ║
╠══════════════════════════════════════════════════════════════════╣
║  RELIABILITY                                                     ║
║  /sdlc:11-observability   Logging, tracing, metrics, config         ║
║  /sdlc:12-sre             SLOs, runbooks, incident response         ║
╠══════════════════════════════════════════════════════════════════╣
║  PLANNING (optional — microsquad or solo)                        ║
║  /sdlc:roadmap         Human session plan — Design, Review, Sync ║
╠══════════════════════════════════════════════════════════════════╣
║  BROWNFIELD (existing codebases)                                 ║
║  /sdlc:map             Map the codebase → .sdlc/CODEBASE_MAP.md ║
║  /sdlc:explore <q>     Answer codebase questions from the map    ║
╠══════════════════════════════════════════════════════════════════╣
║  MAINTENANCE                                                     ║
║  /sdlc:docs            Document audit and management             ║
╚══════════════════════════════════════════════════════════════════╝

PHASE GATES (enforced by orchestrator):
  • DATA-MODEL must exist before: tech-arch, plan, code
  • PLAN must exist before: code
  • PRODUCT-SPEC must exist before: data-model, test-cases
  • TEST-CASES must exist before: test-automation

DOCUMENT REGISTRY (these are the ONLY docs created):
  docs/research/      RESEARCH.md, GAP_ANALYSIS.md, SYNTHESIS.md, VOC.md
  docs/product/       PERSONAS.md, PRODUCT_SPEC.md, CUSTOMER_JOURNEY.md, BUSINESS_PROCESS.md
  docs/data/          DATA_MODEL.md, DATA_DICTIONARY.md
  docs/architecture/  TECH_ARCHITECTURE.md, API_SPEC.md, SOLUTION_DESIGN.md
  docs/qa/            TEST_CASES.md, TEST_AUTOMATION.md
  docs/sre/           OBSERVABILITY.md, RUNBOOKS.md, SLO.md
  docs/review/        REVIEW_REPORT.md
  .sdlc/              STATE.md, TODO.md, PLAN.md, DECISIONS.md, CODEBASE_MAP.md, NEXT_ACTION.md

QUICK START:
  New project:    /sdlc:00-start "describe your idea here"
  Brownfield:     /sdlc:map  (then /sdlc:00-start)
  Status check:   /sdlc:status
  Help:           /sdlc:help <command-name>
```

## If $ARGUMENTS has a command name — Show Command Detail:

Read the command file from `/Users/seanlew/.claude/commands/sdlc/[command-name].md` and show:
- What the command does
- When to use it
- What it requires (inputs, predecessor phases)
- What it produces (output files)
- Available flags
- Example usage
