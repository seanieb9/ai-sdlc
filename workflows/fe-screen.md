# FE Screen Workflow

Generate a single screen from SCREEN_SPEC.md. Applies design tokens via component base. Wires API contracts. Extracts shared components.

## Step 1: Pre-Flight

Read in parallel:
- `docs/frontend/SCREEN_SPEC.md` — REQUIRED. Find the screen matching $ARGUMENTS.
- `docs/frontend/DESIGN_TOKENS.md` — REQUIRED. Token values to apply.
- `docs/frontend/COMPONENT_LIBRARY.md` — REQUIRED. What components are available.
- `docs/architecture/API_SPEC.md` — API contracts for this screen's data requirements.
- `docs/architecture/TECH_ARCHITECTURE.md` — stack confirmation
- `.sdlc/STATE.md` — project context

If SCREEN_SPEC.md missing: STOP. Run `ask Claude to run the fe-setup workflow` first.
If DESIGN_TOKENS.md missing: STOP. Run `ask Claude to run the fe-setup workflow` first.

Identify the screen: match $ARGUMENTS against screen route or name in SCREEN_SPEC.md. If ambiguous, show matching screens and ask for confirmation.

## Step 2: Read Screen Spec

From SCREEN_SPEC.md for the identified screen, extract:
1. Template type
2. All data requirements (endpoints, request/response shapes)
3. Navigation flows (what each action navigates to)
4. All four states: loading, empty, error, success
5. Components used (including which are [shared])
6. Personas and journey reference

## Step 3: Plan the File Structure

Before writing a line of code, define:

```
[Expo Router path — e.g. app/(app)/orders/index.tsx]
[Hook file — e.g. hooks/use-orders.ts (create if not exists)]
[Any new shared components — e.g. components/ui/OrderCard.tsx]
```

Check COMPONENT_LIBRARY.md `## Custom Components` — if a shared component from this screen already exists, use it. Only create if new.

## Step 4: Create TanStack Query Hooks

For each API endpoint in the screen's data requirements:

```typescript
// hooks/use-[resource].ts
// Only add new hooks — check existing file first

export function use[Resource](params: [ParamsType]) {
  return useQuery({
    queryKey: ['[resource]', params],
    queryFn: () => apiClient.get<[ResponseType]>('/api/v1/[path]', { params }),
    staleTime: [appropriate value],
  })
}

export function use[Create/Update/Delete][Resource]() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (command: [RequestType]) =>
      apiClient.post<[ResponseType]>('/api/v1/[path]', command),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['[resource]'] }),
  })
}
```

Types must match API_SPEC.md response/request schemas exactly. No `any`. No approximations.

## Step 5: Generate Screen Code

Apply the selected template pattern. All screens follow this structure:

```typescript
// app/(scope)/screen-name.tsx
import { Stack } from 'expo-router'
// imports from component library (Tamagui, etc.)
// imports from hooks
// imports from shared components

export default function [ScreenName]Screen() {
  // 1. Data fetching (hooks only)
  const { data, isLoading, isError, error, refetch } = use[Resource](params)

  // 2. Mutations
  const { mutate, isPending } = use[Action][Resource]()

  // 3. Render — must handle all four states
  if (isLoading) return <[ScreenName]Skeleton />
  if (isError) return <ErrorState message={error.message} onRetry={refetch} />
  if (!data || data.length === 0) return <EmptyState ... />

  return (
    <SafeAreaView>
      <Stack.Screen options={{ title: '[Screen Title]' }} />
      {/* screen content using token-based components */}
    </SafeAreaView>
  )
}
```

### Template-specific patterns:

**auth template:**
- KeyboardAvoidingView wrapper
- Form fields with controlled inputs
- Validation errors shown inline below each field
- Primary CTA disabled while isPending
- Loading spinner inside CTA button (not separate spinner)
- No back button on root auth screens

**list template:**
- SearchBar at top if search is required by spec
- FilterBar below search if filters defined in spec
- FlatList with keyExtractor, getItemLayout (for fixed-height items)
- ListEmptyComponent for empty state
- ListHeaderComponent for stats/summary if dashboard-like
- Pull-to-refresh with onRefresh + refreshing props
- Pagination: cursor-based via onEndReached

**list-detail template:**
- Mobile: FlatList → push navigation to detail
- Tablet (width > 768): side-by-side split view using useWindowDimensions
- Detail always renderable standalone (deep link safe)

**form template:**
- ScrollView wrapper with keyboardShouldPersistTaps="handled"
- Group fields into logical sections with YStack/VStack
- Validate on blur, show errors inline
- Submit button at bottom, outside scroll (sticky footer)
- Show confirmation dialog before destructive submissions
- Disable all fields while isPending

**dashboard template:**
- ScrollView (not FlatList — non-uniform content)
- Stat cards in a 2-column grid using XStack
- Chart area: placeholder `<ChartPlaceholder />` — charts are project-specific
- Recent activity: FlatList with fixed height, scrollEnabled={false} (inside ScrollView)

**settings template:**
- SectionList with grouped sections
- Each row: label left, value/control right
- Logout row always last, color=colorError
- Toggle rows use Switch component
- Selector rows navigate to dedicated picker screen

**error-empty template:**
- Centered vertically in remaining space
- Illustration area (SVG or image)
- Heading (concise, not technical)
- Body text (what to do, not what went wrong)
- Primary action button (retry / go home / sign in as appropriate)

## Step 6: Implement Accessibility

For every interactive element in the generated screen:
- Add `accessible={true}` and `accessibilityLabel` on icon-only controls
- Add `accessibilityRole` on all pressables (button / link / checkbox / etc.)
- Add `accessibilityHint` where the action isn't obvious from the label
- Add `accessibilityState` for loading (`{ busy: true }`), disabled, checked states
- Add `testID` to all interactive elements (format: `[screen-name]-[element-name]`)
- Verify all text colors pass contrast ratio against their background from token definitions

## Step 7: Extract Shared Components

For each component marked [shared] in the SCREEN_SPEC.md:
1. Check `components/ui/` — if it doesn't exist yet, create it
2. Extract to `components/ui/[ComponentName].tsx`
3. Props interface must be explicit — no passthrough `...props` objects without typing them
4. Add `testID` prop support to every shared component
5. Update `docs/frontend/COMPONENT_LIBRARY.md` ## Custom Components table

Component file structure:
```typescript
// components/ui/[ComponentName].tsx
interface [ComponentName]Props {
  // explicit props — no any
  testID?: string
}

export function [ComponentName]({ ..., testID }: [ComponentName]Props) {
  return (
    // component using only token-based styles
  )
}
```

## Step 8: Write Files

Write in this order:
1. Hook file (create or update `hooks/use-[resource].ts`)
2. Any new shared components (`components/ui/*.tsx`)
3. Screen file (`app/(scope)/screen-name.tsx`)

## Step 9: Update COMPONENT_LIBRARY.md

If any new shared components were extracted, add them to the ## Custom Components table:
```
| [ComponentName] | components/ui/[ComponentName].tsx | [screens that use it] | Done |
```

## Step 10: Output

```
Screen Generated: [screen route]

Template:    [type]
Hook:        hooks/use-[resource].ts ([new | updated])
Components:  [N new shared components extracted]
States:      loading | empty | error | success
A11y:        [N] accessible elements, [N] testIDs
API calls:   [list of endpoints wired]

Files written:
- app/(scope)/screen-name.tsx
- hooks/use-[resource].ts (if new)
- components/ui/[...].tsx (if extracted)

Recommended Next:
  ask Claude to run the fe-screen workflow [next screen from SCREEN_SPEC.md]
  OR /sdlc:09-test-cases after all screens complete
```
