# Personas
*Last Updated: {{DATE}}*
*Evidence basis: {{SOURCES}} | Confidence: {{HIGH|MEDIUM|LOW}}*

---

## Segment Map

| Segment | Size | Priority | Distinguishing Characteristic | Evidence |
|---------|------|----------|-------------------------------|---------|
| {{Name}} | Large/Medium/Small | PRIMARY | {{What makes them distinct}} | VOC themes: {{list}} |

---

## Persona Hierarchy

1. **PRIMARY:** {{Persona Name}} — all core decisions optimize for them
2. **SECONDARY:** {{Persona Name}} — considered when not in conflict with primary

Conflict rule: When primary and secondary conflict, default to primary unless {{exception condition}}.

---

## Personas

### {{Persona Name}} — {{Role/Segment}} (PRIMARY)

#### Narrative
{{Day-in-the-life paragraph grounded in research data}}

#### Jobs-to-be-Done

**Primary Functional Job:**
> "When I {{trigger}}, I want to {{action}}, so I can {{outcome}}"
*Evidence: VOC-{{theme}}, {{N}} customers*

**Emotional Job:** I want to feel {{emotion}} / avoid feeling {{emotion}}

**Social Job:** I want to be seen as {{perception}} by {{audience}}

#### Gains and Pains

**Pains (blockers and frustrations):**

| Pain | Severity (1-5) | Evidence |
|------|---------------|---------|
| {{Pain description}} | {{N}} | "{{verbatim quote}}" — {{source}} |

**Gains (desired outcomes):**
- Essential: {{table-stakes outcome}}
- Desired: {{outcome they'd love}}

#### Empathy Map

| Think & Feel | Say & Do |
|-------------|---------|
| {{Inner concerns and aspirations}} | {{Observable behavior and quotes}} |

| See | Hear |
|-----|------|
| {{Market and environment they observe}} | {{Influences and advice they receive}} |

#### Current Solutions and Gaps

| Currently uses | Why it falls short | Switching cost |
|---------------|-------------------|---------------|
| {{Tool/approach}} | {{The gap — your opportunity}} | HIGH/MEDIUM/LOW |

**Workarounds:** {{What they do to compensate for the gap}}

#### Validation

- ☑ {{N}} customer interviews supporting this persona
- ☑ VOC themes: {{list}}
- ⚠ Assumption not yet validated: {{assumption}}

**Confidence:** HIGH / MEDIUM / LOW

---

## Anti-Personas

### Anti-Persona: {{Name — "The [descriptor]"}}

**Who they are:** {{brief description}}

**Why we won't build for them:**
- {{Reason 1}}
- {{Reason 2}}

**The trap:** {{How we might accidentally build for them}}

**Gate question:** "Does this primarily serve {{Anti-Persona Name}}?" → if yes, reconsider.

---

## Persona Usage Guide

- **Data model:** Primary persona's functional job defines core entities
- **Product spec:** Requirements must address primary persona's top 3 pains
- **Test cases:** E2E tests simulate primary persona's journey
- **Anti-persona gate:** Before adding scope → "does this serve {{Anti-Persona}}?"

---

## Change Log

| Date | Change | Evidence |
|------|--------|---------|
| {{DATE}} | Initial personas | {{source}} |
