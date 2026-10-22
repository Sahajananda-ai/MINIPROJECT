# SaveBite App — UI/UX Polish Pass (Design)

**Date:** 2026-10-22
**Goal:** Make every section of the app more detailed, clearer, and more
professional — in the visual language of Too Good To Go (warm cream, teal,
amber "rescue" energy) crossed with Indian food-delivery polish (clear data
density, rupee-first pricing, step-by-step flow). The user is away today, so
pre-approved design decisions were made conservatively: no behavior changes,
no new network calls, no backend edits.

## Findings from the survey

The screens are individually strong (animated onboarding, TGTG palette,
impact stats, empty states with CTAs), but the pass revealed shared gaps:

1. **Design tokens are duplicated per-file** with drift — `charcoal` is
   `0xFF2B1D15` in main.dart but `0xFF2D2D2D` in three screens. One canonical
   theme file removes this drift.
2. **Loading states are a bare spinner** (Discover feed, My Pickups), which
   reads as unfinished during data fetch.
3. **Sections lack headers/counts** — the Discover feed starts without any
   heading; users can't tell how many boxes are live.
4. **Errors are invisible** — a failed deal fetch shows the same UI as an
   empty result; the user can't retry.
5. **Developer jargon in user-facing copy** — checkout says "Redis Ephemeral
   Lock Active"; students don't know what Redis is.
6. **Checkout has no step indicator** — after reserving, where am I in the flow?
7. **"How it works" is an About dialog** — an OS modal with three bullet lines
   instead of a proper in-app explainer.

## Design decisions

**Scope guardrails:** UI-only edits to `mobile_app/lib`; every existing
callback, API call and flow path stays as-is; no new dependencies.

### 1. Shared design system

- `lib/theme/savebite_theme.dart` — canonical tokens (cream/teal/amber/
  charcoal/muted/danger/success), radius constants, text-style helpers
  (display, title, body, caption) built on Google Fonts already in use
  (Playfair Display + Inter).
- `lib/widgets/common_ui.dart` — reusable widgets:
  - `SectionHeader` — accent icon + title + optional trailing count pill.
  - `LoadingSkeleton` — soft pulsing rectangles (no shimmer dependency).
  - `AppEmptyState` — icon bubble, title, subtitle, optional CTA.
  - `AppErrorState` — failure message + "Try again" CTA.

### 2. Discover feed (`student_home.dart`)

- 3 pulsing deal-card skeletons while loading.
- A `SectionHeader` above the feed: "Live Surplus Near You" + count pill.
- Empty state: friendly copy + CTA "Explore on Radar Map" (jumps to tab 1) and
  "Clear filters" when a search/filter is active.
- Load failure: distinct error state with a Retry button.

### 3. Checkout (`checkout.dart`)

- Countdown banner becomes user language: "Box held for you — finish in 5:00"
  with sub-copy telling them the price stays locked until the timer ends.
- A three-step flow ribbon: **Reserved ✓ → Pay → Collect in store**, current
  stage emphasized.

### 4. My Pickups (`student_orders.dart`)

- Skeleton cards while the order list hydrates from the server, instead of an
  empty-looking flash of "No Active Pickups".

### 5. Profile / Impact (`student_profile.dart`)

- Replace the About-dialog info tile with a proper in-app bottom sheet:
  "How SaveBite Works" — four illustrated steps (Discover · Reserve · Collect ·
  Regenerate) plus a short FAQ (Is the food safe? What's inside the box? Why
  does the price change?).

### 6. Vendor portal (`vendor_dashboard.dart`)

- Give the two big activities numbered, titled sections: "1 · Curate with AI"
  and "2 · Review & Publish" (the form already has a title — reframe it as a
  step with a helper explainer line under the publish button).
- Add a compact "Listing checklist" card (what customers see vs. stays secret)
  so vendors understand the mystery mechanic before publishing.

### 7. Onboarding / role selection / auth

Already animated, well-copied, and brand-consistent — no changes needed
beyond the token files they already duplicate being left untouched (low-risk).

## Success criteria

- `flutter analyze` passes with no issues.
- No screen shows a bare spinner where content is expected (skeletons instead).
- Every user-facing string is customer language — no backend terminology.
- No behavior/API/flow changes: same routes, same callbacks, same data.
