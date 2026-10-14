# 👥 Mystery Box (SaveBite) — 4-Member Project Division & Execution Plan

This document outlines the complete division of responsibilities, codebase ownership, planned feature allocations, and presentation viva topics for a **4-member engineering team**.

---

## 🏗️ High-Level System Architecture & Module Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       FULL STACK SYSTEM ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
     ┌─────────────────────────────────┴─────────────────────────────────┐
     ▼                                                                   ▼
┌───────────────────────────────┐                       ┌───────────────────────────────┐
│     MODULE 1: CORE BACKEND    │                       │     MODULE 2: DISTRIBUTED     │
│   & SPATIAL GEOFENCING (M1)   │                       │   ENGINE & DYNAMIC DECAY (M2) │
├───────────────────────────────┤                       ├───────────────────────────────┤
│ • PostgreSQL + PostGIS Docker │                       │ • Redis Atomic Locks (SETNX)  │
│ • ST_DWithin 2km Spatial SQL  │                       │ • Dynamic Time-Decay Formula  │
│ • Vendor & Student Schemas    │                       │ • Automated Price Updater     │
│ • Geofenced Push Pipeline     │                       │ • Order Completion Lifecycle  │
└───────────────────────────────┘                       └───────────────────────────────┘
     ▲                                                                   ▲
     │                                                                   │
     └─────────────────────────────────┬─────────────────────────────────┘
                                       │
     ┌─────────────────────────────────┴─────────────────────────────────┐
     ▼                                                                   ▼
┌───────────────────────────────┐                       ┌───────────────────────────────┐
│   MODULE 3: STUDENT FLUTTER   │                       │     MODULE 4: VENDOR PORTAL   │
│   EXPERIENCE & RADAR MAP (M3) │                       │     & AGENTIC AI ENGINE (M4)  │
├───────────────────────────────┤                       ├───────────────────────────────┤
│ • GPS Geolocator & OpenStreet │                       │ • Vendor Dashboard & Presets  │
│ • Interactive Radar Map       │                       │ • QR Pass Verification Modal  │
│ • Live Discover Feed & Search │                       │ • Autonomous AI Hunter Agent  │
│ • Digital Pickup Passes & QR  │                       │ • Smart Deal Drafter / AI     │
│ • Sustainability Impact UI    │                       │ • Impact & Carbon Accounting  │
└───────────────────────────────┘                       └───────────────────────────────┘
```

---

## 👤 Member 1 (You / Team Lead): Spatial Geofencing, Database Architecture & Core API

### 🎯 Primary Domain
**Spatial Database Engineering, Geospatial Queries & Core Backend Infrastructure**

### 📦 What Is Built & Handed Over
- Docker orchestration (`docker-compose.yml`) running PostgreSQL 15 with PostGIS.
- SQLAlchemy ORM data models (`backend/models.py`) with SRID 4326 PostGIS geometry points.
- Spatial geofencing service (`backend/services/geofence.py`) using `ST_DWithin` spatial indexing.
- Vendor registration & CRUD routing (`backend/routers/vendors.py`).
- Student location ingestion (`backend/routers/students.py`).

### 🚀 Planned Next Steps (Upcoming Features)
1. **Realistic Campus Seed Data**:
   - Write a seed script (`backend/scripts/seed_campus_data.py`) with 5 real food spots around your actual college campus (e.g., Campus Canteen, Nescafe/Cafe, Local Bakery, Kathi Roll corner).
2. **Notification Dispatch Pipeline**:
   - Enhance `backend/services/notifications.py` to simulate WebPush/SSE notifications when a deal falls within a student's 2km boundary.
3. **Database Performance Indexing**:
   - Add spatial GIST index benchmarking for PostGIS queries to present in the project report.

### 📁 Code Files Owned
- `docker-compose.yml`
- `backend/database.py`
- `backend/models.py`
- `backend/schemas.py`
- `backend/routers/vendors.py`
- `backend/routers/students.py`
- `backend/services/geofence.py`
- `backend/scripts/seed_campus_data.py` *(New)*

### 🎓 Defense & Viva Questions to Master
- *"Why use PostGIS POINT with SRID 4326 instead of regular float columns for latitude/longitude?"*
  *(Answer: PostGIS calculates true spherical distances on earth curved geoids using spatial indices (R-Tree/GIST), achieving O(log N) lookup speeds compared to slow O(N) Euclidean math on regular columns).*
- *"How does `ST_DWithin` determine which students get notified?"*

---

## 👤 Member 2: Distributed Inventory, Dynamic Decay Pricing & Concurrency Engine

### 🎯 Primary Domain
**Distributed Systems, High Concurrency Inventory Locking (Redis) & Algorithmic Pricing**

### 📦 What Is Built & Handed Over
- Redis connection client (`backend/redis_client.py`).
- Dynamic decay formula implementation (`backend/services/decay_pricing.py`).
- Periodic background pricing task (`periodic_pricing_updater` in `backend/main.py`).
- Atomic inventory reservation endpoint (`backend/routers/deals.py`) using Redis `DECR` and `SETNX` with 300s TTL.
- Deal redemption & completion verification (`POST /deals/{id}/complete`).

### 🚀 Planned Next Steps (Upcoming Features)
1. **Dynamic Decay 2.0 (Velocity-Aware Algorithm)**:
   - Upgrade the current linear decay formula in `decay_pricing.py` to account for remaining inventory velocity and closing urgency:
     `P(t) = max(P_min, P_start - (t_elapsed / t_total)^gamma * (P_start - P_min))`
2. **Double-Booking & Race Condition Benchmarking**:
   - Write a python stress test script simulating 50 concurrent students attempting to reserve the last remaining Mystery Box to prove the Redis atomic lock prevents overselling.
3. **Refund / TTL Expiration Handler**:
   - Handle key expiration events in Redis so cancelled/timed-out reservations automatically return inventory back to PostgreSQL.

### 📁 Code Files Owned
- `backend/redis_client.py`
- `backend/services/decay_pricing.py`
- `backend/routers/deals.py`
- `backend/tests/concurrency_stress_test.py` *(New)*

### 🎓 Defense & Viva Questions to Master
- *"How do you prevent race conditions when two students click 'Reserve' at the exact same millisecond?"*
  *(Answer: We use Redis atomic decrement `DECR` and distributed locks `SET NX EX 300`. Because Redis operates on a single-threaded in-memory event loop, atomic decrements guarantee that inventory never drops below zero and no two transactions can hold the same unit lock).*
- *"What happens if the student closes their browser without paying?"*
  *(Answer: The 5-minute TTL expires, clearing the lock key and restoring the box to the public listing).*

---

## 👤 Member 3: Student Experience, GPS Radar Map & Checkout Flow

### 🎯 Primary Domain
**Mobile Frontend Engineering (Flutter), Real-time Geolocation & Consumer UX**

### 📦 What Is Built & Handed Over
- Role selection screen (`mobile_app/lib/screens/role_selection.dart`).
- Student Shell navigation (`mobile_app/lib/screens/student_shell.dart`).
- Live Discover feed (`mobile_app/lib/screens/student_home.dart`) with search, category filtering chips, and modal sheets.
- Hyperlocal Radar Map (`mobile_app/lib/screens/student_map.dart`) with GPS tracking, 2km circular boundary layer, and interactive pin badges.
- Checkout screen (`mobile_app/lib/screens/checkout.dart`) with 5-minute countdown clock and UPI payment simulator.

### 🚀 Planned Next Steps (Upcoming Features)
1. **Interactive Walking Directions / Distance Pinning**:
   - Enhance the Radar Map so clicking a vendor displays distance and estimated walking time from the student's live pin to the shop.
2. **Onboarding Animations & Visual Polish**:
   - Modernize `mobile_app/lib/screens/onboarding.dart` with swipeable carousel cards and smooth hero transitions ("Too Good To Go" style).
3. **Simulated In-App Push Notification Banner**:
   - Add a top notification toast that slides down with sound/vibration whenever Member 1's backend triggers a geofence alert: *"Fresh Mystery Box listed 300m away at Gupta Bakery!"*.

### 📁 Code Files Owned
- `mobile_app/lib/screens/role_selection.dart`
- `mobile_app/lib/screens/onboarding.dart`
- `mobile_app/lib/screens/student_shell.dart`
- `mobile_app/lib/screens/student_home.dart`
- `mobile_app/lib/screens/student_map.dart`
- `mobile_app/lib/screens/checkout.dart`
- `mobile_app/lib/services/location_service.dart`

### 🎓 Defense & Viva Questions to Master
- *"How does the app fetch map tiles without relying on costly Google Maps API billing?"*
  *(Answer: We use `flutter_map` leveraging open-source OpenStreetMap raster tiles, styled with custom markers and vector circles, keeping the platform free and zero-cost for students).*
- *"How does the client-side 5-minute checkout timer stay synchronized with the Redis lock backend?"*

---

## 👤 Member 4: Vendor Portal, Digital Pickup Verification & Agentic AI Engine

### 🎯 Primary Domain
**Vendor Lifecycle, Digital QR Verification & Generative/Agentic AI Automation**

### 📦 What Is Built & Handed Over
- Vendor Partner Portal (`mobile_app/lib/screens/vendor_dashboard.dart`) with 1-tap presets and custom duration dropdown.
- Pickup Verification dialog for shopkeepers to redeem student boxes.
- My Pickups & Digital Passes screen (`mobile_app/lib/screens/student_orders.dart`).
- Sustainability Impact dashboard (`mobile_app/lib/screens/student_profile.dart`) calculating avoided CO₂ and rescued meals.
- AI Surplus Recommendation endpoint (`backend/routers/ai.py`).

### 🚀 Planned Next Steps (Upcoming Features)
1. **Autonomous "Surplus Rescue Hunter" Agent (Student Side)**:
   - Allow students to set agent goals: *"Auto-hold or alert me for bakery deals < ₹150 after 8:30 PM"*.
   - The agent continuously scores active deals in background and triggers reservation locks autonomously.
2. **Smart Deal Drafter (Vendor AI Assistant)**:
   - Add a "Magic Draft" button on the Vendor Dashboard. The vendor enters: *"4 chocolate donuts and 2 veg patties"* and Gemini/LLM drafts the original price, discount curve, and appetizing description automatically.
3. **Camera QR Code Scanner Handover**:
   - Integrate mobile camera scanning in the Vendor Portal to scan the student's QR code pass directly from phone-to-phone.

### 📁 Code Files Owned
- `backend/routers/ai.py`
- `mobile_app/lib/screens/vendor_dashboard.dart`
- `mobile_app/lib/screens/student_orders.dart`
- `mobile_app/lib/screens/student_profile.dart`
- `mobile_app/lib/services/order_manager.dart`
- `backend/services/agent_hunter.py` *(New)*

### 🎓 Defense & Viva Questions to Master
- *"How does the AI Assistant go beyond a basic chat interface?"*
  *(Answer: It functions as an autonomous optimization agent—it analyzes real-time decay pricing gradients, student budget constraints, geofence radius, and food carbon footprints to match surplus supply and demand before food goes to waste).*
- *"How is carbon offset calculated for rescued meals?"*

---

## 🗓️ Team Collaboration Sprints (Step-by-Step Schedule)

| Sprint / Day | Member 1 (Spatial Backend) | Member 2 (Distributed Systems) | Member 3 (Student Flutter) | Member 4 (Vendor & AI) |
| :--- | :--- | :--- | :--- | :--- |
| **Day 1: Environment & Setup** | Pull repo, verify Docker PostGIS, seed 5 campus food spots | Verify Redis container, run mock reservation test | Run Flutter Web/Chrome, test map pins & GPS | Test AI recommend endpoint & vendor presets |
| **Day 2: Feature Development** | Build notification dispatch logic & geofence trigger | Implement Decay 2.0 formula & stress testing script | Add walking distance indicators & polish card images | Build Smart Deal Drafter / AI hunter logic |
| **Day 3: Integration & Linking** | Connect vendor deals trigger to live student push | Sync Redis lock cleanup with order manager | Integrate simulated in-app notification banner | Integrate camera QR scan or PIN handover dialog |
| **Day 4: Demo Rehearsal** | Verify database reset scripts and data cleanliness | Monitor Redis keys during live test checkout | Test full student checkout run on screen 1 | Test vendor listing & QR redemption on screen 2 |
| **Day 5: Report & PPT Finalization** | Write Database & Spatial ER diagram chapter | Write Distributed Locking & Algorithms chapter | Prepare UI Wireframes & User Journey diagrams | Write AI/Agent Architecture & Sustainability section |

---

## 💡 Team Git Collaboration Guidelines

1. **Main Branch Protection**:
   - `main` branch remains stable and runnable at all times.
2. **Feature Branching Convention**:
   - Member 1: `git checkout -b feature/spatial-campus-seed`
   - Member 2: `git checkout -b feature/decay-pricing-engine`
   - Member 3: `git checkout -b feature/map-and-student-ux`
   - Member 4: `git checkout -b feature/ai-agent-vendor-portal`
3. **Merging**:
   - Pull latest `main` before submitting a PR or merging: `git pull origin main`.
