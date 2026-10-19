# Recon map: Too Good To Go (Mobile — iOS/Android)

Scope: Consumer app (browse → reserve → pickup mystery bag) + Vendor dashboard (manage bags → confirm pickups)
For: SaveBite — a campus/hyperlocal food rescue marketplace (college mini-project, positioned as the improved Indian alternative)
Date: 2026-10-19

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | Marketing site | toogoodtogo.com | Core loop, positioning, pricing model |
| 2 | App Store listing | App Store / Google Play | Screenshots, feature list, ratings |
| 3 | Help center | toogoodtogo.com/support | Full feature documentation |
| 4 | Public reviews | App Store, G2, Reddit | Pain points, feature gaps |
| 5 | Design reference | pizza-amici.nl | Design inspiration — warm matte aesthetic, custom card shapes, smooth scroll animations |
| 6 | Design reference | Dribbble (Batch app) | Papermorphism, matte surfaces, organic shapes |

## Core loop

**User browses nearby stores with surplus food → reserves a Surprise Bag at ~1/3 retail price → picks it up during a strict time window → vendor confirms pickup via swipe/code.**

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Splash / Loading | App launch | Brand moment, auth check | Logo animation, loading spinner | loading, authenticated redirect |
| S02 | Onboarding | First launch only | Explain value prop (3 slides) | PageView, hero image, dot indicators, CTA button | page 1/2/3, skip |
| S03 | Login / Sign Up | After onboarding or logout | Auth with email/social | Email input, password, social buttons, terms checkbox | empty, filled, error, loading |
| S04 | Discover (List) | Tab 1 — default home | Browse nearby surprise bags | Category chips, deal cards, pull-to-refresh, search bar | loading, empty (no nearby), filled, filtered |
| S05 | Discover (Map) | Toggle on S04 | Map-based browsing | Map with pins, bottom sheet with cards, locate-me FAB | loading, pins visible, selected pin, no results |
| S06 | Store Detail | Tap a deal card | View store info + bag details | Store header image, rating, pickup window, price badge, reserve button, favourite heart | available, sold out, favourited, loading |
| S07 | Checkout | Tap "Reserve" on S06 | Confirm + pay | Order summary, payment method selector, total, confirm button | ready, processing, success, error, sold-out-interrupt |
| S08 | Order Confirmation | After successful checkout | Show pickup code + details | Pickup code (large), vendor name, pickup window, map preview, "Ask a Friend" share, swipe-to-collect slider | waiting for pickup, ready to swipe |
| S09 | Active Orders | Tab 2 | Track current reservations | Order cards with countdown, status badge, pickup code peek | empty (no orders), 1+ orders, order completed |
| S10 | Order Complete | After swipe-to-collect | Confirm handoff, prompt rating | Success animation, receipt summary, star rating, CO₂ saved stat | unrated, rated |
| S11 | Favourites | Tab 3 or heart icon | Saved stores | Store cards with notification bell, distance | empty, filled |
| S12 | Profile / Settings | Tab 4 | Account management | Avatar, impact stats (meals saved, CO₂), payment methods, preferences, logout | filled, editing |
| S13 | Impact Dashboard | Inside Profile | Gamified environmental impact | Meals saved counter, CO₂ avoided, equivalence illustrations | zero state, populated |
| S14 | Vendor: Dashboard | Vendor app home | Today's overview | Active bags count, reserved count, collected count, pickup window, edit supply button | no bags today, bags available, all collected |
| S15 | Vendor: Manage Supply | Edit on S14 | Set daily bag count + window | Number stepper, time picker, price input, save button | empty, filled, saved confirmation |
| S16 | Vendor: Confirm Pickup | Customer arrives | Verify pickup code | Code input / scanner, customer name, order details, confirm button | waiting, code entered, verified, invalid code |
| S17 | Vendor: History | Tab on vendor side | Past orders + revenue | Order list with date, amount, status filters | empty, filtered, populated |

## Flows

```
F01 Student discovers and reserves a surprise bag
    S04 (browse) → S06 (store detail) → S07 (checkout) → S08 (confirmation)
    happy path clicks: 4
    edge: sold out during checkout, payment failure, no bags near user, student already has active order at same store

F02 Student picks up surprise bag
    S09 (active orders) → S08 (order detail with code) → swipe-to-collect → S10 (complete + rate)
    happy path clicks: 3
    edge: missed pickup window (auto-cancel), vendor cancels, wrong code

F03 Student browses via map
    S04 → toggle to S05 (map) → tap pin → S06 (store detail) → S07 (checkout)
    happy path clicks: 5
    edge: location permission denied, no stores in area, GPS inaccuracy

F04 Student manages favourites
    S04/S06 → tap heart → S11 (favourites list) → tap store → S06
    happy path clicks: 3
    edge: empty favourites

F05 Vendor sets daily supply
    S14 (dashboard) → S15 (manage supply) → set count + window → save
    happy path clicks: 3
    edge: zero bags, overlapping windows, edit after reservations started

F06 Vendor confirms customer pickup
    S14 → S16 (confirm pickup) → enter/scan code → verify → confirmed
    happy path clicks: 3
    edge: invalid code, already collected, customer no-show

F07 Vendor reviews history
    S14 → S17 (history) → filter by date → view details
    happy path clicks: 3
    edge: no history, very long list
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| DealCard | horizontal (list), vertical (grid), compact (map bottom-sheet) | default, loading shimmer, sold-out (greyed), favourite-heart toggle | S04, S05, S11 |
| CategoryChip | selected, unselected | default, active | S04 |
| PriceTag | discount badge, original strikethrough | filled | S04, S06, S07 |
| PickupWindow | today, tomorrow, time range | available, closed, urgent (< 1hr) | S06, S08, S09, S14 |
| ReserveButton | primary CTA | enabled, disabled (sold out), loading | S06 |
| PickupCode | large display, mini peek | visible, hidden | S08, S09 |
| SwipeToCollect | slider | idle, swiping, confirmed | S08 |
| StarRating | 1-5 stars | unrated, rated, disabled | S10 |
| ImpactCounter | meals saved, CO₂ avoided | zero, counting up animation | S12, S13 |
| BottomNav | 4 tabs (student), 3 tabs (vendor) | active tab highlighted | all student screens, all vendor screens |
| MapPin | available (green), sold-out (grey), selected (enlarged) | default, selected, cluster | S05 |
| VendorStatCard | bags available, reserved, collected | zero, positive count | S14 |
| OrderCard | active, completed, cancelled | default, countdown ticking | S09 |
| SearchBar | with icon, clear button | empty, typing, results | S04 |
| PaymentMethod | card, UPI, wallet | selected, unselected | S07 |
| StoreHeader | hero image, overlay gradient, back button, heart | loaded, placeholder | S06 |
| Toast/Snackbar | success, error, info | visible (auto-dismiss) | global |
| Modal | confirmation, error, share | open, closed | S07, S08 |
| EmptyState | illustration + message + CTA | visible when 0 items | S04, S09, S11, S17 |

## Inferred data model

```
User        id, name, email, password_hash, phone, avatar_url, role (student|vendor), 
            created_at, updated_at
            evidence: S03 registration, S12 profile
            confidence: high

Vendor      id, user_id (FK), shop_name, shop_category, description, image_url, 
            address, latitude, longitude, rating, total_ratings, is_active
            evidence: S06 store detail, S14 vendor dashboard
            confidence: high

Deal        id, vendor_id (FK), title, description, original_price, discount_price,
            quantity_total, quantity_remaining, pickup_start, pickup_end,
            dietary_tag, image_url, status (active|sold_out|expired), created_at
            evidence: S04 deal cards, S06 detail, S15 manage supply
            confidence: high

Order       id, deal_id (FK), student_id (FK), pickup_code, status (reserved|collected|cancelled|expired),
            paid_price, original_value, created_at, collected_at
            evidence: S07 checkout, S08 confirmation, S09 orders, S16 vendor verify
            confidence: high

Favourite   id, user_id (FK), vendor_id (FK), created_at
            evidence: S06 heart toggle, S11 favourites list
            confidence: high

Rating      id, order_id (FK), user_id (FK), stars (1-5), comment, created_at
            evidence: S10 post-pickup rating
            confidence: high

ImpactStats user_id, total_meals_saved, total_co2_saved_kg, total_money_saved
            evidence: S12 profile, S13 impact dashboard
            confidence: medium (could be computed on-the-fly)
```

Relationships: User 1→1 Vendor (if vendor role), User 1→n Order, Vendor 1→n Deal, Deal 1→n Order, User 1→n Favourite, Order 1→1 Rating

## Feature matrix

See `features.csv`. Must: 18, should: 8, could: 6, skip: 3.

## Out of scope (cannot or should not be cloned)

- **TGTG's store network** — their 200K+ partner stores and user base are their moat, not a feature
- **TGTG's brand / logo / marketing copy** — we use SaveBite brand
- **TGTG Platform (enterprise)** — AI-powered expiry management for supermarket chains
- **Payment processing partnerships** — we'll use Razorpay (India) instead of Stripe/Apple Pay
- **Push notifications infrastructure** — requires Firebase Cloud Messaging setup (Phase 2)

## Size

Screens 17, flows 7, entities 6. Hard parts: real-time inventory sync (stock going to 0 mid-checkout), map with walking routes, pickup code verification flow with swipe-to-collect, decay pricing algorithm. Size: **M** (a few weeks with focused effort).
