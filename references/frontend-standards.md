# Frontend Standards

## TL;DR
Cross-platform standard: Expo + React Native + Expo Router. Design tokens are first-class via Tamagui. Screens are generated from SCREEN_SPEC.md. No business logic in components — all data via TanStack Query against API_SPEC.md contracts.

---

## Stack
| Layer | Default | Alternatives | Notes |
|-------|---------|-------------|-------|
| Framework | Expo SDK (latest stable) | bare React Native | Expo preferred — managed workflow, OTA updates, EAS |
| Navigation | Expo Router v3 | React Navigation | File-based routing, works iOS/Android/Web |
| Component base | Tamagui | NativeWind v4, Unistyles v2, Gluestack UI v2 | Tamagui default — design tokens first-class, cross-platform |
| Server state | TanStack Query v5 | SWR | API calls, loading/error/success states |
| Client state | Zustand | Jotai | UI state only — no server state here |
| Testing (unit) | Jest + RNTL | — | React Native Testing Library |
| Testing (E2E) | Maestro | Detox | Maestro preferred — simpler, cross-platform |
| Build/Deploy | EAS Build + EAS Update | — | OTA updates for non-native changes |

---

## Design Token Structure

### Color
- Scale naming: `{palette}{step}` — e.g. `primary1` (lightest) → `primary12` (darkest), 12-step scale
- Semantic mapping: `colorSuccess`, `colorWarning`, `colorError`, `colorInfo` — map to a palette step
- Neutral scale: `gray1` → `gray12`
- Background: `bg`, `bgStrong`, `bgSubtle`
- Text: `color`, `colorSubtle`, `colorDisabled`
- Border: `borderColor`, `borderColorStrong`
- Interactive: `colorFocus` (focus ring), `colorPressed` (pressed state)

### Typography
- Font families: `fontBody`, `fontHeading`, `fontMono`
- Size scale: `fontSize1`(10) → `fontSize9`(48) — px values
- Weight: `fontWeightRegular`(400), `fontWeightMedium`(500), `fontWeightSemibold`(600), `fontWeightBold`(700)
- Line height: `lineHeight1`(1.2) → `lineHeight5`(2.0)
- Letter spacing: `letterSpacingTight`(-0.5), `letterSpacingNormal`(0), `letterSpacingWide`(0.5)

### Spacing (4px base unit)
`space1`(4) `space2`(8) `space3`(12) `space4`(16) `space5`(20) `space6`(24) `space8`(32) `space10`(40) `space12`(48) `space16`(64)

### Border Radius
`radius1`(4) `radius2`(8) `radius3`(12) `radius4`(16) `radius5`(24) `radiusFull`(9999)

### Shadow / Elevation
`shadow1` → `shadow5` — progressive elevation. Web uses box-shadow; iOS/Android use elevation + shadow props.

### Motion
`durationFast`(150ms), `durationNormal`(250ms), `durationSlow`(400ms)
`easingDefault`(ease-in-out), `easingEnter`(ease-out), `easingExit`(ease-in)

---

## Screen Templates
8 templates covering ~90% of screens:

| Template | Use when | Key components |
|----------|----------|---------------|
| `auth` | Login, register, forgot password, MFA | KeyboardAvoidingView, form fields, CTA button |
| `onboarding` | Multi-step flow, permissions | Progress indicator, illustration area, nav buttons |
| `list` | Searchable/filterable collection | SearchBar, FlatList with virtualization, empty/loading/error states |
| `list-detail` | Master + detail (push nav mobile, split tablet) | FlatList, detail pane, Platform-conditional layout |
| `form` | Create/edit with validation | ScrollView, field groups, inline errors, submit button |
| `dashboard` | Summary cards + activity | ScrollView, stat cards, chart placeholder, feed |
| `settings` | Grouped preferences | SectionList, row items, toggles, selectors |
| `error-empty` | 404, offline, no results, permission denied | Illustration, heading, body, action button |

Each template must implement all four states: loading (skeleton), empty, error (with retry), success.

---

## Expo Router File Conventions
```
app/
  _layout.tsx           ← root layout, providers (Tamagui, TanStack Query)
  (auth)/
    _layout.tsx         ← unauthenticated stack
    login.tsx
    register.tsx
  (app)/
    _layout.tsx         ← authenticated tabs/drawer
    index.tsx           ← dashboard / home
    (feature)/
      index.tsx         ← list screen
      [id].tsx          ← detail screen
      new.tsx           ← create screen
      [id]/edit.tsx     ← edit screen
components/
  ui/                   ← extracted shared components
  layout/               ← layout wrappers
hooks/
  use-[resource].ts     ← TanStack Query hooks, one per API resource
```

---

## API Integration Pattern
- All data fetching via TanStack Query hooks in `hooks/use-[resource].ts`
- Never fetch directly in components — components receive data as props or via hook
- Never put business logic in components — components render, hooks fetch
- Error boundaries at route level (not component level)
- Optimistic updates: use `useMutation` with `onMutate` / `onError` rollback
- Cache invalidation: invalidate by query key after mutations

```typescript
// hooks/use-orders.ts
export function useOrders(filters: OrderFilters) {
  return useQuery({
    queryKey: ['orders', filters],
    queryFn: () => apiClient.get('/api/v1/orders', { params: filters }),
    staleTime: 30_000,
  })
}

export function useCreateOrder() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (command: CreateOrderRequest) =>
      apiClient.post('/api/v1/orders', command),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['orders'] }),
  })
}
```

---

## Accessibility Standards (WCAG 2.1 AA — mandatory)
| Rule | Requirement | RN implementation |
|------|------------|------------------|
| Color contrast | 4.5:1 normal text, 3:1 large text | Verify in token palette definition |
| Touch target | 44×44pt minimum | `minWidth: 44, minHeight: 44` on all pressables |
| Focus management | Logical focus order, visible focus ring | `accessible`, `accessibilityLabel`, focus trapping in modals |
| Screen reader | All interactive elements labelled | `accessibilityLabel`, `accessibilityRole`, `accessibilityHint` |
| Icon-only controls | Always have text label for SR | `accessibilityLabel` required on icon buttons |
| Form fields | Label linked to input | `accessibilityLabel` or label component with `nativeID` |
| Error messages | Announced to screen reader | `accessibilityLiveRegion="polite"` on error containers |
| Disabled state | Communicated to SR | `accessibilityState={{ disabled: true }}` |

---

## Responsive Strategy
- Mobile-first: design for 375px wide, scale up
- Breakpoints: `sm` (< 640px), `md` (640–1024px), `lg` (> 1024px)
- Use `useWindowDimensions()` for dynamic layout decisions
- Platform splits: `Platform.OS === 'web'` for web-only behaviour; avoid where possible
- Safe areas: always wrap screens in `<SafeAreaView>` or use `useSafeAreaInsets()`
- Keyboard: always `<KeyboardAvoidingView>` on forms

---

## Component Rules
- One component per file
- Props typed with TypeScript interfaces (no `any`)
- No inline styles — all styles via Tamagui tokens or `styled()`
- No hardcoded colors or spacing values
- Loading, empty, and error states are required on every data-dependent component
- Components do not fetch data — they receive it as props
- Extracted component threshold: appears in 2+ screens → extract to `components/ui/`

---

## Performance Standards
| Metric | Target | How to achieve |
|--------|--------|---------------|
| JS bundle (initial) | < 1MB | Code splitting via Expo Router lazy loading |
| TTI (web) | < 3s on 3G | SSR/SSG via Expo Router where applicable |
| Frame rate | 60fps (90+ on capable devices) | No heavy work on JS thread, use worklets |
| List performance | No dropped frames on 1000+ items | FlatList with `getItemLayout`, `keyExtractor`, `removeClippedSubviews` |
| Image loading | Skeleton placeholder until loaded | expo-image with placeholder prop |

---

## Testing Standards
| Layer | Tool | What to test |
|-------|------|-------------|
| Component | Jest + RNTL | Renders correctly, user interactions, state changes, accessibility tree |
| Hook | Jest + renderHook | Query/mutation logic, error handling, loading states |
| Navigation | Expo Router test utils | Route pushes, params passed correctly |
| E2E | Maestro | Full user flows from SCREEN_SPEC.md happy paths + failure paths |
| Accessibility | jest-axe + manual | WCAG 2.1 AA automated checks + manual VoiceOver/TalkBack |

---

## What NOT to do
- Never import from `../../../api/` directly in a component — always through a hook
- Never use `StyleSheet.create()` when Tamagui tokens are available
- Never hardcode platform checks for styling — use Tamagui's `$platform-web` / `$platform-native` props
- Never skip loading/error states — every async operation must handle all three states
- Never put navigation logic in components deeper than one level — navigate from the screen, not from nested components
- Never use `any` type — typed API contracts from API_SPEC.md should drive types
