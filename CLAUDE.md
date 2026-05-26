# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `flutter pub run build_runner build --delete-conflicting-outputs` | Regenerate Riverpod `.g.dart` files after editing providers |
| `flutter analyze` | Lint check (treat warnings as failures — they exit non-zero) |
| `flutter test` | Run all tests |
| `flutter test test/widget_test.dart` | Run a single test file |
| `flutter build apk --release` | Release APK |
| `flutter run --debug` | Run on device/emulator |

## Architecture

**Single-package Flutter app** — entrypoint: `lib/main.dart`.

**Dual state management**: Riverpod (auth, tasks, DI) + GetX (navigation, snackbars). Screens are `ConsumerStatefulWidget` (Riverpod), but navigate with `Get.to()` and show toasts with `Get.snackbar()`. Do not mix these: use Riverpod `ref.watch` for state, GetX only for imperative navigation/notifications.

**No local database** — `DbService.init()` is a no-op. Firestore is the sole data store. Firestore path: `users/{user.email}/tasks`.

**DI via ProviderScope overrides** — `dbServiceProvider` and `sharedPreferencesProvider` throw `UnimplementedError` unless overridden at app start in `main.dart`'s `ProviderScope(overrides: [...])`.

**Auth gating** — `_AuthGate` in `main.dart` uses `StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), ...)`. Non-null user → `UnifiedScreen`, null → `LoginView`/`SignUpView`. Login/SignUp switching uses local `_showSignUp` state + callbacks, **not** `Get.to()` (which stacks Navigator routes and breaks auth transition). The Riverpod `authStateProvider` was unreliable for auth transitions — direct StreamBuilder on Firebase Auth is the fix.

**`UnifiedScreen`** is the root post-auth shell with a frosted-glass bottom nav bar hosting two tabs: `TimelineView` (scheduled tasks by date, drag-drop with 15-min snap) and `TodoView` (unscheduled todos). The FAB opens `TaskEntryDialog` as a modal bottom sheet.

## Key files

| File | Role |
|------|------|
| `lib/models/time_task.dart` | Core model. `TimeTask` has `RecurrenceType` (none/daily/weekly/monthly/weekdays). Recurring tasks project a virtual copy per date in `watchTimeline`. Dates stored as ISO-8601 strings in Firestore. |
| `lib/providers/providers.dart` | All `@riverpod` provider declarations. Edit here → run build_runner. |
| `lib/providers/providers.g.dart` | Generated — do not edit manually. |
| `lib/services/db_service.dart` | All Firestore CRUD. `watchTimeline(date)` handles recurring task projection and past-pending task surfacing client-side. |
| `lib/services/settings_service.dart` | `ChangeNotifier` backed by `SharedPreferences`. Both `sharedPreferencesProvider` and `settingsServiceProvider` are declared here. |
| `lib/controllers/update_controller.dart` | Fetches `app_version.json` from `raw.githubusercontent.com/justaman045/agentic-todo/master/` to detect OTA updates. |

## Firebase

- Android config: `android/app/google-services.json` (checked in). No `firebase_options.dart` — `Firebase.initializeApp()` relies on platform-level config files.
- iOS: requires `GoogleService-Info.plist` (not checked in — add locally).
- `AuthService` uses `GoogleSignIn.instance` singleton (google_sign_in 7.x API).

## Codegen

After editing any `@riverpod`-annotated provider in `lib/providers/providers.dart`, regenerate:

```
flutter pub run build_runner build --delete-conflicting-outputs
```

`**/*.g.dart` is excluded from the analyzer (`analysis_options.yaml`).

## CI/CD

Triggers on push to `master`/`main` (skip with `[skip ci]` in commit message). The workflow auto-bumps the patch version in `pubspec.yaml`, commits back with `[skip ci]`, generates `app_version.json`, and creates a GitHub release with the release APK.

## Known gotchas

- `doc.data()` on `QueryDocumentSnapshot` is already non-nullable `Map<String, dynamic>` in cloud_firestore 4.x — do not cast it with `as Map<String, dynamic>` (triggers `unnecessary_cast` warning, fails CI).
- `SettingsService` and `sharedPreferencesProvider` are both declared in `lib/services/settings_service.dart`, not in `providers.dart`.
- `watchTimeline` performs all recurring-task projection and deduplication client-side in a single Firestore stream — there is no server-side date filtering for recurring tasks.
- `TimeTask.fromJson` uses `_parseDateTime`/`_parseDateList` helpers that handle both `String` and Firestore `Timestamp` — do not replace with direct casts.
- Login/SignUp navigation uses callbacks + local `_showSignUp` state in `_AuthGate`. Never use `Get.to()` between these two screens — it stacks routes and the auth-state rebuild can't reach the top route.
- Auth gating is a `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` directly (not via Riverpod `authStateProvider`). The provider was unreliable for auth transitions.

---

# Comprehensive GitHub Repository Analysis

> **User:** justaman045 (Aman Ojha) — QA Automation Engineer @ Infosys | Aspiring Full Stack Developer
> **Core Skills:** Java, Selenium, Python, Flutter (Dart), Next.js/React (TypeScript), Firebase, MERN Stack
> **Full analysis saved at:** `github_repos_comprehensive_analysis.md` (1403 lines, 60KB)
> **GitHub Token:** (redacted — do not commit)

## All 15 Repositories — Quick Reference

### 1. Finance-Control (WealthSync)
- **URL:** https://github.com/justaman045/Finance-Control
- **Status:** Public, MIT License, Released APK (v2.0.118)
- **Stack:** Flutter/Dart, GetX, Firebase (Auth + Firestore + Crashlytics)
- **Purpose:** Full-featured personal finance app with 24 asset types, AI SMS parsing, biometric security, UPI payments, free + Pro model (₹249/mo)
- **Architecture:** MVC-Service-Repository, 30+ screens, offline-first
- **Key files:** `lib/main.dart`, `lib/Controllers/*`, `lib/Services/*`, `lib/Screens/*`

### 2. Agentic-TODO
- **URL:** https://github.com/justaman045/Agentic-TODO
- **Status:** Public, Active local development
- **Stack:** Flutter/Dart, Riverpod 2.x + GetX, Firebase
- **Purpose:** To-do & timeline manager with drag-drop, frosted-glass UI, OTA updates
- **Architecture:** Provider-Service-Model, `_AuthGate` StreamBuilder, Riverpod for state/GetX for nav
- **Key files:** `lib/main.dart`, `lib/screens/timeline_view.dart`, `lib/providers/providers.dart`

### 3. Assistant (Personal Dashboard)
- **URL:** https://github.com/justaman045/Assistant
- **Status:** Public, Source-available license, Active (last push May 13)
- **Stack:** Next.js 15, TypeScript, Firebase, OpenRouter AI, Razorpay, Sentry, PostHog
- **Purpose:** Full-stack personal productivity SaaS — AI content creation, planner, finance tracker, subscriptions, roleplay chat, memory system
- **Architecture:** Next.js App Router (protected + API + admin routes), SSE streaming for AI, memory extraction after each AI interaction
- **Key files:** `src/app/api/*`, `src/lib/*`, `src/context/*`

### 4. NextRound
- **URL:** https://github.com/justaman045/NextRound
- **Status:** Private, Pre-launch (active development)
- **Stack:** Next.js 16, TypeScript, Firebase, OpenAI SDK, Puppeteer, Razorpay
- **Purpose:** AI-powered resume builder with tailoring, ATS evaluation, DOCX/PDF export, cover letter generation
- **Architecture:** App Router, 4 resume templates (Creative/FAANG/Minimalist/Modern), Handlebars rendering
- **Key files:** `app/api/ai/*`, `components/templates/*`, `components/dashboard/*`

### 5. company (Nexus)
- **URL:** https://github.com/justaman045/company
- **Status:** Private, Active development
- **Stack:** Next.js 16, TypeScript, Firebase, Razorpay + Stripe, Tailwind CSS v4, Framer Motion
- **Purpose:** Software e-commerce platform — products, licenses, dual payment gateways, multi-currency (50+ currencies), admin CMS
- **Architecture:** App Router, dual-gateway checkout (Razorpay modal / Stripe redirect), IP-based geo-detection, 5-min in-memory caching
- **Key files:** `src/app/products/*`, `src/app/admin/*`, `src/lib/*`, `DOCUMENTATION.md`

### 6. Saas-Waitlist
- **URL:** https://github.com/justaman045/Saas-Waitlist
- **Status:** Public, Active development
- **Stack:** Next.js 16, TypeScript, Firebase, Tailwind, shadcn/ui, Framer Motion, Cloudinary
- **Purpose:** Reusable SaaS waitlist system — unlimited projects, custom fields, referrals, launch emails, admin dashboard
- **Architecture:** App Router, Firebase Auth+Firestore, react-hook-form + zod
- **Key files:** `app/admin/*`, `components/*`, `lib/db-service.ts`

### 7. Portfolio (Zenith)
- **URL:** https://github.com/justaman045/Portfolio
- **Status:** Public, MIT License, Deployed on Vercel
- **Stack:** Next.js 14, TypeScript, Contentlayer (MDX), Tailwind, shadcn/ui
- **Purpose:** Personal dev portfolio + blog (30+ posts on programming topics)
- **Architecture:** Contentlayer for MDX content, RSS feed, newsletter, SEO, dark mode
- **Key files:** `content/posts/*`, `app/(site)/*`, `components/*`

### 8. Instagram-Content-Analyzer
- **URL:** https://github.com/justaman045/Instagram-Content-Analyzer
- **Status:** Public, 2 stars, CLI tool
- **Stack:** Python, Selenium/requests, Supabase, Telegram API
- **Purpose:** Instagram automation framework — scheduled posting, monitoring, Telegram notifications
- **Architecture:** Modular (instagram/, db/, jobs/, tgram/, utils/), CLI interface, GH Actions schedules
- **Key files:** `bot.py`, `cli.py`, `scheduler.py`, `instagram/*`, `jobs/*`

### 9. Job-Application-tracker (North)
- **URL:** https://github.com/justaman045/Job-Application-tracker
- **Status:** Public, MIT License, New (May 11)
- **Stack:** React 19, Vite 8, Tailwind CSS v4, Firebase, Recharts, dnd-kit
- **Purpose:** Job application tracker with Kanban board, dashboard analytics, offer comparison, PWA
- **Architecture:** React Router v7, Firebase Spark plan (free), vite-plugin-pwa, Docker deployment
- **Key files:** `src/pages/*`, `src/components/*`, `src/hooks/useApplications.js`

### 10. codeitdown
- **URL:** https://github.com/justaman045/codeitdown
- **Status:** Public, MIT License, Deployed on Vercel (https://codeitdown.vercel.app)
- **Stack:** Next.js (JavaScript), Bootstrap/SCSS, Django REST API backend
- **Purpose:** Blog platform frontend consuming Django REST API — categories, hashtags, search, comments
- **Architecture:** API-driven (all content from backend), SSR for SEO, dynamic sitemap
- **Key files:** `pages/*`, `components/*`, `Data/index.json`

### 11. learning-tracker (SDET Tracker)
- **URL:** https://github.com/justaman045/learning-tracker
- **Status:** Private, New (May 11)
- **Stack:** React 18, Vite, Firebase, Tailwind, React Router v6
- **Purpose:** SDET learning progress tracker — daily logs, topic roadmaps, interview prep, notes
- **Architecture:** Firebase Auth + Firestore, onboarding wizard, Google Sign-In
- **Key files:** `src/pages/*`, `src/data/topics.js`, `src/hooks/useFirestoreData.js`

### 12. justaman045 (Profile README)
- **URL:** https://github.com/justaman045/justaman045
- **Status:** Public, Active (auto-updating via GH Actions)
- **Stack:** Markdown, GitHub Actions (3 workflows: manual, snake, wakatime)
- **Purpose:** GitHub profile README with auto-updated AI summary, blog posts, repos, WakaTime stats, snake animation

### 13. Selenium-AdityaBirla-Automation
- **URL:** https://github.com/justaman045/Selenium-AdityaBirla-Automation
- **Status:** Private, Archived/Inactive (last push June 2023)
- **Stack:** Python, Selenium WebDriver, tkinter
- **Purpose:** Automates ABG sustainability portal form filling — Microsoft SSO login → incident form automation
- **Key files:** `automater.py` (AutoBot class), `data.json`

### 14. DailyCommit
- **URL:** https://github.com/justaman045/DailyCommit
- **Status:** Private, Active (bot keeps streak)
- **Stack:** Text file + automation bot
- **Purpose:** Maintains daily commit streak — single `readme.txt` with timestamp updated daily

### 15. decognizer
- **URL:** https://github.com/justaman045/decognizer
- **Status:** Private, Inactive (single commit, Feb 2026)
- **Stack:** Unknown (only `.build_log` artifact)
- **Purpose:** Unknown — likely scaffolding or build artifact storage

## Technology Distribution

| Technology | Repos |
|---|---|
| Flutter (Dart) | Finance-Control, Agentic-TODO |
| Next.js (TypeScript) | Assistant, NextRound, company, Saas-Waitlist, Portfolio |
| Next.js (JavaScript) | codeitdown |
| React + Vite | Job-Application-tracker, learning-tracker |
| Python | Instagram-Content-Analyzer, Selenium-AdityaBirla-Automation |
| Firebase | All major projects (Firestore + Auth) |

## Common Patterns

1. Firebase-centric — almost every project uses Firebase (Auth + Firestore)
2. Google Sign-In — primary auth method across all web apps
3. Dual state management — Finance-Control uses GetX; Agentic-TODO uses Riverpod + GetX
4. Next.js App Router — all newer web projects use App Router
5. Tailwind CSS — used in all web projects (v3 or v4)
6. shadcn/ui components — shared UI pattern
7. CI/CD via GitHub Actions — most projects have automated builds

## Skill Trajectory

```
QA Automation Engineer (Infosys) → Selenium + Java → Python Automation
→ Flutter Mobile (Finance-Control) → Next.js/React Full-Stack (Assistant, Nexus, NextRound)
→ SaaS Products (Waitlist, Resume builder, E-commerce)
→ Developer Productivity Tools (Job tracker, Learning tracker)
```

## GitHub Token

A GitHub token was used to fetch all repo data including private repos. Must not be exposed or committed.
