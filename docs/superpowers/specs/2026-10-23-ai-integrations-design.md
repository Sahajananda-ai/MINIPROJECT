# SaveBite — Real AI & Free-API Integrations (Brainstorm → Design)

Date: 2026-10-23
Status: user pre-approved building ("start brainstorming new ai integration ideas... and start building those in the app")
Source of APIs: the well-known `public-apis/public-apis` free public API collection (no paid keys required).

## Goal

Add **real, useful, modern integrations** — not cosmetic AI labels. Every item below either
fixes a broken experience or adds capability a real food-rescue app would ship. Each idea was
scored on: usefulness to a SaveBite user, API cost (free/no-key strongly preferred), and how
much of the existing stack it reuses.

## Ideas considered

| # | Idea | API (free tier) | Useful? | Decision |
|---|------|------------------|---------|----------|
| 1 | Turn-by-turn walking navigation | OSRM demo (no key) | Fixes the user-reported "route shows no directions" bug | **Build now** |
| 2 | Weather-aware pickup nudges | Open-Meteo (no key) | "Rain at 6 PM — collect before 5:30" is a genuinely smart rescue nudge | **Build now** |
| 3 | Real pickup addresses on shops | Nominatim / OSM (no key) | Users need to know *where* to collect, not just lat/lng | **Build now** |
| 4 | "Ask SaveBite" AI concierge | Gemini free tier + rule-based fallback | Natural-language deal search ("vegan under ₹150 within 2 km") is the modern UX | **Build now** |
| 5 | AI smart-pricing advisor for vendors | Gemini free tier | Useful but redundant with existing AI curator suggestions | Later |
| 6 | Voice search | Web Speech API | Nice-to-have; flaky in some browsers | Later |
| 7 | AI photo cleanup for listings | Gemini vision | Existing curator already handles photos | Later |
| 8 | Multilingual UI strings | Gemini translate | Large surface; separate project | Later |

## Design — 1. Turn-by-turn walking navigation (OSRM steps)

- `ApiService.fetchWalkingRoute` currently parses only geometry/distance; extend it to also parse
  `routes[0].legs[*].steps[]` (`maneuver.type`, `maneuver.modifier`, `name`, `distance`) and build
  human-readable instructions ("Turn right onto 12th Main", "Continue on 80 Feet Road",
  "Arrive at destination") with a maneuver icon per step.
- New state on the map screen: `List<RouteStep> _routeSteps`.
- UI: the deal-preview and pickup-order cards gain a "Step-by-step directions" button that opens
  a bottom sheet listing each step (icon + text + distance), summary row at top
  (total distance, minutes). The simulated fallback path is labelled as approximate so it never
  pretends to be street-accurate.

## Design — 2. Weather-aware pickup nudges (Open-Meteo)

- New `WeatherService` in the app: `getPickupWeather(lat, lng)` → current temp, precipitation,
  and "rain expected within the next 2 hours" derived from hourly precipitation probability.
  Cached per coordinate pair (one in-app cache map) to respect the free tier.
- UI: pickup cards (map screen pickup card + My Pickups active order card) show a weather chip:
  "☀️ 21°C • Dry — good for pickup" or "🌧️ Rain likely — collect before <closing time>".
  Failure = chip hidden (weather is an enhancement, never blocking).

## Design — 3. Real pickup addresses (Nominatim reverse geocoding)

- `ApiService.reverseGeocode(lat, lng)` → reverse geocode via Nominatim (proper User-Agent,
  1 request/second policy respected, in-app cache keyed by rounded coordinates).
- Display name is trimmed to the locally meaningful part (e.g. "Amarjyothi Nagara, Hebbal, Bengaluru").
- UI: "📍 <address>" line on the pickup-order card (map + pickups screen) and on the deal preview
  card so students know the exact pickup spot.

## Design — 4. "Ask SaveBite" AI concierge (Gemini + fallback)

- Backend: `POST /ai/chat` in `backend/routers/ai.py`.
  - Input `{message, latitude?, longitude?}`.
  - If `GEMINI_API_KEY` is set, ask Gemini (free-tier model) to return strict JSON:
    `{reply, filters: {max_budget, dietary, category, keywords}}` (temperature 0.2).
  - Backend then scores the active deals (existing decay pricing + haversine distance), applies
    the filters, and returns `{reply, deals: [...]}` with live prices and walking distance.
  - Rule-based fallback parses ₹ amounts, veg/non-veg keywords and categories from the message —
    so the feature works with zero configuration.
- App: "Ask SaveBite" entry from the existing AI banner → new chat screen
  (`ai_concierge.dart`): message bubbles, typing indicator, quick-prompt chips
  ("Veg dinner under ₹150", "Best bakery deal", "Closing soon"). Matched deals render as compact
  result cards; tapping one jumps to the Discover detail sheet.

## Error handling (all four)

- Every external call has a timeout (5–8 s), a silent-failure path, and never blocks the primary
  flow. Directions fall back to the labelled approximate path; weather/geocode chips simply hide;
  the concierge falls back to rule-based parsing or a friendly "try again" bubble.

## Testing

- `flutter analyze` clean; backend `/ai/chat` smoke-tested with curl (with and without
  GEMINI_API_KEY); OSRM/Open-Meteo/Nominatim responses verified live before implementation
  (all three returned 200 on 2026-10-23).

## Future (not this session)

- AI smart-pricing advisor for the vendor dashboard (demand-aware price suggestions).
- Voice search, multilingual copy, AI photo cleanup.
