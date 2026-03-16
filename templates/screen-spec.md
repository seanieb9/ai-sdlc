# Screen Specification
*Last Updated: {{DATE}} | {{N}} screens | Derived from: CUSTOMER_JOURNEY.md*

## TL;DR
- {{N}} screens across {{N}} flows
- {{N}} shared components identified
- Platform: iOS + Android + Web (Expo Router)
- Component base: {{Tamagui | NativeWind | etc.}}

## Contents
[Screen inventory and then one section per screen]

---

## Screen Inventory

| Route | Name | Template | Personas | Auth | Shared Components |
|-------|------|---------|---------|------|------------------|
| (auth)/login | Login | auth | All | Public | FormField, ErrorBanner |
| (auth)/register | Register | auth | All | Public | FormField, ErrorBanner |
| (app)/index | Dashboard | dashboard | All | Authenticated | StatCard, ActivityRow |
| ... | | | | | |

### Shared Component Registry
| Component | File | Used in | Status |
|-----------|------|---------|--------|
| FormField | components/ui/FormField.tsx | login, register | Not built |
| ErrorBanner | components/ui/ErrorBanner.tsx | login, register, ... | Not built |
| StatCard | components/ui/StatCard.tsx | dashboard | Not built |

*Status: Not built | In progress | Built*

---

## (auth)/login — Login

**Route:** `app/(auth)/login.tsx`
**Template:** `auth`
**Persona(s):** {{list}}
**Journey:** CUSTOMER_JOURNEY.md → {{journey name}} → Step {{N}}
**Auth:** Public

### Data Requirements
| Type | Endpoint | Request | Response | Notes |
|------|---------|---------|----------|-------|
| Mutation | POST /api/v1/auth/login | `{ email, password }` | `{ token, user }` | Store token in SecureStore |

### Navigation
| Action | Destination | Type |
|--------|------------|------|
| Submit success | (app)/index | replace (no back) |
| Forgot password | (auth)/forgot-password | push |
| Register | (auth)/register | push |

### States
| State | Content |
|-------|---------|
| Loading | Submit button shows spinner, fields disabled |
| Empty | n/a — pre-filled form starts empty |
| Error | ErrorBanner below form fields, fields re-enabled |
| Success | Redirect — screen not shown |

### Components
- `[FormField]` [shared] — email input
- `[FormField]` [shared] — password input (secureTextEntry)
- `[ErrorBanner]` [shared] — API error display
- `[PrimaryButton]` [shared] — submit CTA

---

<!-- Repeat the above section for every screen in the inventory -->
