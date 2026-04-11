# FE Setup Workflow

Configure the front-end design system foundation before planning. Creates DESIGN_TOKENS.md, COMPONENT_LIBRARY.md, and SCREEN_SPEC.md.

## Step 1: Pre-Flight

Read in parallel:
- `docs/architecture/TECH_ARCHITECTURE.md` — REQUIRED. Must contain ## Frontend Architecture section from Phase 6. STOP if missing or no FE section found.
- `docs/product/CUSTOMER_JOURNEY.md` — REQUIRED. Journey steps become screens.
- `docs/architecture/API_SPEC.md` — REQUIRED. API contracts drive screen data requirements.
- `docs/product/PERSONAS.md` — screen ownership per persona
- `docs/frontend/DESIGN_TOKENS.md` — if exists (update mode)
- `docs/frontend/SCREEN_SPEC.md` — if exists (update mode)
- `.sdlc/STATE.md` — project context, constraints

If CUSTOMER_JOURNEY.md missing: STOP. Cannot derive screens without journeys.
If API_SPEC.md missing: WARN. Screen data requirements will be incomplete — proceed with caution.

## Step 2: Determine Design System Level

Check STATE.md and TECH_ARCHITECTURE.md for any declared design system level. If not stated, ask the user ONE question:

> "What design assets exist for this project?
> A) None — use sensible defaults
> B) Brand guidelines only — provide primary color (hex) and font name
> C) Full design system — provide token file or Figma token export"

For B: ask for primary color + font. Derive the full token set (Step 3 will handle derivation).
For A or C: proceed directly to Step 3.

## Step 3: Build Design Tokens

### Level A (None — use defaults):
Apply the standard default token set from frontend-standards.md. Document rationale: "Default AI-SDLC token set — 4px base unit, Inter font, neutral gray scale, blue primary."

### Level B (Brand only):
Given primary color hex:
1. Generate 12-step palette from that color (lightest to darkest, perceptually uniform)
2. Derive secondary: rotate hue 30° or use complement
3. Check contrast ratios — primary6 on white must pass 4.5:1 (WCAG AA)
4. If it fails: shift to primary7 or primary8 as the interactive base
5. Derive semantic colors: success (green), warning (amber), error (red), info (blue) — adjust to complement primary
6. Typography: use provided font for headings; system font (-apple-system, sans-serif) for body unless font specified

### Level C (Full design system):
Read provided token file. Map to the DESIGN_TOKENS.md structure. Flag any missing required token categories.

### Token validation checklist (all levels):
- [ ] All 12 color steps defined for primary palette
- [ ] Neutral scale (gray1–gray12) defined
- [ ] All semantic colors defined (success/warning/error/info)
- [ ] Background tokens (bg, bgStrong, bgSubtle) defined
- [ ] Text tokens (color, colorSubtle, colorDisabled) defined
- [ ] Typography scale complete (fontSize1–fontSize9)
- [ ] Spacing scale complete (space1–space16)
- [ ] Border radius scale complete
- [ ] Shadow scale (shadow1–shadow5) defined
- [ ] Motion tokens defined (duration + easing)
- [ ] All interactive states covered (hover, pressed, focus, disabled)
- [ ] Contrast ratio verified: primary interactive base ≥ 4.5:1 on bg

## Step 4: Configure Component Library

Read the component base choice from TECH_ARCHITECTURE.md ## Frontend Architecture.

Default: Tamagui. For other choices, adapt the COMPONENT_LIBRARY.md structure accordingly.

Document:
1. Library name + version
2. Token mapping (how DESIGN_TOKENS.md values map to library config)
3. Custom overrides: components with non-default sizing, spacing, or radius
4. Component catalogue: list all available components from the chosen library (table: name, variants, key props)
5. Custom components: any components the project needs that are not in the base library (derive from SCREEN_SPEC.md in next step)

For Tamagui, generate a `tamagui.config.ts` snippet showing the token mapping.

## Step 5: Derive SCREEN_SPEC.md from Customer Journey

This is the key transformation: journey steps → screens.

### 5a: Screen inventory
For each journey in CUSTOMER_JOURNEY.md:
- Each named step that involves user interaction = one screen
- System-only steps (background processing, external redirects) = not a screen
- Name screen using route convention: `(auth)/login`, `(app)/orders/index`, `(app)/orders/[id]`
- Assign template type: `auth` | `onboarding` | `list` | `list-detail` | `form` | `dashboard` | `settings` | `error-empty`
- Link to persona(s) that use this screen
- Link to journey name and step number

### 5b: Data requirements per screen
For each screen, scan API_SPEC.md and identify:
- Which API endpoints this screen calls (GET for reads, POST/PUT/DELETE for mutations)
- What data shape it displays (from response schema)
- What it submits (from request schema)
- Auth requirement (public / authenticated / role-restricted)

### 5c: Navigation flows
Map the navigation graph:
- What screen does each CTA or action navigate to?
- What are the back/cancel destinations?
- What are the modal/sheet screens (overlays, not full navigations)?

### 5d: States per screen
For every screen, define all four required states:
- **Loading**: what skeleton or placeholder is shown
- **Empty**: what is shown when data exists but is empty (vs never loaded)
- **Error**: what is shown on API failure (with retry CTA)
- **Success**: the primary content state

### 5e: Component identification
Scan across all screens. Any UI element appearing in 2+ screens = shared component → flag as `[shared]` in the spec.

## Step 6: Write Output Documents

### Write/update `docs/frontend/DESIGN_TOKENS.md`:
```markdown
# Design Tokens
*Last Updated: [date] | Level: [None | Brand | Full] | Component Base: [Tamagui | NativeWind | etc.]*

## TL;DR
- [N] token categories | Base unit: 4px | Primary: [hex] | Font: [name]
- Platform: iOS / Android / Web (Expo + React Native + Expo Router)

## Color
[Token tables — name | value | semantic meaning | WCAG ratio where applicable]

## Typography
[Font families, size scale table, weight table]

## Spacing
[Scale table — token name | px value | common use]

## Border Radius
[Scale table]

## Shadow / Elevation
[Scale table — token | web box-shadow | iOS shadow | Android elevation]

## Motion
[Duration and easing tokens]

## Platform Config

### Tamagui (tamagui.config.ts snippet)
[Generated config snippet]
```

### Write/update `docs/frontend/COMPONENT_LIBRARY.md`:
```markdown
# Component Library
*Last Updated: [date] | Base: [library@version]*

## TL;DR
[Library choice and rationale — 1 sentence]

## Token Mapping
[How DESIGN_TOKENS.md maps to library config]

## Available Components
| Component | Variants | Key Props | Notes |
|-----------|---------|-----------|-------|
[All components from chosen library]

## Custom Components
| Component | Location | Used in screens | Status |
|-----------|---------|-----------------|--------|
[Components extracted from SCREEN_SPEC.md — initially empty, populated as screens are generated]

## Overrides
[Any non-default token applications or component config overrides]
```

### Write/update `docs/frontend/SCREEN_SPEC.md`:
```markdown
# Screen Specification
*Last Updated: [date] | [N] screens | Derived from: CUSTOMER_JOURNEY.md*

## TL;DR
[N screens across [N] flows. [N] shared components identified.]

## Contents
[Auto-generated contents with anchors]

## Screen Inventory

| Route | Template | Personas | Journey Ref | Auth | Shared Components |
|-------|---------|---------|------------|------|------------------|
[One row per screen]

---

## [Screen Name]

**Route:** `app/(auth)/login`
**Template:** `auth`
**Persona(s):** [list]
**Journey:** [CUSTOMER_JOURNEY.md section ref]

### Data Requirements
| Type | Endpoint | Shape | Notes |
|------|---------|-------|-------|
| Read | GET /api/v1/... | [fields] | |
| Mutation | POST /api/v1/... | [request fields] | |

### Navigation
| Action | Destination | Type |
|--------|------------|------|
| Submit | (app)/index | push |
| Forgot password | (auth)/forgot-password | push |

### States
| State | Content | Notes |
|-------|---------|-------|
| Loading | [skeleton description] | |
| Empty | [n/a for auth screens] | |
| Error | [error message + retry] | |
| Success | [redirect to destination] | |

### Components Used
- [SharedButton] [shared] — primary CTA
- [FormField] [shared] — email and password inputs
- [ErrorBanner] [shared] — inline error display
[one line per component, mark shared ones]
```

## Step 7: Update STATE.md

Mark Phase 6b (FE Setup) complete.
Add to document index:
- [x] docs/frontend/DESIGN_TOKENS.md
- [x] docs/frontend/COMPONENT_LIBRARY.md
- [x] docs/frontend/SCREEN_SPEC.md

## Step 8: Output Summary

```
FE Setup Complete

Design tokens:   Level [A/B/C] — [N] categories, [primary color], [font]
Screens:         [N] screens across [N] flows
Shared components identified: [N]
Component base:  [library@version]
Platform:        iOS + Android + Web (Expo Router)

Files:
- docs/frontend/DESIGN_TOKENS.md
- docs/frontend/COMPONENT_LIBRARY.md
- docs/frontend/SCREEN_SPEC.md

GATE UNLOCKED: the plan phase (tell Claude to proceed) can now include FE tasks.
Recommended Next: the plan phase (tell Claude to proceed)
  Then:           ask Claude to run the fe-screen workflow <screen-name> for each screen during Phase 8
```
