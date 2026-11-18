# PROJECT_PROCESS.md — Showcase & Feedback Kiosk App

> **This file is the single source of truth for the project.**
> Version 2.1 — Offline-first build order (cloud deferred to Phase 6). Last updated: 2026-11-18.
> Status: **In progress — Phase 1 (Iterations 7–8 done; 9 next).**
> Every future iteration message references this document (e.g. "Per §2.2.3, this iteration ships with a test").
> If we ever disagree about a decision, we update this document **first**, then implement.

---

## 0. Brief analysis & merge notes

### 0.1 What was analyzed

Two inputs were consolidated into this document:

1. **Master Process Prompt (v1)** — 40 iterations / 6 phases / phone-first kiosk app, with a full design system, architecture, testing discipline and iteration protocol.
2. **Offline-First Update (v2)** — a set of *delta patches* that revise v1: local Drift database, connectivity detection, background sync, `client_id` idempotency, and a revised 44-iteration roadmap.

The offline update was written as patches. That is intentional for a chat message but **dangerous as a standing document** (two sources drift apart). So every patch has been applied inline below. There is now exactly one roadmap, one tech stack, one schema, one architecture diagram.

### 0.2 Step-by-step reasoning of the plan

1. **Phone first, TV last.** The app must be usable and validated on a phone (Iteration 1–38); TV hardening (39–44) is a port of a working app, not a parallel track. This de-risks the hardest UI work early.
2. **Feature-first + layered architecture.** `presentation → domain ← data`. Presentation never imports `data/`; data implements abstract domain repositories. A full visual redesign therefore only touches `core/theme/` + `features/*/presentation/widgets/`.
3. **Offline-first because the venue is unreliable.** A lost Wi-Fi connection must never mean a lost data point. The visitor sees the same instant Thank-You whether online or offline; sync is invisible background work.
4. **Idempotency by construction.** Every submission gets a client-generated `client_id` UUID *before* it enters the local DB. The same UUID is the remote primary/dedupe key, so retries produce `ON CONFLICT DO NOTHING`, never duplicates.
5. **Drift over Isar/Hive/sqflite.** We need typed queries like `WHERE sync_status = 'pending' ORDER BY created_at`, reactive streams, and an in-memory DB for tests. Drift is the only option that gives all three.
6. **Server stays authoritative.** Client cooldown is UX; server rate limits are the law. If a kiosk accumulates 50 offline submissions, the Edge Function rejects the overflow with 429 on replay and those rows are dropped as `rejected`. Correct behavior.
7. **Micro-iterations + mandatory tests.** One meaningful change per iteration, at least one automated test, `flutter test` after every iteration, confirmation before the next, commit & push each time. The offline logic increases the count from 40 → 44 because sync bugs are exactly the kind that hide in combined changes.
8. **D-pad readiness from day one.** Even on phone, interactive widgets use `FocusableActionDetector` / focusable `InkWell`, never `GestureDetector`-only. TV work in Phase 7 becomes tuning, not rewriting.

### 0.3 Original → merged delta (what changed)

| Area | v1 (original) | v2 (this document) |
|---|---|---|
| Roadmap | 40 iterations | **44 iterations** (offline-first added 4) |
| Local DB | none | **Drift** (`drift`, `drift_flutter`, `drift_dev`) |
| Connectivity | none | **connectivity_plus** + reachability probe |
| Sync | none | **SyncService** with exponential backoff |
| Dedupe key | `id` (server-generated) | **`client_id` UUID, client-generated, UNIQUE** |
| Schema | `feedback`, `ratings`, `rate_limits` | + `client_id uuid UNIQUE NOT NULL` on both data tables |
| Edge Function | plain insert + rate limit | **`INSERT … ON CONFLICT (client_id) DO NOTHING`**, 409 treated as success |
| Repository write | remote-first | **local-first write, best-effort remote, instant UI success** |
| Tests | standard | + explicit offline path test per repository / use case |
| Sync triggers | n/a | app start, connectivity regained, every 5 min, after each write |

### 0.4 Repo-specific notes (reality check)

- Actual package / directory: `ucstgo_showcase_flutter_app`. The `showcase_app/` name in §4.1 is illustrative; all `lib/` subpaths are identical.
- Measured environment: **Flutter 3.47.9 stable**, **Dart 3.13.7**, matching `pubspec.yaml` (`sdk: ^3.13.7`).
- Git is initialized; remote `origin` configured in Iteration 2; every iteration ends with a commit (§12).
- `web/` exists from the `flutter create` scaffold but is **unused**. No JS / HTML / CSS in the app (§2.3, §3).
- Foundation complete: tokens/theme/`KioskScaffold` (M1) plus domain entities and repository contracts (I7–I8, 56 tests). Next: Drift queue (I9).

### 0.5 Build-order decision (2026-11-18) — offline-first, cloud later

**Decision:** build and release the entire app **without Supabase first** (Phases 1–5), then attach Supabase in a dedicated cloud phase (Phase 6), and keep the TV port last (Phase 7).

**Why:**

1. **The local queue is the source of truth.** §6.4 makes Drift durable-first and the remote best-effort. The app's correctness — thank-you always appears, nothing is lost — can therefore be built and verified with zero backend. Supabase is an *attachment*, and attachments are cheaper to add to a working system than to develop against.
2. **No cloud account blocks the build.** Iterations 9–33 (25 of 44) run completely offline: no project, no keys, no deploy, no network flakiness in the test loop. The only Supabase prerequisites move to I34/I36.
3. **Fakes prove the contract earlier.** SyncService, backoff, and the §6.6 outcome matrix are tested against a typed `FeedbackRemoteDataSource` fake. When the real Supabase datasource lands at I38 it must satisfy an **already-tested** contract — and no UI, controller, or domain edits are allowed.
4. **A demo exists sooner.** M6 (I33) yields a release APK with the full flow and a proven offline drill. If the venue network never works, the app still ships and still captures data locally.
5. **Cloud risk is isolated.** Schema/RLS, Edge Functions, and rate limits land in one phase (I34–I38) with their own curl/drill evidence instead of being interleaved through the app build.

**What does not change:** the 44-iteration total, the 38-phone / 6-TV split, the architecture (§4), the schema (§6.1), the sync semantics (§6.4–§6.8), and every test discipline (§8–§9). Only the **order** changed.

**Trade-off accepted:** until Phase 6 the queue only grows and never drains; the I33 drill asserts exactly that. This is intentional and by design, not a missing feature.

---

## 1. Project Charter

### 1.1 What We're Building

A visually rich, animated feedback and rating application for public showcase events. Visitors to the showcase will:

- See an attractively animated **idle** screen that invites interaction.
- Select an emoji to give quick feedback (satisfied / neutral / dissatisfied, expandable later).
- See a **thank-you** animation.
- Be prompted to **rate specific showcase projects**.
- Rate projects using an animated rating widget.
- All data is silently collected for later visualization — **online or offline**.

### 1.2 Deployment Targets (in order)

| Phase | Target | Purpose |
|---|---|---|
| Primary | Android phone | Development, iteration, manual testing |
| Secondary | Android TV (leanback kiosk) | Final deployment at showcase |
| Future (out of scope) | Web dashboard | Data visualization (separate project) |

Development starts on phone. Every UI iteration is validated on phone first. TV-specific hardening (D-pad focus tuning, kiosk mode, leanback manifest) is applied in a dedicated late phase (Phase 7).

### 1.3 Success Criteria

- Full flow (feedback → thank-you → rating prompt → rating) works end-to-end.
- Zero crashes during a sustained showcase (target: **8 hours unattended**).
- Visuals are "fancy, doodle-rich, smooth" — locked **60fps** on target hardware.
- Every submission is captured **exactly once** to Supabase (idempotent via `client_id`).
- No data is lost when the network drops — local queue drains on reconnect.
- Rate limiting prevents abuse (rapid taps, kiosk hogging) — client and server.
- The UI can be fully redesigned by only editing `core/theme/` + `features/*/presentation/widgets/`, without touching domain or data layers.

---

## 2. Non-Negotiable Principles

These rules govern every decision. If a shortcut violates one, we don't take it.

### 2.1 Architecture

1. **Separation of concerns.** UI ≠ logic ≠ data. A UI redesign must never require touching `domain/` or `data/`.
2. **Feature-first organization.** Each feature (feedback, rating, showcase) owns its full stack: domain → data → presentation.
3. **Dependency inversion.** Repositories are abstract interfaces in `domain/`; implementations live in `data/`.
4. **Design tokens over hardcoded values.** No `Color(0xFF...)`, no `TextStyle(fontSize: 17)` scattered in widgets. Everything comes from `core/theme/`.
5. **No `setState` for shared state.** Local ephemeral state (e.g. a focus index in a single widget) may use `setState`. Anything the app cares about goes through Riverpod.
6. **Local-first writes.** A submission is durable in Drift *before* any network call. UI success is never blocked by connectivity.

### 2.2 Development Workflow

1. **Micro-iterations.** One iteration = one meaningful, testable change. Never combine unrelated features.
2. **Test-driven.** Every iteration ships with at least one automated test. No exceptions.
3. **Confirm before continuing.** Each iteration ends with you running the test and confirming before the next begins.
4. **Explain, don't dump code.** Every code block is accompanied by what it does, why it exists, and how it connects.
5. **Commit & push each iteration.** Every completed + confirmed iteration ends with `git add . && git commit && git push`.

### 2.3 Platform Discipline

1. **Phone-first.** All flows validated on Android phone before TV work begins.
2. **TV-ready architecture.** Even in the phone phase, every interactive widget is written with D-pad focusability in mind (no `GestureDetector`-only interactions; use `FocusableActionDetector` or `InkWell` with proper focus nodes).
3. **Assume low-end hardware.** Target Android 8+ (API 26+) with limited GPU. Cap particle counts, test performance early.

### 2.4 Data & Privacy

1. **No user accounts.** Identification is anonymous (device UUID + IP hash).
2. **No PII.** Never store raw IPs, no names, no emails, no location.
3. **Rate limit by default.** Every submission endpoint has rate limiting before it touches the feedback table — including replayed offline submissions.

---

## 3. Tech Stack (Locked)

| Layer | Technology | Rationale |
|---|---|---|
| Framework | Flutter (latest stable) | Single codebase, native rendering, TV support |
| Language | Dart 3.x (sound null safety) | Required by Flutter |
| State management | `flutter_riverpod` | Testable, no BuildContext leak, great for domain separation |
| Navigation | `go_router` | Declarative, testable, handles both phone and TV |
| Animations (interactive) | Rive (`rive`) | State machines, small files, GPU-efficient |
| Animations (decorative) | Lottie (`lottie`) | Only lightweight loops; avoid heavy files on TV |
| Animations (declarative) | `flutter_animate` | Entrance effects, staggers, sequencing |
| Custom graphics | `CustomPainter` + `AnimationController` | Doodle art, procedural effects |
| Doodle annotations | `rough_notation` | Sketchy highlight boxes, underlines |
| Sketch image entrance | `sketchify` | Line-drawing animation for logos |
| Rating widget | `fancy_rating_bar` (optional) | Evaluate in Phase 4; may build custom for full control |
| Fonts | `google_fonts` | Zero-asset setup; lock family in Phase 0 |
| **Local DB** | **Drift (`drift`, `drift_flutter`, `drift_dev` dev-dep)** | Type-safe SQLite, reactive streams, testable in-memory queue |
| **Connectivity** | **`connectivity_plus`** | Network-change stream to trigger sync |
| **Backoff** | **Manual exponential (no extra package)** | Simple, we control 2s → 60s schedule |
| Rate limiting (client) | Custom `CooldownService` + `shared_preferences` | Persistent 30s cooldown with an injectable clock (`limit` rejected: hardcodes `DateTime.now`, untestable) |
| Kiosk mode | `screen_pinning` | TV-only, Phase 7 |
| Device ID | `uuid` + `shared_preferences` | Anonymous persistent identity |
| Backend | Supabase (`supabase_flutter`) | Postgres + Edge Functions + real-time (future dashboard) |
| Server rate limiting | Supabase Edge Function (Deno/TS) | IP hash + device check before insertion |
| Testing | `flutter_test`, `mocktail`, `integration_test` | Unit, widget, E2E |
| Linting | `flutter_lints` + custom rules | Enforces architectural boundaries |
| CI | (Optional — TBD) | GitHub Actions can be added later |
| Environment | Fedora Linux, Bash | All commands are Fedora-compatible |

**No JS / HTML / CSS in the app. Confirmed for kiosk performance.**

---

## 4. Architecture

### 4.1 Folder Structure (Canonical)

```text
showcase_app/                         # in this repo: ucstgo_showcase_flutter_app/
├── lib/
│   ├── main.dart                     # Bootstraps ProviderScope, Supabase, app
│   ├── app.dart                      # Root widget, router wiring
│   │
│   ├── core/                         # Shared across features
│   │   ├── domain/                   # Shared pure-Dart contracts
│   │   │   ├── sync_status.dart      # pending/synced/rejected/failed_permanent
│   │   │   └── submission_result.dart # local-first submit outcome
│   │   ├── theme/
│   │   │   ├── app_colors.dart       # Color tokens
│   │   │   ├── app_typography.dart   # Text style tokens
│   │   │   ├── app_spacing.dart      # Spacing scale (4/8/12/16…)
│   │   │   └── app_theme.dart        # Composed ThemeData
│   │   ├── router/
│   │   │   └── app_router.dart       # go_router config
│   │   ├── widgets/                  # Reusable dumb widgets
│   │   │   ├── sketch_button.dart
│   │   │   ├── kiosk_scaffold.dart
│   │   │   └── ...
│   │   └── utils/                    # Pure helpers, extensions
│   │
│   ├── services/                     # App-wide singletons (Riverpod providers)
│   │   ├── supabase_service.dart
│   │   ├── device_id_service.dart
│   │   ├── cooldown_service.dart
│   │   ├── connectivity_service.dart # connectivity_plus + reachability probe
│   │   ├── sync_service.dart         # Drains pending queue with backoff
│   │   └── kiosk_service.dart
│   │
│   └── features/
│       ├── feedback/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── emoji_choice.dart
│       │   │   │   └── feedback.dart          # includes clientId
│       │   │   ├── repositories/
│       │   │   │   └── feedback_repository.dart   # Abstract
│       │   │   └── usecases/
│       │   │       └── submit_feedback.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   └── feedback_model.dart        # JSON DTO
│       │   │   ├── datasources/
│       │   │   │   ├── feedback_remote_datasource.dart
│       │   │   │   └── feedback_local_datasource.dart  # Drift CRUD
│       │   │   ├── local/
│       │   │   │   ├── app_database.dart           # Drift database class
│       │   │   │   └── tables/
│       │   │   │       ├── pending_feedback_table.dart
│       │   │   │       └── pending_ratings_table.dart
│       │   │   └── repositories/
│       │   │       └── feedback_repository_impl.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   └── feedback_screen.dart
│       │       ├── widgets/
│       │       │   ├── emoji_picker.dart
│       │       │   ├── thank_you_card.dart
│       │       │   └── rate_projects_prompt.dart
│       │       └── controllers/
│       │           └── feedback_controller.dart   # Riverpod notifier
│       ├── rating/                  # Same structure
│       └── showcase/                # Same structure
│
├── test/                            # Mirrors lib/ structure
│   ├── core/
│   ├── services/
│   └── features/
├── integration_test/                # Phone E2E (Phase 5), TV E2E (Phase 7)
├── supabase/                        # Edge Functions (Phase 6)
│   └── functions/
│       ├── submit-feedback/
│       └── submit-rating/
├── android/
├── pubspec.yaml
├── analysis_options.yaml
└── PROJECT_PROCESS.md               # This document
```

### 4.2 Layer Communication Rules

```text
┌──────────────────────────────────────────────────────────┐
│  Presentation (Widgets, Screens, Controllers)            │
│  ▸ Reads/writes state via Riverpod providers             │
│  ▸ NEVER calls Supabase directly                         │
│  ▸ NEVER imports from data/ — only domain/               │
└──────────────────────────┬───────────────────────────────┘
                           │ calls UseCase / reads Entity
┌──────────────────────────▼───────────────────────────────┐
│  Domain (Entities, Repositories, UseCases)               │
│  ▸ Pure Dart, no Flutter, no Supabase imports            │
│  ▸ Repositories are abstract interfaces                  │
└──────────────────────────┬───────────────────────────────┘
                           │ implemented by
┌──────────────────────────▼───────────────────────────────┐
│  Data (Models, DataSources, RepositoryImpls, Drift)      │
│  ▸ Talks to Supabase / Supabase Edge Functions           │
│  ▸ Maps DTOs ⇄ Entities                                  │
│  ▸ Implements domain/ repositories                       │
└──────────────────────────────────────────────────────────┘
```

**Rule of thumb:** If you can import `package:supabase_flutter` from a file, that file belongs in `data/` or `services/`, never in `presentation/` or `domain/`.

#### Local-first write flow (data layer)

```text
FeedbackRepositoryImpl receives Feedback(clientId, ...)
   │
   ├─ 1. local.save(feedback)  → durable row, status = pending
   ├─ 2. remote.submit(feedback)  ← attempted if ConnectivityService says online
   │      ├─ success (200/409)  → local.markSynced(clientId)
   │      └─ failure (network/5xx) → leave as pending, swallow error
   └─ 3. return Success to UI  ← regardless of remote result
```

### 4.3 Test Layer Placement

| Layer | Test type | Location |
|---|---|---|
| `domain/` (entities, usecases) | Pure test, no Flutter | `test/features/*/domain/` |
| `data/` (repos, datasources) | Unit test with `mocktail` | `test/features/*/data/` |
| `presentation/` (widgets) | Widget test | `test/features/*/presentation/` |
| `services/` | Unit test with fakes | `test/services/` |
| Full flows | Integration test | `integration_test/` (Phase 5 phone, Phase 7 TV) |

---

## 5. Design System — "Living Sketchbook"

### 5.1 Design Language Summary

| Aspect | Specification |
|---|---|
| Concept | Hand-drawn whiteboard brought to life. Warm, playful, inviting. |
| Background | Off-white paper `#F7F3EA` with faint grid dots. Slow pencil-shaving particle drift. |
| Idle / Attract mode | Pencil draws welcome text stroke by stroke, loops every ~20s. |
| Emoji feedback | Three sketch-outlined faces. Focus = re-draw outline + bouncing pencil tip. Select = wobbly pop + hand-drawn heart/star. |
| Thank you | Doodled character walks in, waves, speech bubble scribbles "Thank you!" |
| Rating screen | Projects as polaroid cards with hand-drawn tape. Stars draw in on tap. |
| Cooldown screen | Designed "catch your breath" moment — doodled clock ticking down. Never a grayed-out disabled button. |
| Motion feel | Overshoot/elastic easing everywhere. Never linear. |

### 5.2 Color Tokens (`app_colors.dart`)

| Token | Hex | Usage |
|---|---|---|
| `paperBackground` | `#F7F3EA` | Main background |
| `paperShadow` | `#E5DFD0` | Card shadows |
| `inkPrimary` | `#2B2B2B` | Primary text, sketch strokes |
| `inkSecondary` | `#5C5C5C` | Body text |
| `accentWarm` | `#FF6B4A` | Primary accent, active highlights |
| `accentSky` | `#7FB5D6` | Secondary accent |
| `accentSage` | `#A8C09A` | Positive feedback |
| `accentBlush` | `#F5A8A0` | Negative feedback |
| `paperWhite` | `#FFFFFF` | Card surfaces |
| `idleGlow` | `#FFD166` | Idle-mode glow accent |

### 5.3 Typography Tokens (`app_typography.dart`)

- **Display (TV headlines):** 48–64sp, sketch-style custom font (Caveat or Patrick Hand via `google_fonts`).
- **Headline:** 32–40sp.
- **Body:** 20–24sp (10-foot readability).
- **Caption:** 16sp minimum.

Load via `google_fonts` for now (zero-asset setup). Lock a family in Phase 0 / Iteration 4.

### 5.4 Spacing Scale (`app_spacing.dart`)

`xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48, huge=64`

### 5.5 TV Safe Areas (Applied in Phase 7)

- Overscan margin: **5% on all sides minimum**.
- Min focusable size: **120dp height**.
- Min text size: **32sp** for anything visitors must read.

---

## 6. Data & Backend

### 6.1 Supabase Schema (Reference — created in Iteration 34)

**Table: `feedback`**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid (PK, default `gen_random_uuid()`) | |
| `client_id` | **uuid UNIQUE NOT NULL** | Client-generated idempotency key |
| `device_id` | text | Persistent UUID from app |
| `emoji_choice` | text | `'satisfied'` / `'neutral'` / `'dissatisfied'` |
| `created_at` | timestamptz | `now()` |

**Table: `ratings`**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid (PK) | |
| `client_id` | **uuid UNIQUE NOT NULL** | Client-generated idempotency key |
| `device_id` | text | Persistent UUID from app |
| `project_id` | text | Showcase project identifier |
| `score` | int | 1–5 |
| `created_at` | timestamptz | |

**Table: `rate_limits` (server-side only)**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid (PK) | |
| `identity_hash` | text | Hash of device_id or IP |
| `endpoint` | text | `'feedback'` / `'rating'` |
| `count` | int | |
| `window_start` | timestamptz | |

### 6.2 Supabase Edge Function: `submit-feedback`

- **Receives:** `client_id`, `device_id`, `emoji_choice`, `ip_hash` (server-derived).
- **Checks rate limits:** max 3 submissions per device per 5 min, max 5 per IP hash per hour.
- **Idempotent insert:** `INSERT … ON CONFLICT (client_id) DO NOTHING` → returns 200 either way. A replay is a no-op, never a duplicate.
- If rate limit exceeded → **429 Too Many Requests**.
- If OK → inserts to `feedback`, updates `rate_limits`, returns **200**.
- The app never inserts directly to `feedback` via REST. All submissions go through this function.

Same pattern for `submit-rating`.

### 6.3 Anonymous Identity

- **Device ID:** UUID v4, generated once on first launch, stored in `shared_preferences` (Iteration 12).
- **IP Hash:** computed inside the Edge Function using SHA-256 of `ip + SALT`. Never stored raw.

### 6.4 Offline-First Strategy — Write-Through Queue

```text
Visitor taps emoji
      │
      ▼
┌──────────────────────┐
│ 1. Write to LOCAL DB │  ← Durable. Never lost, even if app crashes.
│    (status: pending) │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 2. Show Thank-You UI │  ← Instant. Never blocked by network.
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 3. Attempt upload    │  ← Async. Fire-and-forget from UI's perspective.
│    → success: mark   │
│      synced          │
│    → fail: stays     │
│      pending         │
└──────────┬───────────┘
           │
           ▼ (later, whenever)
┌──────────────────────┐
│ 4. SyncService drains│  ← On: app start, connectivity regained,
│    pending queue     │    every 5 min, after each new write
└──────────────────────┘
```

**Key rule:** The visitor's experience is identical whether online or offline. Thank-you always appears instantly. Sync is invisible background work.

### 6.5 Idempotency is Non-Negotiable

Every feedback/rating gets a client-generated UUID (`client_id`) before it's written to local DB. This UUID is:

- The primary key of the local row.
- Sent to Supabase as the primary dedupe key of the remote row (`UNIQUE`).
- Used to dedupe on retry — replaying a submission that actually succeeded returns 200 (409 also treated as success), not a duplicate row.

Designed out from Iteration 7.

### 6.6 Retry Semantics

| Server response on replay | Action |
|---|---|
| `200 OK` | Mark synced, delete from queue |
| `409 Conflict` (duplicate `client_id`) | Treat as success — mark synced, delete |
| `429 Too Many Requests` | Mark `rejected`, do not retry (visitor exceeded limits) |
| `400 Bad Request` | Mark `failed_permanent`, do not retry (malformed data — a bug) |
| Network error / timeout | Keep `pending`, retry with exponential backoff |
| `5xx` | Keep `pending`, retry with exponential backoff |

**Sync status enum:** `pending`, `synced`, `rejected`, `failed_permanent`.

### 6.7 Connectivity Detection — Two Signals

`connectivity_plus` alone is insufficient (reports "Wi-Fi connected" on captive portals). We combine:

1. `connectivity_plus` stream → triggers a sync attempt on network change.
2. Periodic reachability probe → `HEAD https://<project>.supabase.co/rest/v1/` with 5s timeout. Cheap, and accurately answers "can we actually talk to our backend?"

Both feed the same `SyncService`.

### 6.8 Server-Enforced Limits Remain

Even with offline queueing, server rate limits are never removed. The client cooldown is a UX layer; the server is the authority. If a kiosk goes offline for 10 minutes and accumulates 50 pending feedbacks, the Edge Function will reject most of them on replay with 429. Those get marked `rejected` and dropped — that is the correct behavior. Offline mode never bypasses rate limits.

---

## 7. Rate Limiting (Layered Strategy)

| Layer | Where | What | Iteration |
|---|---|---|---|
| Client cooldown | Flutter (`CooldownService`) | After successful submit, lock action for 30s (tunable). Persistent across restarts. | 13 |
| Client throttle | Flutter (button `InkWell` / `FocusableActionDetector`) | Ignore double-taps within 2s. | 19 |
| Server rate limit | Edge Function + `rate_limits` table | Per-device + per-IP hash rolling window. Applies to offline replay too. | 37 |
| UI feedback | Cooldown screen widget | Designed "Please wait" screen, not a disabled button. | 32 |

Every submission passes through all four layers. No bypass allowed.

---

## 8. Testing Discipline

### 8.1 TDD Rules

1. Write the test first when practical (especially for domain logic).
2. Every iteration has at least one test.
3. Widget tests simulate real interaction: taps, focus changes, text assertions — not just "widget builds without throwing."
4. No mocks of things you own. Only mock abstract interfaces. Use `mocktail` for Supabase/cross-boundary calls.
5. Run `flutter test` after every iteration. Include the output in your confirmation message.
6. **Test offline behavior explicitly.** Every repository/use case must have a test that verifies the local-first path: write succeeds even when the remote call throws, and the row remains `pending`.

### 8.2 Test Naming Convention

```dart
test('EmojiChoice.satisfied serializes to "satisfied"', () { ... });
testWidgets('EmojiPicker highlights focused face', (tester) async { ... });
```

### 8.3 Coverage Target

- Domain layer: **100%**.
- Data layer: **80%** (repository + datasource together).
- Presentation: every interactive widget has ≥1 widget test.
- Overall project: **70% minimum by Phase 5**.

---

## 9. Iteration Protocol

Every implementation message follows this exact template:

```text
### Iteration N — <Objective>

**1. What we're building**
   One-paragraph description.

**2. Why (learning context)**
   Explains the concept being demonstrated and how it fits the architecture.

**3. Files to create/modify**
   Bulleted list with full paths.

**4. Exact bash commands**
   Fedora-compatible. Includes mkdir, touch, flutter commands.

**5. Code with explanations**
   Code blocks + line-by-line "why" annotations.
   Never paste a code wall without explanation.

**6. How to run & test**
   Command(s) to execute.

**7. Expected test output**
   Exact expected console output or manual observation.

**8. What we learned**
   Key takeaways.

**9. Git commit & push**
   git add . && git commit -m "..." && git push
```

**Rules:**

- Never assume previous tests passed. Wait for confirmation.
- Never combine features.
- Never skip the test step.
- Never move forward if the previous iteration wasn't confirmed working.

---

## 10. Execution Plan — Phases, Iterations & Deliverables

### 10.0 How to use this plan

- This is the build order for **completing the project**: **8 phases → 44 iterations → 8 milestones** (§10.1).
- **Offline-first build order (decided 2026-11-18, see §0.5):** Phases 1–5 build the complete, releasable app with **zero backend** — Drift queue, sync engine proven against fake remotes, full UI, phone APK. **Supabase lands in Phase 6 (I34–I38)** and the TV port stays last (Phase 7). No iteration before I34 needs a cloud account, a deployed function, or a network connection.
- Each iteration card is the planning contract: **what** to build, **files**, **tests**, **deps**, **done-when evidence**. The live implementation message still follows the 9-part template in §9.
- **Status convention** in card headers: ⬜ not started · 🔄 in progress · ✅ confirmed. Flip to ✅ only after tests are green, committed, and pushed (§2.2.5).
- **Gates are blocking.** A phase's first iteration must not begin until the previous phase's exit gate is confirmed (§2.2.3).
- **Every iteration**, including manual ones, runs `flutter test` + `flutter analyze` before commit, **plus** its card-specific evidence (drill checklist, curl script, device run).
- Manual iterations (33, 34, 36, 37, 43, 44) involve device/deploy/Supabase steps the Flutter test runner can't do — their evidence is a script or recorded checklist output.

### 10.1 Plan overview & gates

| Phase | Iterations | Milestone | Goal | Exit gate |
|---|---|---|---|---|
| 0 — Foundation | 1–6 | **M1** App shell | Git-tracked, linted, tokenized app skeleton | `flutter analyze` clean; token/theme/scaffold tests green; initial commit pushed |
| 1 — Domain & Local Persistence | 7–11 | **M2** Offline-durable queue | Contracts + Drift queue + local datasource + local-first repository | Repository derives all §6.6 outcomes with a fake remote; submissions are durable with no backend configured |
| 2 — Offline Sync & Guardrails | 12–17 | **M3** Self-healing sync | Identity, cooldown, connectivity, DTO/remote seam, sync engine, triggers | SyncService outcome matrix + backoff tested with fake clock + fake remote; triggers coalesce; still no network required |
| 3 — Feedback Flow UI | 18–24 | **M4** Feedback experience | Picker → controller → thank-you → prompt → screen | E2E widget test: tap emoji → submit → thank-you → prompt; every interactive widget focusable |
| 4 — Rating Flow | 25–29 | **M5** Rating experience | Cards, carousel, sketch stars, rating submission | Full `RatingScreen` widget test; ratings ride the same offline queue |
| 5 — Phone Polish & Offline Release | 30–33 | **M6** Offline phone release | Rive, attract mode, cooldown UI, offline drill + APK | Airplane-mode drill survives force-kill + relaunch; release APK built — **no Supabase needed** |
| 6 — Cloud Backend & Live Sync | 34–38 | **M7** Cloud-connected kiosk | Schema + RLS, `SupabaseService`, Edge Function, live remote datasource | Live drill: offline rows sync on reconnect, replay deduped, 429 marks rows `rejected` |
| 7 — TV Port & Hardening | 39–44 | **M8** TV artifact | Leanback, D-pad, kiosk, safe areas, signed build | TV emulator E2E via D-pad + signed APK installed + 30-min soak, no crash |

**44 iterations = 38 phone + 6 TV.** (Original plan: 40; offline-first added 4.)

### 10.2 Dependency & prerequisite schedule

| Iteration | Adds | Kind |
|---|---|---|
| 1 | — | None — baseline via `flutter test`; device run optional |
| 2 | — | Prereq: GitHub remote for push |
| 4 | `google_fonts` | pub |
| 9 | `drift`, `drift_flutter`, dev: `drift_dev`, `build_runner` | pub + codegen |
| 12 | `uuid`, `shared_preferences` | pub |
| 13 | — (custom service; injectable clock) | pub: `shared_preferences` already added at I12 |
| 14 | `connectivity_plus` | pub |
| 15 | dev: `mocktail` | pub |
| 19 | `flutter_animate`, `rough_notation` | pub (focus + entrance motion) |
| 24 | `go_router` | pub (screen wiring) |
| 25 | `fancy_rating_bar` (evaluate), `sketchify` (optional) | pub (keep only if sketch look holds) |
| 30 | `rive`, `lottie` (light loops) + `assets/rive/` | pub + asset |
| 33 | `integration_test` (dev) | pub |
| 34 | — | **Manual: Supabase account + schema SQL** |
| 35 | `supabase_flutter` | pub |
| 36 | — | **Manual: `supabase login` + project link + function deploy** |
| 39 | — | Manual: TV banner drawable asset |
| 41 | `screen_pinning` | pub (TV only) |
| 44 | — | Manual: self-signed keystore (never committed) |

### 10.3 Phase 0 — Foundation (Iterations 1–6) ✅

**Goal:** a git-tracked, analyzed, tokenized, themed app shell with a kiosk-ready scaffold.
**Entry gate:** Flutter installed ✅ (3.47.9 detected), Android toolchain OK, device/emulator available.
**Exit gate:** `flutter analyze` clean; token + theme + scaffold tests green; initial commit pushed.
**Deliverables:** repo + canonical folder tree, design tokens, `AppTheme`, `KioskScaffold`.

**Milestone M1 reached ✅ (2026-11-18):** 26/26 tests green, `flutter analyze` clean, theme applied to the running app shell, shared kiosk surface ready for feature screens.

#### Iteration 1 — Environment baseline + folder scaffold + structure test ✅ (2026-11-17)

- **Build:** record the baseline (`flutter --version`, `flutter test`, `flutter analyze` must be green); create the canonical `lib/` tree from §4.1 (directories + `.gitkeep`), mirror the test layers under `test/`; `git init -b main` + hardened `.gitignore` (secrets, keystores, `supabase/.branches/`) + initial commit — git is folded in here because §9.9 requires every iteration to end with a commit.
- **Files:** 38 `lib/` dirs + 14 `test/` dirs each with `.gitkeep`; `test/core/structure_test.dart`; `.gitignore`.
- **Tests:** `test/core/structure_test.dart` — every canonical `lib/` dir exists; `test/` mirrors lib by layer; root docs (`PROJECT_PROCESS.md`, `README.md`, `analysis_options.yaml`, `pubspec.yaml`) present. Baseline `flutter test` also green.
- **Done:** `flutter test` + `flutter analyze` green; `git log` shows `Iteration 1: ...`.

#### Iteration 2 — GitHub remote + first push ✅ (2026-11-17, verified: remote `main` = `85c777a`)

- **Remote:** `origin` → `https://github.com/SoeMoeNaiing/UCSTGO_Showcase_App.git` (created empty, no initial commit — push was a clean fast-forward).
- **Build:** user creates an empty GitHub repo (manual prereq); `git remote add origin …` + `git push -u origin main`; audit `.gitignore` covers `build/`, `.dart_tool/`, `.idea/`, `*.iml`, `*.jks`, `*.keystore`, `.env`, `supabase/.branches/`.
- **Files:** `.gitignore` (adjust if the audit finds gaps).
- **Tests:** `flutter test` + `flutter analyze` green immediately before push — never push failing tests (§12).
- **Done:** `git status` clean; remote shows the commit.

#### Iteration 3 — Strict analysis rules + process docs ✅ (2026-11-17)

- **Build:** tighten `analysis_options.yaml` (stricter lints: `prefer_single_quotes`, `require_trailing_commas`, no stray `print`; keep existing excludes); verify `PROJECT_PROCESS.md` + `README.md` live at repo root and are tracked.
- **Files:** `analysis_options.yaml`, docs if untracked.
- **Tests:** `flutter analyze` → 0 issues; `flutter test` green.
- **Done:** analyze + test clean; commit.

#### Iteration 4 — Design tokens (colors, spacing, typography) ✅ (2026-11-17)

- **Build:** `AppColors` (all §5.2 tokens), `AppSpacing` (§5.4 scale), `AppTypography` (Patrick Hand via `google_fonts`, sizes per §5.3). All `static const` — the only place a hex value may ever appear.
- **Files:** `lib/core/theme/app_colors.dart`, `app_spacing.dart`, `app_typography.dart`.
- **Tests:** `test/core/theme/design_tokens_test.dart` — exact token values, spacing strictly increasing, typography sizes recorded (TV 32sp audit compares against these later).
- **Deps:** `google_fonts`.
- **Done:** tests green; grep confirms no `0xFF` outside `app_colors.dart`.

#### Iteration 5 — AppTheme composition ✅ (2026-11-18)

- **Build:** compose `ThemeData` from tokens — `colorScheme`, `scaffoldBackgroundColor = paperBackground`, card theme, base `TextTheme`. One place, no hardcoded values (§2.1.4).
- **Files:** `lib/core/theme/app_theme.dart`.
- **Tests:** `test/core/theme/app_theme_test.dart` — `AppTheme.light().scaffoldBackgroundColor == AppColors.paperBackground`, text sizes match typography tokens, focus decoration uses `accentWarm`.
- **Done:** widget test green.

#### Iteration 6 — KioskScaffold ✅ (2026-11-18)

- **Build:** root scaffold — paper background + faint dot-grid `CustomPainter`, safe-area/overscan padding (configurable 5% for TV later, §5.5), child slot, hook for background animations.
- **Files:** `lib/core/widgets/kiosk_scaffold.dart`.
- **Tests:** `test/core/widgets/kiosk_scaffold_test.dart` — renders child, background token applied, painter paints without exception.
- **Done:** widget test green → **M1**.

### 10.4 Phase 1 — Domain & Local Persistence (Iterations 7–11) ✅

**Goal:** an offline-durable feedback pipeline with **no network at all**: pure domain entities → Drift queue → local datasource → local-first repository (with a remote seam that stays unplugged until Phase 6).
**Entry gate:** M1 confirmed.
**Exit gate:** repository tests derive all §6.6 outcomes against a fake remote; duplicate `client_id` rejected by the database; the app accepts and durably stores submissions with zero backend configured.
**Deliverables:** entities + contracts (done), `AppDatabase`, `FeedbackLocalDataSource`, `FeedbackRepositoryImpl`.

**Milestone M2 reached ✅ (2026-11-18):** 80/80 tests green, `flutter analyze` clean. Submissions are durable in Drift before any network call, and all five §6.6 outcomes are proven with a fake remote — the pipeline works with **no backend configured**.

#### Iteration 7 — EmojiChoice enum + Feedback entity with clientId ✅ (2026-11-18)

- **Build:** `EmojiChoice` enum (`satisfied` / `neutral` / `dissatisfied`, `toJson`/`fromJson`, unknown → `FormatException`), `Feedback` entity (`clientId`, `deviceId`, `emojiChoice`, `createdAt`) — pure Dart, no Flutter.
- **Files:** `lib/features/feedback/domain/entities/emoji_choice.dart`, `feedback.dart`.
- **Tests:** serialization round-trip for all 3 values; invalid string throws; entity requires `clientId` (non-null) and compares by value.
- **Done:** tests green; grep: no Flutter/Supabase import in `domain/` (§4.2 rule of thumb).

#### Iteration 8 — Repository interfaces + Rating entity + result types ✅ (2026-11-18)

- **Build:** abstract `FeedbackRepository` and `RatingRepository`; `Rating` entity (`clientId`, `deviceId`, `projectId`, `score` 1–5, `createdAt`); `SubmissionResult` / `SyncOutcome` value types covering the §6.6 status vocabulary.
- **Files:** `lib/features/feedback/domain/repositories/feedback_repository.dart`, `lib/features/rating/domain/entities/rating.dart`, `lib/features/rating/domain/repositories/rating_repository.dart`, `lib/core/domain/sync_status.dart`, `submission_result.dart`.
- **Tests:** a fake repository implements both interfaces (compile-time contract test); status enum ↔ string mapping is exhaustive.
- **Done:** pure-Dart tests green.

#### Iteration 9 — Drift schema: queue tables + AppDatabase ✅ (2026-11-18)

- **Build:** `AppDatabase` hosting both queue tables `pending_feedback` and `pending_ratings` (`client_id` PK, payload columns, `sync_status`, `attempts`, `last_attempt_at`, `next_retry_at`, `created_at`), plus an in-memory constructor for tests. No Supabase, no network — this is the durable core the whole app stands on.
- **Files:** `lib/features/feedback/data/local/app_database.dart`, `lib/features/feedback/data/local/tables/pending_feedback_table.dart`, `pending_ratings_table.dart`.
- **Tests:** `test/features/feedback/data/app_database_test.dart` — insert→query round-trip; duplicate `client_id` rejected (UNIQUE); status filter query returns only `pending`.
- **Deps:** `drift`, `drift_flutter`, dev: `drift_dev`, `build_runner`; run `dart run build_runner build --delete-conflicting-outputs` and commit generated `*.g.dart`.
- **Note:** queue infrastructure lives under `features/feedback/data/local/` per §4.1; other features import it **only from their own `data/` layer** (rating plugs in at Iteration 28).
- **Done:** codegen committed; in-memory tests green.

#### Iteration 10 — FeedbackLocalDataSource (Drift CRUD) ✅ (2026-11-18)

- **Build:** `insert()`, `pending(limit)`, `markSynced()`, `markRejected()`, `markFailedPermanent()`, `scheduleRetry(clientId, nextRetryAt)`, `delete()`; entity↔row mapping.
- **Files:** `lib/features/feedback/data/datasources/feedback_local_datasource.dart`.
- **Tests:** `test/features/feedback/data/feedback_local_datasource_test.dart` with in-memory DB — insert→appears in `pending()`; `markSynced` removes it from pending; retry timestamp respected; all status transitions exhaustive.
- **Done:** tests green.

#### Iteration 11 — FeedbackRepositoryImpl: local-first orchestration ✅ (2026-11-18)

- **Build:** `submit()` → write to Drift (`pending`) → attempt remote **only if a remote is configured and `isOnline()` is true** → apply the outcome to the row → **return success to the caller regardless** (remote errors swallowed + logged). Declares the injected `FeedbackRemoteDataSource` seam (one method returning a typed `RemoteOutcome`) and wires `UnavailableFeedbackRemoteDataSource` (always `networkFailure`) so the queue simply accumulates in Phases 1–5. `pending()` + `applySyncStatus()` expose the queue for the sync engine (Iteration 16). No UI or Supabase dependency.
- **Files:** `lib/features/feedback/data/repositories/feedback_repository_impl.dart`.
- **Tests:** `test/features/feedback/data/feedback_repository_impl_test.dart` — 5 paths with fakes: remote success → `synced`; remote throws → row stays `pending` **and** result still success (Patch D rule); remote 429 → `rejected`; replay 409 → `synced`; offline → `verifyNever(remote.submit)` called.
- **Done:** all 5 paths green → **M2**.

### 10.5 Phase 2 — Offline Sync & Guardrails (Iterations 12–17) ✅

**Goal:** identity + cooldown + connectivity + a **fake-provable** sync engine + automatic triggers, so the queue self-heals without any backend attached.
**Entry gate:** M2 confirmed.
**Exit gate:** SyncService outcome matrix + backoff tested with fake clock; triggers coalesce correctly; the offline build never needs a network.
**Deliverables:** `DeviceIdService`, `CooldownService`, `ConnectivityService`, `FeedbackModel` + remote contract, `SyncService`, `SyncScheduler`.

**Milestone M3 reached ✅ (2026-11-18):** 149/149 tests green, `flutter analyze` clean. Identity, 30s cooldown, captive-portal-safe online detection, the exact §6.2 wire payload, the §6.6 outcome matrix with durable 2→60s backoff, and all four sync triggers are proven with fakes — still **zero network required**. The queue now heals itself automatically the moment a backend is attached.

#### Iteration 12 — DeviceIdService ✅ (2026-11-18)

- **Build:** generate UUID v4 on first launch, persist in `shared_preferences`, stable for the device's lifetime; storage injected so tests can fake it.
- **Files:** `lib/services/device_id_service.dart`.
- **Tests:** `test/services/device_id_service_test.dart` with fake storage — first call persists; a second service instance returns the same id; no regeneration after "restart".
- **Deps:** `uuid`, `shared_preferences`.
- **Done:** tests green.

#### Iteration 13 — CooldownService (30s persistent cooldown) ✅ (2026-11-18)

- **Build:** per-action cooldown (feedback / rating) backed by a persisted deadline so it survives restart; exposes `canSubmit(action)`, `timeRemaining(action)` and a `remaining` stream. **Decision:** custom service with an injectable clock + storage seam; the `limit` package was evaluated and rejected because its `Cooldown` hardcodes `DateTime.now()` (untestable with the fake clock §8 requires) and bundles `prf`. `shared_preferences` is already present from I12.
- **Files:** `lib/services/cooldown_service.dart`.
- **Tests:** with fake clock — allowed → submit → blocked; after 30s allowed again; new service instance with persisted deadline still blocked; feedback and rating cooldowns don't cross-block.
- **Deps:** none new (`shared_preferences` from I12).
- **Done:** tests green (30s default tunable per §13).

#### Iteration 14 — ConnectivityService (stream + reachability probe) ✅ (2026-11-18)

- **Build:** combines the `connectivity_plus` stream (physical link) with an on-demand reachability probe (injectable HTTP client, `HEAD` to the backend base URL from `--dart-define SUPABASE_URL`, 5s timeout) → exposes `online` stream + `checkNow()`. With no URL configured (Phases 1–5) it falls back to link state; the remote seam stays `Unavailable`, so nothing is uploaded. Captive-portal safe: link up + probe fails = offline (§6.7).
- **Files:** `lib/services/connectivity_service.dart`.
- **Tests:** with fakes, no real network — Wi-Fi up + probe OK → online; Wi-Fi up + probe timeout → offline; probe recovery emits a rising edge; no URL configured → link-state fallback without throwing.
- **Deps:** `connectivity_plus`.
- **Done:** tests green.

#### Iteration 15 — FeedbackModel DTO + remote outcome mapping + payload wiring ✅ (2026-11-18)

- **Build:** `FeedbackModel` entity↔JSON (`client_id`, `device_id`, `emoji_choice`); complete the Iteration 11 remote seam with a pure `mapHttpStatus → RemoteOutcome` table (`200/409 → success`, `429 → rejected`, `400 → invalid`, `5xx → serverError`, transport exception → `networkFailure`); `UnavailableFeedbackRemoteDataSource` uses `networkFailure` for the offline build. Guarantee both identifiers are present before any local write: `device_id` resolved from `DeviceIdService`, `client_id` always on the entity — payload keys match §6.2 exactly.
- **Decision:** the I11 seam is refined to `submit(FeedbackModel payload)` — the only upload path now carries the exact §6.2 wire DTO, not the domain entity, so Phase 6 cannot bypass the payload contract. The repository converts entity → DTO. `created_at` is **not** in the payload: the server assigns it (`now()`); the local row already records the visit time for queue ordering. Identity stays structural (`Feedback` asserts both ids); the first-run generation path is integration-tested before the local save.
- **Files:** `lib/features/feedback/data/models/feedback_model.dart`, `lib/features/feedback/data/datasources/feedback_remote_datasource.dart`, `lib/features/feedback/data/repositories/feedback_repository_impl.dart`.
- **Tests:** `mocktail` — payload keys exact; DTO round-trip; strict `fromJson`; the full status→outcome table; unavailable remote → `networkFailure`; seam receives the DTO; first-run device id generated from empty storage before the row is saved.
- **Deps:** dev: `mocktail`.
- **Done:** tests green.

#### Iteration 16 — SyncService: drain, outcomes, backoff ✅ (2026-11-18)

- **Build:** drains the pending queue serially (low-end friendly, one item at a time) via `FeedbackRepository.pending()` / `applySyncStatus()`: per item → submit → map §6.6 outcome (200/409 → `synced` + delete, 429 → `rejected`, 400 → `failed_permanent`, network/5xx → retry); exponential backoff **2 → 4 → 8 → 16 → 32 → 60s**, max 6 retries then `failed_permanent`; overlap guard; `syncAll()` + `pendingCount` stream. Queue interface: feedback implements now, rating plugs in at Iteration 28.
- **Decision:** `pending()` returns `QueuedFeedback(feedback, attempts)` (not the bare entity) so the backoff step is read from the durable row and survives restarts. The queue also gains `watchPendingCount()` for the UI. §13's six-step schedule governs: **six retries** (initial upload + 6 retries) before `failed_permanent`; the earlier card wording "6 attempts" was off by one and is corrected here.
- **Files:** `lib/services/sync_service.dart`, `lib/features/feedback/domain/entities/queued_feedback.dart`, `lib/features/feedback/data/datasources/feedback_local_datasource.dart`, `lib/features/feedback/domain/repositories/feedback_repository.dart`, `lib/features/feedback/data/repositories/feedback_repository_impl.dart`.
- **Tests:** full outcome matrix with fake repository/remote; backoff schedule asserted with fake clock; six-retry cap then terminal; serial FIFO drain; two concurrent `syncAll()` calls coalesce; batch loop; throwing remote → retry; empty queue = no-op; `pendingCount` forwards live counts.
- **Done:** tests green.

#### Iteration 17 — Sync triggers wired ✅ (2026-11-18)

- **Build:** `SyncScheduler` with four triggers: (1) app start, (2) ConnectivityService rising edge, (3) 5-minute periodic timer, (4) post-write nudge (~1s after each local save) — all debounced/coalesced into a single `syncAll()` (§6.4). With no backend the sweep is a harmless no-op; with Supabase attached in Phase 6 the identical scheduler goes live.
- **Decision:** the scheduler depends on two narrow seams — `SyncRunner` (implemented by `SyncService`) and `ConnectivityStatus` (implemented by `ConnectivityService`) — so every trigger is fake-testable without the provider graph. App start calls `connectivity.start()` (one probe, one link subscription) and sweeps only when online; rising edges re-sweep; periodic ticks trust `isOnline` rather than probing every 5 minutes; `notifyLocalWrite()` debounces nudges and is wired to the repository at I21, when the provider graph exists.
- **Files:** `lib/services/sync_scheduler.dart`, `lib/services/sync_service.dart` (`SyncRunner`), `lib/services/connectivity_service.dart` (`ConnectivityStatus`).
- **Tests:** each trigger → exactly one sync; concurrent triggers coalesce; no sync attempt while offline; periodic timer ticks correctly under `fakeAsync`; nudge debounce; dispose stops all triggers.
- **Done:** tests green → **M3**.

### 10.6 Phase 3 — Feedback Flow UI (Iterations 18–24)

**Goal:** the complete visitor feedback experience — phone-first, but D-pad-ready from the first pixel (§2.3.2).
**Entry gate:** M3 confirmed.
**Exit gate:** end-to-end widget test proves emoji → submit → thank-you → prompt; every interactive widget uses focusable components (no `GestureDetector`-only).
**Deliverables:** `EmojiPicker`, focus/select interaction, `FeedbackController`, `SubmitFeedback` use case, `ThankYouCard`, `RateProjectsPrompt`, `FeedbackScreen`, `go_router` wiring.

#### Iteration 18 — Static EmojiPicker ✅ (2026-11-18)

- **Build:** three sketch-outlined faces via `CustomPainter` doodle strokes (happy / neutral / sad), paper palette, 10-foot sizing, semantics labels — render only, no interaction.
- **Decision:** face size is adaptive — each face takes a third of the row minus gutters, capped at 180dp (`maxFaceSize` is configurable so Phase 7 can raise it for 4K). The painted face is a wobbly double-pass ink outline plus an accent marker wash; cheeks only on the happy face. Visible copy is friendly ("Loved it" / "Okay" / "Not great") while the single semantic node speaks the domain vocabulary ("Satisfied" / "Neutral" / "Dissatisfied"); visible text is excluded from semantics to avoid double-reading.
- **Files:** `lib/features/feedback/presentation/widgets/emoji_picker.dart`.
- **Tests:** widget test — renders exactly 3 faces in sentiment order; one semantic label per face; visible labels; square faces stay ≥88dp on a 320dp phone; size caps at 180dp and honours a TV override; no hardcoded colors (global token guard, §2.1.4).
- **Done:** tests green.

#### Iteration 19 — Focus + select interaction + double-tap throttle ⬜

- **Build:** wrap each face in `FocusableActionDetector` (tap **and** D-pad activate), visible focus state (scale + `rough_notation` highlight box), 2s throttle ignoring double-taps (§7 client throttle).
- **Files:** same widget + focus styling.
- **Tests:** tap fires the callback **once** on double-tap; arrow traversal focuses next/prev; activate/Enter key selects; focus state visibly changes.
- **Deps:** `flutter_animate`, `rough_notation`.
- **Done:** widget tests green.

#### Iteration 20 — FeedbackController (Riverpod notifier) ⬜

- **Build:** state machine `idle → selecting → submitting → success | cooldown | error`, with the submitter injected (fake first — wiring lands in Iteration 21).
- **Files:** `lib/features/feedback/presentation/controllers/feedback_controller.dart`.
- **Tests:** unit tests — each state transition; double-select ignored while `submitting`; error state carries a user-facing message; no `BuildContext` in the controller (§2.1.5).
- **Done:** tests green.

#### Iteration 21 — SubmitFeedback use case + controller wiring ⬜

- **Build:** generate `clientId` (uuid) → fetch `deviceId` → build `Feedback(now)` → `repo.submit()` → map `SubmissionResult` to controller state; success starts the cooldown (Iteration 13).
- **Files:** `lib/features/feedback/domain/usecases/submit_feedback.dart` + controller wiring.
- **Tests:** happy path; repository offline still yields success; `rejected` result → cooldown started + error message; invalid input → validation error.
- **Done:** unit test green.

#### Iteration 22 — ThankYouCard ⬜

- **Build:** doodled character + speech bubble scribbling "Thank you!" with `flutter_animate` entrance (Rive deferred to Iteration 30), token-styled.
- **Files:** `lib/features/feedback/presentation/widgets/thank_you_card.dart`.
- **Tests:** appears on success state; text present; pumps through the entrance animation without exceptions.
- **Done:** widget test green.

#### Iteration 23 — RateProjectsPrompt ⬜

- **Build:** "Rate our projects?" card with focusable **Yes** (→ rating) and **Skip** (→ idle) actions, sketch styling.
- **Files:** `lib/features/feedback/presentation/widgets/rate_projects_prompt.dart`.
- **Tests:** Yes → `onYes` once; Skip → `onSkip` once; both reachable via focus traversal.
- **Done:** widget test green.

#### Iteration 24 — Full FeedbackScreen assembly + E2E widget test ⬜

- **Build:** screen state machine (picker → success → thank-you → prompt → cooldown slot); `/feedback` route registered in `go_router`; all providers overridden in tests with a fake repository.
- **Files:** `lib/features/feedback/presentation/screens/feedback_screen.dart`, `lib/core/router/app_router.dart`, `lib/app.dart`.
- **Tests:** E2E widget test — tap emoji → submit called → thank-you appears → prompt appears → Skip returns to picker; initial focus lands on the first face.
- **Deps:** `go_router`.
- **Done:** widget tests green → **M4**.

### 10.7 Phase 4 — Rating Flow (Iterations 25–29)

**Goal:** rate showcase projects, riding the exact same offline queue and sync engine.
**Entry gate:** M4 confirmed.
**Exit gate:** full `RatingScreen` widget test; rating rows flow through the same SyncService outcome matrix.
**Deliverables:** `Project` entity + fixture list, `ProjectCard`, `ProjectCarousel`, `RatingWidget`, rating data layer + `RatingController`, `RatingScreen`.

#### Iteration 25 — Project entity + ProjectCard ⬜

- **Build:** `Project` (`id`, `title`, `blurb`, `imageAsset?`) + a const fixture list of ~6 placeholder showcase projects in the showcase feature; polaroid `ProjectCard` with hand-drawn tape (§5.1).
- **Files:** `lib/features/showcase/domain/entities/project.dart`, `lib/features/showcase/presentation/widgets/project_card.dart`, fixture provider.
- **Tests:** card renders title + blurb; tap/focus fires select callback once; tokens only.
- **Deps:** `fancy_rating_bar` evaluated later (I27); `sketchify` optional here for card entrance.
- **Done:** widget test green.

#### Iteration 26 — ProjectCarousel ⬜

- **Build:** horizontal `PageView` (swipe on phone) plus focus next/prev hooks for D-pad; hand-drawn page-dots indicator.
- **Files:** `lib/features/showcase/presentation/widgets/project_carousel.dart`.
- **Tests:** swipe changes page; focus-next advances index; dots update; no focus trap at list edges.
- **Done:** widget test green.

#### Iteration 27 — RatingWidget: sketch stars 1–5 ⬜

- **Build:** five `CustomPainter` stars that "draw in" on tap, score 1–5, D-pad left/right adjusts, elastic overshoot animation, ≥120dp min height (§5.5).
- **Files:** `lib/features/rating/presentation/widgets/rating_widget.dart`.
- **Tests:** tap star n → score n; right-arrow increments (capped at 5); semantics announce the score; min height asserted.
- **Done:** widget test green; `fancy_rating_bar` verdict recorded (keep only if it yields the sketch look, else custom — §3).

#### Iteration 28 — Rating submission path + RatingController ⬜

- **Build:** `RatingRemoteDataSource` contract + `RatingLocalDataSource` + `RatingRepositoryImpl` (mirrors Phase 1 seams with an unplugged remote, reuses the shared `AppDatabase` from Iteration 9), `SubmitRating` use case, `RatingController` state machine; the rating queue is added to `SyncService` (Iteration 16) and the scheduler (Iteration 17).
- **Files:** `lib/features/rating/data/**`, `lib/features/rating/domain/usecases/submit_rating.dart`, `lib/features/rating/presentation/controllers/rating_controller.dart`, `sync_service.dart` queue wiring.
- **Tests:** offline path (remote unavailable → success + row `pending` — Patch D rule), fake online → `synced`, 429 → `rejected`; controller transitions; SyncService drains rating rows too.
- **Done:** tests green.

#### Iteration 29 — Full RatingScreen assembly ⬜

- **Build:** screen flow: carousel → select card → stars → submit → confirmation → back to idle; `/rating` route registered; providers overridable for tests.
- **Files:** `lib/features/rating/presentation/screens/rating_screen.dart` + router wiring.
- **Tests:** select card shows stars; set score + submit calls repo once; confirmation appears; fake pending repo → no crash; cooldown respected.
- **Done:** widget tests green → **M5**.

### 10.8 Phase 5 — Phone Polish & Offline Release (Iterations 30–33)

**Goal:** make it beautiful, self-attending (attract loop), fair (cooldown UX), and **prove the offline story end-to-end on phone with no backend attached**.
**Entry gate:** M5 confirmed.
**Exit gate:** offline drill checklist passes (queue survives force-kill + relaunch); `flutter build apk --release` succeeds.
**Deliverables:** Rive assets, idle attract mode, cooldown screen, integration test, phone release APK.

#### Iteration 30 — Rive integration ⬜

- **Build:** add `assets/rive/` (emoji reaction + thank-you character); wrap in a sketch-animation widget with an **injectable no-op backend** for tests and a `CustomPainter` fallback if Rive fails to load (kiosk must never show a broken asset).
- **Files:** `assets/rive/*.riv`, `lib/core/widgets/sketch_animation.dart`, updates to `EmojiPicker` / `ThankYouCard`; pubspec `assets:` section.
- **Tests:** fake backend renders + advances state; Rive failure path falls back to painter without throwing. **No `.riv` loading in widget tests.**
- **Deps:** `rive`, `lottie` (lightweight decorative loops only — §3).
- **Done:** widget tests green; manual visual check on phone.

#### Iteration 31 — Idle attract mode ⬜

- **Build:** 20s inactivity → attract overlay (pencil draws welcome text loop, token-styled); any input dismisses + resets the timer; wired into Feedback + Rating screens.
- **Files:** `lib/core/widgets/attract_overlay.dart` + screen wiring.
- **Tests:** widget test with fake async — after 20s idle the overlay shows; input hides it; timer resets; no spurious trigger during active use.
- **Done:** widget test green (20s default tunable per §13).

#### Iteration 32 — Cooldown screen UI ⬜

- **Build:** designed "catch your breath" moment — doodled clock counting down `CooldownService.remaining` (§5.1), shown **instead of** disabled buttons; expiry returns to interactive/attract.
- **Files:** `lib/core/widgets/cooldown_screen.dart` (or feature-local) + wiring.
- **Tests:** countdown text decrements; picker not visible during cooldown; expiry restores interaction; respects persisted deadline from Iteration 13.
- **Done:** widget test green.

#### Iteration 33 — Full phone integration test + offline drill + release APK ⬜ (manual + automated)

- **Build:** `integration_test/feedback_rating_flow_test.dart` covering the full happy path on a real device; `flutter build apk --release`; **manual offline drill:** airplane mode → submit 2 feedback + 1 rating → pending count = 3 → force-kill the app → relaunch → still 3 pending (durability proven) → wait one 5-minute sweep → still pending (no backend configured, by design) → re-enable network → still pending until Phase 6 → no crash, no data loss.
- **Files:** `integration_test/feedback_rating_flow_test.dart`, drill checklist in the iteration message.
- **Tests:** `flutter test integration_test -d <device>` green + drill evidence (pending counts before/after restart).
- **Done:** APK built + drill passed → **M6**. 🎉 The full visitor flow and the offline story demo with Wi-Fi off — **Supabase not required**.

### 10.9 Phase 6 — Cloud Backend & Live Sync (Iterations 34–38)

**Goal:** attach Supabase to the already-working offline app — schema, Edge Function, and swapping the fake remote seam for the real datasource. **No UI or domain changes should be required**; if they are, the Phase 1–2 seams were wrong.
**Entry gate:** M6 confirmed; Supabase account ready (free tier is fine).
**Exit gate:** live drill passes — offline rows appear after reconnect, replay is deduped, 429 marks rows `rejected`; curl suite green.
**Deliverables:** migrations + verify script, `SupabaseService`, `submit-feedback` / `submit-rating` Edge Functions, `SupabaseFeedbackRemoteDataSource`, drill evidence.

#### Iteration 34 — Manual: Supabase project + schema with client_id UNIQUE ⬜ (manual)

- **Build:** create the Supabase project; apply `supabase/migrations/0001_init.sql` — `feedback`, `ratings`, `rate_limits` (§6.1) including `client_id uuid UNIQUE NOT NULL`; **enable RLS with no public policies** (writes only via Edge Function service role → direct REST insert stays impossible).
- **Files:** `supabase/migrations/0001_init.sql`, `supabase/verify_schema.sh`.
- **Tests:** run verify script → reports tables + unique constraint present; unauthenticated REST insert → denied. Script output replaces `flutter test` evidence (see §10.0).
- **Done:** script output captured in the iteration message.

#### Iteration 35 — SupabaseService initialization + smoke test ⬜

- **Build:** provider-based init of `supabase_flutter` from `--dart-define SUPABASE_URL / SUPABASE_ANON_KEY` — secrets never committed or hardcoded; clear failure message if missing; overridable provider for tests.
- **Files:** `lib/services/supabase_service.dart`.
- **Tests:** `test/services/supabase_service_test.dart` — config parsing success + missing-config failure; provider override works in a widget harness.
- **Deps:** `supabase_flutter`.
- **Done:** tests green.

#### Iteration 36 — Manual: deploy Edge Function skeletons ⬜ (manual)

- **Build:** `supabase login` + link project; `supabase functions new submit-feedback` + `submit-rating` skeletons (JSON echo + CORS) and deploy both.
- **Files:** `supabase/functions/submit-feedback/index.ts`, `supabase/functions/submit-rating/index.ts`, curl smoke script.
- **Tests:** curl script returns 200 + expected JSON (script replaces `flutter test` evidence).
- **Done:** deployed URLs respond.

#### Iteration 37 — Edge Functions: idempotent insert + rate limit ⬜

- **Build:** TypeScript Edge Functions (shared handler module, table variant per endpoint): validate payload → rate check (device 3 / 5 min, IP-hash 5 / hour, salted SHA-256) → `INSERT … ON CONFLICT (client_id) DO NOTHING` → update `rate_limits` → 200 / 409 / 429 / 400 (§6.2).
- **Files:** `supabase/functions/_shared/handler.ts`, `supabase/functions/submit-feedback/index.ts`, `supabase/functions/submit-rating/index.ts`, `tests/curl_submit_feedback.sh`.
- **Tests (curl suite):** first submit → 200 + exactly 1 row; replay same `client_id` → 200 **+ still 1 row** (dedupe); rating replay → still 1 row; 4th rapid submit → 429; malformed payload → 400; row counts verified via SQL.
- **Done:** all curl assertions pass (server authority confirmed — §6.8).

#### Iteration 38 — Wire the live Supabase remote + online drill ⬜ (manual + automated)

- **Build:** `SupabaseFeedbackRemoteDataSource` implementing the Iteration 15 contract (invokes `submit-feedback`, maps 200/409/429/400/5xx/exception → the same `RemoteOutcome`); replace `UnavailableFeedbackRemoteDataSource` in the provider graph (feedback + ratings); point the ConnectivityService probe at `SUPABASE_URL/rest/v1/`; config via `--dart-define`. No widget, controller, or domain edits — proof the seam held.
- **Files:** `lib/features/feedback/data/datasources/supabase_feedback_remote_datasource.dart`, `lib/features/rating/data/datasources/supabase_rating_remote_datasource.dart`, provider wiring.
- **Tests:** `mocktail` HTTP client maps all six outcomes; provider graph resolves the live datasource when config is present; full suite still green.
- **Manual drill:** airplane mode → submit ×2 → reconnect → within ~10s both rows in Supabase → replay one `client_id` via curl → still 2 rows → hammer 10× → 429 → local rows marked `rejected`.
- **Done:** drill evidence (SQL row counts before/after) captured → **M7**. 🎉 Cloud-connected kiosk ready.

### 10.10 Phase 7 — TV Port & Hardening (Iterations 39–44)

**Goal:** turn the phone app into a hardened, unattended TV kiosk artifact.
**Entry gate:** M7 confirmed; Android TV emulator (or device) available.
**Exit gate:** TV emulator E2E passes via D-pad; signed APK installed; 30-minute soak with no crash.
**Deliverables:** leanback manifest + banner, focus tuning, `KioskService`, TV-safe layout, signed build.

#### Iteration 39 — Android manifest: leanback, banner, landscape ⬜

- **Build:** manifest declares the leanback launcher intent-filter + `android.software.leanback` with touchscreen **not required**, TV banner drawable, landscape lock, `minSdk 26` check (§13) — while staying installable on phone for development.
- **Files:** `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/drawable-tv/banner.*`, verification script.
- **Tests:** `flutter build apk --debug` + script greps merged manifest for leanback intent-filter, banner, landscape orientation.
- **Done:** script assertions pass.

#### Iteration 40 — D-pad focus tuning across all widgets ⬜

- **Build:** audit + fix every interactive widget: initial focus targets (first emoji face), unmistakable visible focus (rough box + scale, §5.1), no focus traps, carousel/star navigation, back-button behavior, 10-foot focus visibility.
- **Files:** fixes across `features/*/presentation/widgets/` + audit checklist doc.
- **Tests:** per-screen widget tests asserting initial focus + traversal reaches every action exactly once.
- **Done:** checklist complete; all focus tests green.

#### Iteration 41 — KioskService (screen pinning) ⬜

- **Build:** pin the app on TV start (`screen_pinning` / pinning intent), no-op on phone, documented exit gesture for operators.
- **Files:** `lib/services/kiosk_service.dart`.
- **Tests:** unit test with fake platform channel — pin invoked when supported; unsupported platform → clean no-op; errors logged, never thrown to UI.
- **Deps:** `screen_pinning`.
- **Done:** tests green.

#### Iteration 42 — TV safe area + oversized text audit ⬜

- **Build:** enforce §5.5 — 5% overscan via `KioskScaffold`, min 32sp visitor text, ≥120dp focus targets; audit every screen; adjust typography tokens **only** (§2.1.4).
- **Files:** `app_typography.dart`, `kiosk_scaffold.dart`, layout fixes.
- **Tests:** widget tests assert overscan padding present; key visitor texts ≥ 32sp; interactive heights ≥ 120dp.
- **Done:** tests green; 60fps spot-check recorded on target hardware.

#### Iteration 43 — Full integration test on Android TV emulator ⬜

- **Build:** run the integration flow on TV emulator driven by key events (D-pad), plus a 30-min soak checklist (idle → attract → input cycles, repeated submissions, cooldown path).
- **Files:** `integration_test/tv_flow_test.dart` + soak checklist.
- **Tests:** `flutter test integration_test -d <tv-emulator>` green; soak results recorded.
- **Done:** TV E2E green.

#### Iteration 44 — Signed APK build, final deployable artifact ⬜

- **Build:** generate self-signed keystore (gitignored, §13), gradle signing config via env vars, `flutter build apk --release`, final install on TV, `RELEASE_CHECKLIST.md` (setup, exit gesture, cooldown/sync tunables, rollback).
- **Files:** `android/key.properties` (gitignored), keystore (local only), signing config, `RELEASE_CHECKLIST.md`.
- **Tests:** build succeeds; verification checklist executed end-to-end (launch, full flow, offline-drill replay, dedupe, soak).
- **Done:** signed APK artifact → **M8** 🎉.

### 10.11 Risk register

| Risk | Impact | Mitigation (by design) | Iterations |
|---|---|---|---|
| Venue Wi-Fi flaky / captive portal | Lost feedback | Local-first queue + reachability probe (not just link state) | 9–11, 14 |
| Retry duplicates on replay | Double-counted data | `client_id UNIQUE` + `ON CONFLICT DO NOTHING` + 409 = success | 7, 34, 37, 38 |
| Offline flood on reconnect | Legit rows rejected | Server stays authoritative; overflow → `rejected`, tunable windows | 13, 37, 38 |
| App killed mid-sync | Orphaned rows | Durable Drift rows + app-start trigger resumes queue | 9, 17 |
| Low-end TV jank (<60fps) | Poor showcase impression | Capped particles, Rive fallback, token sizes, early perf spot-checks | 30, 42 |
| Focus traps on TV | Kiosk unusable | Focus audit + traversal tests per screen | 40, 43 |
| Rive asset fails to load | Broken visuals | Painter fallback behind injectable animation backend | 30 |
| Runtime font fetch fails offline | Fallback font at the kiosk | Bundle the Patrick Hand TTF as an asset before deployment (google_fonts asset mode) | 5, 44 |
| Secrets leakage (keys, keystore) | Security | `--dart-define` + gitignore rules | 2, 35, 44 |
| Drift codegen forgotten after table change | Build breaks | Codegen command baked into I9 + regenerate on any schema edit | 9 |

### 10.12 What you'll be able to say at the showcase

**After Phase 5 / M6 — offline demo, no backend needed:**

- ✅ "Unplug the router right now." → App keeps accepting feedback. Queue grows.
- ✅ "Kill the app mid-submit." → On next launch it resumes with the same pending rows.
- ✅ "How does it know not to duplicate?" → `client_id` UUID is generated before the local write and is the local primary key; server-side uniqueness arrives in Phase 6.
- ✅ "What happens when you reconnect?" → The scheduler drains the queue automatically — as soon as the backend is attached in Phase 6.

**After Phase 6 / M7 — cloud live:**

- ✅ "Plug it back in." → Within ~10 seconds, all pending submissions flow to Supabase.
- ✅ "How does it know not to duplicate?" → `client_id UNIQUE` + `ON CONFLICT DO NOTHING`; replay verified by curl (still 2 rows).
- ✅ "What if someone hammers the emoji 100 times offline?" → Server rejects overflow with 429 on replay; client drops them with `rejected` status.

---

## 11. Bash Commands Cheat Sheet (Fedora)

```bash
# Flutter environment check
flutter --version
flutter doctor -v

# Create project (already done in this repo; shown for reference)
flutter create --org com.yourcompany --project-name showcase_app showcase_app
cd showcase_app

# Dependencies (added across the early iterations)
flutter pub add flutter_riverpod go_router supabase_flutter limit \
  shared_preferences uuid rive lottie flutter_animate rough_notation \
  sketchify fancy_rating_bar google_fonts
flutter pub add drift drift_flutter connectivity_plus
flutter pub add --dev drift_dev mocktail build_runner

# Run tests
flutter test
flutter test test/features/feedback/domain/entities/emoji_choice_test.dart
flutter test --coverage

# Code generation (when Drift tables land, Iteration 9)
dart run build_runner build --delete-conflicting-outputs

# Run app (phone connected via USB, USB debugging on)
flutter devices
flutter run

# Analyze
flutter analyze

# Build
flutter build apk --release

# Git (starts at Iteration 2)
git add .
git commit -m "Iteration N: <objective>"
git push

# Supabase CLI (Phase 6, from Iteration 34)
supabase login
supabase init
supabase functions new submit-feedback
supabase functions new submit-rating
supabase functions deploy submit-feedback
supabase functions deploy submit-rating
```

Android phone prerequisites (run once before Iteration 1):

```bash
# Enable USB debugging on phone, connect via USB, then:
adb devices  # should list your phone
```

---

## 12. Git Workflow

- **Branch:** `main` only for now (solo dev, micro-iterations).
- **Commit message format:**

```text
Iteration N: <short objective>

<optional body describing what changed and why>
```

- **Example:**

```text
Iteration 4: Add AppColors design tokens

Introduces the canonical color palette. All future widgets
must source colors from AppColors, never hardcode.
```

- **Push frequency:** every confirmed iteration.
- **Never commit with failing tests.**
- **Never commit** `.env`, secrets, or `supabase/.branches/`.

---

## 13. Open Assumptions to Confirm As We Go

These are defaults we'll follow unless told otherwise.

| Assumption | Default | Changeable at iteration |
|---|---|---|
| Supabase account | You'll create one at Iteration 34 | — |
| Signing key for release APK | Self-signed for internal testing | 44 |
| Font family | Patrick Hand via `google_fonts` (locked at Iteration 4) | 4 |
| Cooldown duration | 30 seconds | 13 |
| Idle timeout before attract mode | 20 seconds | 31 |
| Supported Android versions | Android 8.0 (API 26)+ | 39 |
| Release build target | Phone (Phase 5), TV (Phase 7) | — |
| Local DB | Drift | 9 (before it's added) |
| Sync interval | 5 min + on-start + on-connectivity-regained | 17 |
| Retry backoff | 2s → 4s → 8s → 16s → 32s → 60s cap, max 6 retries then `failed_permanent` | 16 |

---

## 14. Confirmation Needed Before Iteration 1

Please confirm:

**From the original plan:**

1. **Plan approved** — the roadmap, phases, and principles above all look right.
2. **Tech stack** — Riverpod ✅, mocktail ✅, go_router ✅, Supabase ✅, custom cooldown service ✅, no JS/HTML/CSS ✅.
3. **Design tokens** — Living Sketchbook palette, spacing, typography defaults acceptable.
4. **Phone-first strategy** — TV port deferred to Phase 7.
5. **Ready for Iteration 1** — Flutter installed ✅ (3.47.9 stable detected), phone with USB debugging, Supabase account (or ready to create one at Iteration 34).

**From the offline-first update:**

6. **Local DB: Drift?** ✅ recommended (vs Isar / Hive / raw sqflite).
7. **Iteration count: 44** — acceptable? Or compress (e.g. merge 11+13) toward ~40? Recommendation: keep 44.
8. **`client_id` on server schema** — confirmed as the idempotency key?
9. **Sync triggers** — 5 min background sweep + on-startup + on-connectivity-regained. OK?
10. **Retry backoff** — 2s → 4s → 8s → 16s → 32s → 60s cap, max 6 retries then `failed_permanent`. OK?

**Once confirmed, begin Iteration 1 — Verify Flutter environment, create project, run the default counter app.**

> **Update (2026-11-18):** the build order was re-sequenced per **§0.5** — the app is built offline through Phase 5, Supabase lands in Phase 6 (I34–I38), and TV remains Phase 7 (I39–I44). All confirmations above still stand; only the order changed.

Nothing gets built until you say go. 🚀
