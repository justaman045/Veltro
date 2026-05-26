# Gemini Agent Guide — justaman045 (Aman Ojha)

## About the User

- **Name:** Aman Ojha (justaman045)
- **Role:** QA Automation Engineer @ Infosys (Oct 2021 — Present)
- **Goal:** Transitioning to Senior QA Automation or Full Stack Developer roles
- **GitHub Profile:** https://github.com/justaman045
- **LinkedIn:** linkedin.com/in/justaman045
- **Portfolio:** https://justaman045.vercel.app
- **Blogs:** Dev.to (dev.to/justaman045), Hashnode (justaman045.hashnode.dev)
- **GitHub Token:** (redacted — do not expose or commit)

## Current Project: Agentic-TODO

**Location:** `/home/athena/Development/agentic-todo`

This is the active development workspace — a Flutter to-do & timeline manager.

### Tech
- Flutter (Dart SDK ^3.11.1)
- Riverpod 2.x for state, GetX for navigation/snackbars only
- Firebase Auth + Firestore + Crashlytics + Analytics
- `flutter analyze` passes with zero issues
- Debug APK builds successfully

### Architecture
- Single-package Flutter app, entrypoint: `lib/main.dart`
- No local DB — Firestore is SSOT at `users/{user.email}/tasks`
- Auth gating: `_AuthGate` uses `StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), ...)` directly (Riverpod `authStateProvider` was unreliable)
- Login/SignUp switching: local `_showSignUp` state + callbacks, NEVER `Get.to()` (stacks routes, breaks auth transition)
- DI overrides: `dbServiceProvider` and `sharedPreferencesProvider` throw unless overridden in `ProviderScope(overrides: [...])`
- Drag-drop: `LongPressDraggable` with `RenderBox.globalToLocal()` for 15-min snap
- `Dismissible` removed from timeline cards (conflicted with long-press); delete via `TaskEntryDialog` only

### Commands
| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install deps |
| `flutter pub run build_runner build --delete-conflicting-outputs` | Regenerate `.g.dart` |
| `flutter analyze` | Lint check |
| `flutter test` | Run tests |
| `flutter build apk --release` | Release APK |
| `flutter run --debug` | Run on device |

### Key Files
- `lib/main.dart` — Entry, ProviderScope, _AuthGate
- `lib/models/time_task.dart` — Core model with recurrence
- `lib/providers/providers.dart` — @riverpod annotations
- `lib/services/db_service.dart` — Firestore CRUD
- `lib/services/auth_service.dart` — GoogleSignIn.instance
- `lib/screens/timeline_view.dart` — Drag-drop timeline
- `lib/screens/login_view.dart` / `signup_view.dart` — Auth screens
- `lib/utils/app_colors.dart` — Gradient colors

### Known Gotchas
- `QueryDocumentSnapshot.data()` is non-nullable — do NOT cast with `as Map<String, dynamic>`
- `SettingsService` and `sharedPreferencesProvider` live in `settings_service.dart`, NOT `providers.dart`
- `TimeTask.fromJson` uses `_parseDateTime`/`_parseDateList` helpers — don't replace with direct casts
- `watchTimeline` does all recurring-task projection client-side
- Auth gating uses direct `StreamBuilder` on Firebase Auth — not Riverpod provider

---

# Full GitHub Repository Analysis

Complete analysis saved at: `github_repos_comprehensive_analysis.md` (1403 lines, 60KB)

## All 15 Repositories

### 1. Finance-Control (WealthSync)
- **URL:** https://github.com/justaman045/Finance-Control
- **Public** | MIT License | **Released APK v2.0.118**
- **Stack:** Flutter/Dart, GetX, Firebase
- **Purpose:** Personal finance app — track expenses, 24 asset types, AI SMS parsing, UPI payments, biometric security
- **Model:** Free (150 tx/mo, 10 categories) + Pro ₹249/mo
- **Architecture:** MVC-Service-Repository, 30+ screens, offline-first
- **Payment:** UPI via Kotlin MethodChannel + RevenueCat IAP
- **Key Files:** `lib/main.dart`, `lib/Controllers/*` (14 controllers), `lib/Services/*` (18 services), `lib/Screens/*` (30+ screens)

### 2. Agentic-TODO
- **URL:** https://github.com/justaman045/Agentic-TODO
- **Public** | **Active local development**
- **Stack:** Flutter/Dart, Riverpod 2.x + GetX, Firebase
- **Purpose:** To-do & timeline manager with drag-drop, frosted-glass UI, OTA updates
- **Key features:** Timeline with 15-min drag-drop snap, recurring tasks, Google Sign-In, CI/CD auto-release
- **This is the local codebase** — `/home/athena/Development/agentic-todo`

### 3. Assistant
- **URL:** https://github.com/justaman045/Assistant
- **Public** | Source-available license | Active on Vercel
- **Stack:** Next.js 15, TypeScript, Firebase, OpenRouter AI, Razorpay, Sentry, PostHog
- **Purpose:** Full-stack personal productivity SaaS — AI content creation, planner, finance tracker, subscription manager, roleplay chat, memory system, billing
- **Key routes:** 20+ API routes for AI streaming (SSE), payments, admin, cron
- **Architecture highlights:**
  - AI streaming via SSE from OpenRouter through Next.js API routes
  - Memory system: `users/{uid}/memories/{memoryId}` extracted by LLM after each interaction
  - Credit enforcement: server-side via Firebase Admin SDK
  - Admin panel: API key rotation, model usage tracking, user management

### 4. NextRound
- **URL:** https://github.com/justaman045/NextRound
- **Private** | Pre-launch development
- **Stack:** Next.js 16, TypeScript, Firebase, OpenAI SDK, Puppeteer, Razorpay
- **Purpose:** AI-powered resume builder — multi-template, ATS evaluation, cover letter generation, DOCX/PDF export
- **Templates:** Creative, FaangPath, Minimalist, Modern (Handlebars + Puppeteer)
- **Testing:** Vitest (unit) + Playwright (e2e)

### 5. company (Nexus)
- **URL:** https://github.com/justaman045/company
- **Private** | Active development
- **Stack:** Next.js 16, TypeScript, Firebase, Razorpay + Stripe, Tailwind CSS v4
- **Purpose:** Software e-commerce — products, licenses, dual payments, multi-currency
- **Architecture highlights:**
  - Dual payment: Razorpay (inline modal) or Stripe (redirect to hosted checkout)
  - Multi-currency: IP detection via ipapi.co → 50+ currencies
  - VPN-aware: re-detects currency on IP change
  - Caching: in-memory 5min (products/orders/CMS), 30sec (payment settings), localStorage 1hr (rates), sessionStorage (geo)
  - License keys: auto-generated XXXX-XXXX-XXXX-XXXX on payment success
  - Admin CMS: 8-tab editor (Hero, Stats, About, Testimonials, FAQ, Footer, Categories, Contact)

### 6. Saas-Waitlist
- **URL:** https://github.com/justaman045/Saas-Waitlist
- **Public** | Active development
- **Stack:** Next.js 16, TypeScript, Firebase, Tailwind, shadcn/ui, Framer Motion, Cloudinary
- **Purpose:** Reusable SaaS waitlist system — unlimited projects, custom signup fields, referrals, admin dashboard

### 7. Portfolio (Zenith)
- **URL:** https://github.com/justaman045/Portfolio
- **Public** | MIT License | **Deployed on Vercel**
- **Stack:** Next.js 14, TypeScript, Contentlayer (MDX), Tailwind, shadcn/ui
- **Purpose:** Personal dev portfolio + 30+ blog posts on programming

### 8. Instagram-Content-Analyzer
- **URL:** https://github.com/justaman045/Instagram-Content-Analyzer
- **Public** | 2 stars | CLI tool
- **Stack:** Python, Supabase, Telegram API, GitHub Actions
- **Purpose:** Instagram automation — scheduled posting, monitoring, Telegram notifications

### 9. Job-Application-tracker (North)
- **URL:** https://github.com/justaman045/Job-Application-tracker
- **Public** | MIT License | New (May 11)
- **Stack:** React 19, Vite 8, Tailwind CSS v4, Firebase (Spark free plan), Recharts, dnd-kit
- **Purpose:** Job application tracker PWA — Kanban board, dashboard analytics, offer comparison
- **Deployment:** Firebase Hosting + Docker

### 10. codeitdown
- **URL:** https://github.com/justaman045/codeitdown
- **Public** | MIT License | **Deployed** (https://codeitdown.vercel.app)
- **Stack:** Next.js (JS), Bootstrap/SCSS, Django REST API backend
- **Purpose:** Blog platform frontend consuming Django REST API

### 11. learning-tracker (SDET Tracker)
- **URL:** https://github.com/justaman045/learning-tracker
- **Private** | New (May 11)
- **Stack:** React 18, Vite, Firebase, Tailwind, React Router v6
- **Purpose:** SDET learning progress tracker — topic roadmaps, daily logs, interview prep, notes
- **Firestore:** `users/{uid}/data/{settings, topics, questions, logs, notes}`

### 12. justaman045 (Profile)
- **URL:** https://github.com/justaman045/justaman045
- **Public** | Auto-updating via 3 GH Actions workflows
- **Purpose:** GitHub profile README — AI summary, blog posts, repos, WakaTime stats, contribution snake

### 13. Selenium-AdityaBirla-Automation
- **URL:** https://github.com/justaman045/Selenium-AdityaBirla-Automation
- **Private** | Archived (2023)
- **Stack:** Python, Selenium WebDriver, tkinter
- **Purpose:** ABG sustainability portal form automation — SSO login → incident form filling

### 14. DailyCommit
- **URL:** https://github.com/justaman045/DailyCommit
- **Private** | Active (bot keeps streak)
- **Purpose:** Single `readme.txt` updated with timestamp daily — maintains commit streak

### 15. decognizer
- **URL:** https://github.com/justaman045/decognizer
- **Private** | Inactive (single commit, Feb 2026)
- **Purpose:** Unknown — only `.build_log` artifact

## Technology Distribution

| Technology | Used In |
|---|---|
| Flutter/Dart | Finance-Control, Agentic-TODO |
| Next.js + TypeScript | Assistant, NextRound, company, Saas-Waitlist, Portfolio |
| Next.js + JavaScript | codeitdown |
| React + Vite | Job-Application-tracker, learning-tracker |
| Python | Instagram-Content-Analyzer, Selenium-AdityaBirla-Automation |
| Firebase | All major projects |

## Common Patterns
1. Firebase-centric — all major projects use Firestore + Auth
2. Google Sign-In — primary auth for web apps
3. Next.js App Router — modern web projects
4. Tailwind CSS + shadcn/ui — shared UI stack across web projects
5. CI/CD via GitHub Actions — automated builds/deploys
6. Offline-first for mobile (Finance-Control), cache-heavy for web (Nexus)

## Skill Trajectory
```
QA Automation Engineer (Infosys)
→ Selenium + Java → Python Automation
→ Flutter Mobile Development (Finance-Control)
→ Next.js/React Full-Stack (Assistant, Nexus, NextRound)
→ SaaS Products (Waitlist, Resume builder, E-commerce)
→ Developer Productivity Tools (Job tracker, Learning tracker)
```
