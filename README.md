# UCSTGO Showcase & Feedback Kiosk App

An offline-first, animated feedback and rating kiosk for public showcase events. Visitors give emoji feedback, see a "Living Sketchbook" thank-you animation, then rate showcase projects. Data is captured locally first and silently synced to Supabase whenever connectivity returns.

> **Status:** 🚧 In progress — Phase 0 complete (M1), Phase 1 underway (domain contracts done; Drift queue next).
> **Single source of truth:** [`PROJECT_PROCESS.md`](PROJECT_PROCESS.md) — architecture, design system, tech stack, testing rules, iteration protocol, and the full 44-iteration roadmap live there.

---

## Quick links

| Document | Purpose |
|---|---|
| [PROJECT_PROCESS.md](PROJECT_PROCESS.md) | Canonical process plan (all sections, all iterations) |
| §0 in that file | Analysis of the brief + original→merged delta |
| §10 in that file | Execution plan: phase gates, dependency schedule, all 44 iteration cards |
| §0.5 in that file | Build-order decision: offline first, Supabase in Phase 6, TV last |

---

## What we're building (in one picture)

```text
Visitor taps emoji
      │
      ▼
┌──────────────────────┐
│ 1. Write to LOCAL DB │  Drift / SQLite, status = pending (durable)
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 2. Instant Thank-You │  Never blocked by the network
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 3. Rate projects     │  Polaroid cards + sketch stars
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 4. Background sync   │  On start / reconnect / every 5 min
│    → Supabase        │  client_id UUID = idempotent, no duplicates
└──────────────────────┘
```

**Deployment:** Android phone first (development + iteration), Android TV / leanback kiosk last (Phase 7). The app is fully functional offline; Supabase is attached in Phase 6. No JS/HTML/CSS in the app.

---

## Roadmap at a glance

| Phase | Iterations | Focus |
|---|---|---|
| 0 — Foundation | 1–6 | Env, git, folder scaffold, design tokens, theme, `KioskScaffold` |
| 1 — Domain & Local Persistence | 7–11 | Entities + `client_id`, contracts, Drift queue, local datasource, local-first repo |
| 2 — Offline Sync & Guardrails | 12–17 | Device ID, cooldown, connectivity, DTO/remote seam, sync service, triggers |
| 3 — Feedback Flow UI | 18–24 | Emoji picker, focus/select, controller, thank-you, prompt, full screen |
| 4 — Rating Flow | 25–29 | Project card, carousel, sketch stars, rating controller, full screen |
| 5 — Phone Polish & Offline Release | 30–33 | Rive, idle attract mode, cooldown UI, integration test + offline drill + APK |
| 6 — Cloud Backend & Live Sync | 34–38 | Supabase schema/RLS, Edge Functions, live remote datasource, online drill |
| 7 — TV Port & Hardening | 39–44 | Leanback manifest, D-pad, kiosk pinning, safe areas, TV E2E, signed APK |

**Total: 44 iterations (38 phone + 6 TV).** One meaningful change, one test, one commit each. Phases 1–5 need **no backend at all**.

---

## Current repo state

- Flutter **3.47.9 stable** / Dart **3.13.7** (matches `pubspec.yaml`).
- **M1 complete:** design tokens, `AppTheme`, `KioskScaffold` (26 tests).
- **M2 complete (Phase 1):** local-first pipeline — domain entities, contracts, Drift queue, queue CRUD, `FeedbackRepositoryImpl` with an unplugged remote seam (**80 tests**).
- **Phase 2 complete (M3):** `DeviceIdService`, `CooldownService`, `ConnectivityService`, `FeedbackModel` (exact §6.2 DTO + §6.6 table), `SyncService` (serial drain + 2→60s backoff), `SyncScheduler` (four coalesced triggers) — **149 tests**, still zero network required.
- **Next:** Iteration 18 — **UI begins**: static `EmojiPicker` with three sketch-outlined faces.
- Dependencies land per iteration; see §10.2 of the process doc.
- Git initialized with `origin` configured; every iteration commits.
- `web/` is unused scaffold; the app is Android-only.

---

## Key decisions locked

- **Architecture:** feature-first, `presentation → domain ← data`, Riverpod state, go_router navigation.
- **Offline-first:** Drift local queue, `client_id` UUID idempotency, status enum `pending / synced / rejected / failed_permanent`.
- **Connectivity:** `connectivity_plus` stream **plus** a 5s reachability probe (captive-portal safe; Supabase URL wired in Phase 6).
- **Rate limiting:** client cooldown + 2s double-tap throttle + server-side per-device/per-IP limits; offline replay is still server-checked.
- **Design:** "Living Sketchbook" — paper background, ink strokes, warm accents, overshoot easing, D-pad focusable from day one.

---

## Commands (Fedora)

```bash
flutter doctor -v                 # environment check
flutter test                      # run after EVERY iteration
flutter analyze                   # static checks
flutter pub add <packages>        # per §3 / §11 of the process doc
dart run build_runner build --delete-conflicting-outputs   # Drift codegen (Iteration 9)
flutter devices && flutter run    # phone testing
flutter build apk --release       # Phase 5 artifact
```

---

## Next step

**Iteration 18:** static `EmojiPicker` — three sketch-outlined faces (`CustomPainter`, tokens only, semantic labels, 10-foot sizing), render-only. **The UI starts here.** See [§10.6 of PROJECT_PROCESS.md](PROJECT_PROCESS.md). 🚀
