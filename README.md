# UCSTGO Showcase & Feedback Kiosk App

An offline-first, animated feedback and rating kiosk for public showcase events. Visitors give emoji feedback, see a "Living Sketchbook" thank-you animation, then rate showcase projects. Data is captured locally first and silently synced to Supabase whenever connectivity returns.

> **Status:** 📘 Planning complete — awaiting confirmation before **Iteration 1**.
> **Single source of truth:** [`PROJECT_PROCESS.md`](PROJECT_PROCESS.md) — architecture, design system, tech stack, testing rules, iteration protocol, and the full 44-iteration roadmap live there.

---

## Quick links

| Document | Purpose |
|---|---|
| [PROJECT_PROCESS.md](PROJECT_PROCESS.md) | Canonical process plan (all sections, all iterations) |
| §0 in that file | Analysis of the brief + original→merged delta |
| §10 in that file | Execution plan: phase gates, dependency schedule, all 44 iteration cards |
| §14 in that file | Confirmations needed before Iteration 1 |

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

**Deployment:** Android phone first (development + iteration), Android TV / leanback kiosk last (Phase 6). No JS/HTML/CSS in the app.

---

## Roadmap at a glance

| Phase | Iterations | Focus |
|---|---|---|
| 0 — Foundation | 1–6 | Env, git, folder scaffold, design tokens, theme, `KioskScaffold` |
| 1 — Domain, Data & Local Persistence | 7–14 | Entities + `client_id`, repositories, Supabase, Drift schema/datasources, local-first repo |
| 2 — Offline Sync & Rate Limiting | 15–22 | Device ID, cooldown, connectivity, sync service, Edge Function, triggers |
| 3 — Feedback Flow UI | 23–29 | Emoji picker, focus/select, controller, thank-you, prompt, full screen |
| 4 — Rating Flow | 30–34 | Project card, carousel, sketch stars, rating controller, full screen |
| 5 — Phone Polish & Release | 35–38 | Rive, idle attract mode, cooldown UI, integration test + offline drill |
| 6 — TV Port & Hardening | 39–44 | Leanback manifest, D-pad, kiosk pinning, safe areas, TV E2E, signed APK |

**Total: 44 iterations (38 phone + 6 TV).** One meaningful change, one test, one commit each.

---

## Current repo state

- Flutter **3.47.9 stable** / Dart **3.13.7** (matches `pubspec.yaml`).
- Default counter scaffold: `lib/main.dart`, `test/widget_test.dart`.
- Dependencies not yet added; they land across early iterations (see §3 and §11 of the process doc).
- Git **not initialized** yet — Iteration 2.
- `web/` is unused scaffold; the app is Android-only.

---

## Key decisions locked

- **Architecture:** feature-first, `presentation → domain ← data`, Riverpod state, go_router navigation.
- **Offline-first:** Drift local queue, `client_id` UUID idempotency, status enum `pending / synced / rejected / failed_permanent`.
- **Connectivity:** `connectivity_plus` stream **plus** a 5s reachability probe to Supabase (captive-portal safe).
- **Rate limiting:** client cooldown + 2s double-tap throttle + server-side per-device/per-IP limits; offline replay is still server-checked.
- **Design:** "Living Sketchbook" — paper background, ink strokes, warm accents, overshoot easing, D-pad focusable from day one.

---

## Commands (Fedora)

```bash
flutter doctor -v                 # environment check
flutter test                      # run after EVERY iteration
flutter analyze                   # static checks
flutter pub add <packages>        # per §3 / §11 of the process doc
dart run build_runner build --delete-conflicting-outputs   # Drift codegen (Iteration 11)
flutter devices && flutter run    # phone testing
flutter build apk --release       # Phase 5 artifact
```

---

## Next step

Confirm the 10 items in [§14 of PROJECT_PROCESS.md](PROJECT_PROCESS.md), then reply **"go"**. Iteration 1 will verify the Flutter environment and confirm the default counter app runs. Nothing gets built until then. 🚀
