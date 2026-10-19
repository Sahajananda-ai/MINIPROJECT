# SaveBite — Competitive Fix Plan

Date: 2026-10-19
Sample: Research across TGTG Trustpilot (global), Plenti App Store/Reddit (India), Good To Grab Reddit (Hyderabad)

## What They Hate (Top complaints across all competitors)

### 1. "Surprise Bag" is a gamble — low quality items (32+ reviews, 3 sources)
> "Got nothing but day-old plain bread... not worth it" — TGTG Trustpilot
> "Picky eaters or people with specific dietary constraints cannot pre-select" — Plenti Reddit

**SaveBite Fix:** AI Sensory Shield. Gemini Vision classifies items by category + dietary tag WITHOUT revealing exact contents. Customer sees "Artisan Bakery Vault — 100% Pure Veg, Baked Fresh Today" with FSSAI Green-Dot badge, not "3 old rotis".
**Size:** Already built (backend/services/ai_vision_curator.py)

### 2. Pickup cancellations — store closed, staff unaware (18+ reviews, 2 sources)
> "Arriving at a store during the designated window only to find the store closed" — TGTG App Store
> "Staff unaware of how the app works" — TGTG Trustpilot

**SaveBite Fix:** Redis-locked pickup window with live countdown + vendor-side dashboard showing active reservations. Vendor MUST acknowledge orders. 5-min atomic lock with auto-release.
**Size:** Already built (backend/routers/deals.py reserve endpoint)

### 3. Inventory sells out instantly — no transparency (15+ reviews, 3 sources)
> "Popular drops sell out instantly" — Plenti Reddit
> "Zero active listings on slow business days" — Plenti user review

**SaveBite Fix:** Live decay pricing visible on card + remaining quantity counter. Redis DECR atomic operations — if quantity hits 0, card shows "Sold Out" immediately. No phantom inventory.
**Size:** Already built (backend/services/decay_pricing.py)

### 4. Self-pickup is inconvenient without routes (12+ reviews, 2 sources)
> "Commuting just to pick up a discounted meal can sometimes defeat the convenience factor" — Plenti analysis

**SaveBite Fix:** OSRM walking polyline route from student GPS to vendor with live distance + ETA. PostGIS-powered 2km radius means everything IS walkable.
**Size:** Already built (api_service.dart fetchWalkingRoute)

### 5. Food safety trust in India (10+ reviews, 2 sources)
> "Consumers skeptical about consuming day-old or surplus food due to fears of spoilage" — Plenti analysis
> "Fear of negative publicity... could lead to customer falling sick" — India market analysis

**SaveBite Fix:** FSSAI license verification on vendor registration + tamper-proof freshness guarantee in AI-generated description + vendor auto-suspend if rating < 3.0.
**Size:** S — Already in backend models (fssai_license field, rating + is_suspended)

---

## What Is Missing (Features people ask for)

1. **Dietary filters** (veg/vegan/gluten-free) — Plenti users want this. We have dietary_tag field but need filter UI.
2. **Impact dashboard** — Users want to know their environmental contribution. CO2/meals saved stats.
3. **Favourites** — TGTG has this. Users want notifications from preferred stores.
4. **Rating system** — Post-pickup star rating to build trust ecosystem.

---

## What Is Unsolved (Whole gaps competitors ignore)

1. **College campus hyperlocal** — Neither Plenti nor Good To Grab targets college campuses specifically. Campus canteens, hostel area vendors, food trucks near gates.
2. **AI-powered personalization** — No competitor uses AI for recommendations. Our /ai/recommend endpoint scores deals by discount%, budget, category, urgency.
3. **Real-time price transparency** — Nobody shows LIVE price decay. Users see a fixed discount. Our prices tick down every minute.

---

## The Positioning Angle

**For Indian college students who hate wasting money on mediocre campus food,
SaveBite rescues premium surplus mystery boxes from nearby vendors at prices that drop every minute — with AI safety verification so you know what you're getting into.**

Evidence: "surprise quality" (32 reviews, 3 sources), "food safety trust" (10 reviews, 2 sources), "campus hyperlocal" (unsolved gap).

---

## Build Priority (Fix Plan)

| # | What to build/fix | Size | Skill | Status |
|---|---|---|---|---|
| 1 | Rebuild Discover screen (S04) with proper design tokens | M | replica-build | NOW |
| 2 | Rebuild Store Detail (S06) with AI mystery description display | M | replica-build | NOW |
| 3 | Rebuild Checkout flow (S07) with live decay price | S | replica-build | NOW |
| 4 | Rebuild Orders screen (S09) with pickup countdown | S | replica-build | NOW |
| 5 | Fix Vendor Dashboard (S14) — overflow bugs + real verification | M | replica-build | NOW |
| 6 | Add dietary filter chips | S | feature | NEXT |
| 7 | Add impact counter to Profile (S12) | S | feature | NEXT |
| 8 | Web landing page — 3D animated showcase (not app embed) | L | separate | NEXT |
