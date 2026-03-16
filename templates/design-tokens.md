# Design Tokens
*Last Updated: {{DATE}} | Level: {{None | Brand | Full}} | Component Base: {{Tamagui | NativeWind | Unistyles}}*

## TL;DR
- {{N}} token categories | Base unit: 4px | Primary: {{hex}} | Font: {{name}}
- Platform: iOS / Android / Web (Expo + React Native + Expo Router)
- Source: {{Default AI-SDLC set | Derived from brand color | Imported from design system}}

## Contents
- [Color](#color)
- [Typography](#typography)
- [Spacing](#spacing)
- [Border Radius](#border-radius)
- [Shadow](#shadow)
- [Motion](#motion)
- [Platform Config](#platform-config)

---

## Color

### Primary Palette
| Token | Hex | Use |
|-------|-----|-----|
| primary1 | | Lightest — backgrounds, tints |
| primary2 | | Hover backgrounds |
| primary3 | | Active backgrounds |
| primary4 | | Borders on white |
| primary5 | | Borders on dark |
| primary6 | | Muted text, subtle icons |
| primary7 | | Decorative — badges, tags |
| primary8 | | Interactive base (must pass 4.5:1 on white) |
| primary9 | | Interactive base dark mode |
| primary10 | | Text on primary background |
| primary11 | | Strong text, headings |
| primary12 | | Darkest — high-contrast text |

### Semantic Colors
| Token | Hex | Maps to |
|-------|-----|---------|
| colorSuccess | | |
| colorWarning | | |
| colorError | | |
| colorInfo | | |

### Neutral Scale
| Token | Hex | Use |
|-------|-----|-----|
| gray1 | | Lightest backgrounds |
| gray2 | | |
| gray3 | | |
| gray4 | | Borders |
| gray5 | | |
| gray6 | | Subtle text |
| gray7 | | |
| gray8 | | Body text |
| gray9 | | |
| gray10 | | |
| gray11 | | Strong text |
| gray12 | | |

### Semantic Aliases
| Token | Points to | Use |
|-------|----------|-----|
| bg | gray1 | Default screen background |
| bgStrong | gray2 | Elevated surfaces |
| bgSubtle | gray1 | |
| color | gray12 | Default text |
| colorSubtle | gray8 | Secondary text |
| colorDisabled | gray6 | |
| borderColor | gray4 | |
| borderColorStrong | gray6 | |
| colorFocus | primary8 | Focus ring |
| colorPressed | primary9 | Pressed state |

---

## Typography

### Font Families
| Token | Value | Use |
|-------|-------|-----|
| fontBody | | Body text, UI labels |
| fontHeading | | Headings, display text |
| fontMono | 'Courier New', monospace | Code, numeric data |

### Size Scale
| Token | px | rem (web) | Use |
|-------|-----|----------|-----|
| fontSize1 | 10 | 0.625 | Caption, legal |
| fontSize2 | 12 | 0.75 | Label, badge |
| fontSize3 | 14 | 0.875 | Body small |
| fontSize4 | 16 | 1.0 | Body default |
| fontSize5 | 18 | 1.125 | Body large |
| fontSize6 | 20 | 1.25 | Subtitle |
| fontSize7 | 24 | 1.5 | Heading 3 |
| fontSize8 | 32 | 2.0 | Heading 2 |
| fontSize9 | 48 | 3.0 | Heading 1, display |

### Weight
| Token | Value | Use |
|-------|-------|-----|
| fontWeightRegular | 400 | Body |
| fontWeightMedium | 500 | Labels, buttons |
| fontWeightSemibold | 600 | Subheadings |
| fontWeightBold | 700 | Headings, emphasis |

### Line Height
| Token | Value | Use |
|-------|-------|-----|
| lineHeightTight | 1.2 | Headings |
| lineHeightSnug | 1.4 | UI labels |
| lineHeightNormal | 1.5 | Body text |
| lineHeightRelaxed | 1.75 | Long-form reading |

---

## Spacing

*Base unit: 4px*

| Token | px | Common use |
|-------|-----|-----------|
| space1 | 4 | Icon gap, tight padding |
| space2 | 8 | Compact padding |
| space3 | 12 | |
| space4 | 16 | Default padding, gap |
| space5 | 20 | |
| space6 | 24 | Section padding |
| space8 | 32 | Large gap |
| space10 | 40 | |
| space12 | 48 | Section spacing |
| space16 | 64 | Page sections |

---

## Border Radius

| Token | px | Use |
|-------|-----|-----|
| radius1 | 4 | Small inputs, chips |
| radius2 | 8 | Buttons, cards |
| radius3 | 12 | Modals, sheets |
| radius4 | 16 | Large cards |
| radius5 | 24 | Pill shapes |
| radiusFull | 9999 | Avatars, badges |

---

## Shadow

| Token | Web box-shadow | iOS | Android elevation |
|-------|---------------|-----|------------------|
| shadow1 | 0 1px 2px rgba(0,0,0,0.05) | | 1 |
| shadow2 | 0 1px 3px rgba(0,0,0,0.1) | | 2 |
| shadow3 | 0 4px 6px rgba(0,0,0,0.1) | | 4 |
| shadow4 | 0 10px 15px rgba(0,0,0,0.1) | | 8 |
| shadow5 | 0 25px 50px rgba(0,0,0,0.15) | | 16 |

---

## Motion

| Token | Value | Use |
|-------|-------|-----|
| durationFast | 150ms | Micro-interactions, toggles |
| durationNormal | 250ms | Standard transitions |
| durationSlow | 400ms | Page transitions, modals |
| easingDefault | ease-in-out | General |
| easingEnter | ease-out | Elements entering |
| easingExit | ease-in | Elements leaving |

---

## Platform Config

### Tamagui (tamagui.config.ts)
```typescript
// Auto-generated from DESIGN_TOKENS.md — update this file when tokens change
import { createTokens, createTamagui } from 'tamagui'

export const tokens = createTokens({
  color: {
    // Primary palette
    primary1: '{{primary1}}',
    // ... all color tokens
  },
  space: {
    1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 8: 32, 10: 40, 12: 48, 16: 64,
  },
  size: {
    1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 8: 32, 10: 40, 12: 48, 16: 64,
  },
  radius: {
    1: 4, 2: 8, 3: 12, 4: 16, 5: 24, true: 8, full: 9999,
  },
  zIndex: {
    0: 0, 1: 100, 2: 200, 3: 300, 4: 400,
  },
})
```
