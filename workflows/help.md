# SDLC Help

Display the SDLC system guide. If a specific command was provided in $ARGUMENTS, show detailed help for that command.

## If $ARGUMENTS is empty — Show Full Guide:

```
╔══════════════════════════════════════════════════════════════════╗
║           AI-SDLC — Software Development Lifecycle              ║
╠══════════════════════════════════════════════════════════════════╣
║  COMMANDS (9 total — everything else is automatic)              ║
╠══════════════════════════════════════════════════════════════════╣
║  START & NAVIGATE                                                ║
║  /sdlc:00-start <idea>  Universal entry point. Handles:         ║
║                         • New project → full lifecycle          ║
║                         • Existing codebase → maps + continues  ║
║                         • "resume" → picks up from checkpoint   ║
║                         • "status" → shows current phase        ║
║                                                                  ║
║  /sdlc:fix <bug>        Bug fix — diagnose, plan, code, test    ║
║  /sdlc:iterate <feat>   Add/change a feature (scoped lifecycle) ║
╠══════════════════════════════════════════════════════════════════╣
║  DAILY RHYTHM                                                    ║
║  /sdlc:sod              Start of day — reads checkpoint, plans  ║
║  /sdlc:eod              End of day — commits WIP, saves state   ║
║  /sdlc:checkpoint       Save session state to state.json        ║
║  /sdlc:resume           Restore after /clear or auto-compact    ║
╠══════════════════════════════════════════════════════════════════╣
║  STATUS                                                          ║
║  /sdlc:status           Phase progress, gates, active tasks     ║
║  /sdlc:help             This guide                              ║
╚══════════════════════════════════════════════════════════════════╝

LIFECYCLE (fully automatic via /sdlc:00-start):
  Research → Synthesize → Product Spec ◉ → Journey →
  Data Model ◉⚠️ → Tech Arch ◉ → Plan ◉⚠️ → Code →
  Test Cases ◉⚠️ → Test Gen → Observability → SRE →
  Review → Verify ◉ → Deploy ◉
  ◉ = human review pause   ⚠️ = hard gate

AUTO-CHAINS (fire silently after each phase):
  idea        → nfr-analysis → nfr-slo (SLO derivation)
  data-model  → pii-audit, migrate-scaffold
  design      → threat-model → security TC-IDs + tasks
               adr-gen → adr-test-coverage
               infra-design, contract-test-scaffold (if API spec)
               observability skeleton, sre skeleton
  test-cases  → bdd-tdd-scaffold (Gherkin + TDD stubs)
  test-gen    → test-gaps, traceability
  build       → code-quality → debt-log, audit-deps, pii-audit
  plan        → roadmap
  deploy      → ci-verify (hard gate), maintain

HUMAN TOUCHPOINTS (only these):
  • Product spec — confirm requirements
  • NFR review — approve before data model
  • Data model — challenger review + approval
  • Tech arch — adversarial debate + approval
  • Plan — approve before coding
  • Verify — quality gate before deploy
  • Deploy — checklist sign-off

BROWNFIELD QUICK START:
  /sdlc:00-start "describe what you want to do"
  (00-start detects existing codebase and maps it automatically)

RESUME AFTER /clear:
  /sdlc:resume   or   /sdlc:00-start "resume"
```

## If $ARGUMENTS has a command name — Show Command Detail:

Look up the workflow for the command described and show:
- What the command does
- When to use it
- What it requires (inputs, predecessor phases)
- What it produces (output files)
- Available flags
- Example usage
