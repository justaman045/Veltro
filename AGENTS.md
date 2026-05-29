# agentic_todo — agent guide

## Commands

| Command | Purpose |
|---------|---------|
| `./run.sh` | run on device/emulator in debug mode (reads API keys from `config.dev.json`) |
| `./testrun.sh` | run on device/emulator in release mode (reads API keys from `config.dev.json`) |
| `./release-build.sh` | mimic CI locally: analyze + test + build release APK with release keystore (auto-creates if missing). Install with `adb install` and add SHA-1 to Firebase Console for Google sign-in. |
| `./test.sh` | run all tests (no API keys needed) |
| `flutter pub get` | install dependencies |
| `flutter pub run build_runner build --delete-conflicting-outputs` | regenerate Riverpod `.g.dart` after editing providers |
| `flutter analyze` | lint check (warnings exit non-zero — they fail CI) |
| `flutter test` | run all tests (alias: `./test.sh`) |
| `flutter run --dart-define-from-file=config.dev.json` | same as `./run.sh` (manual equivalent) |
| `flutter run --release --dart-define-from-file=config.dev.json` | same as `./testrun.sh` (manual equivalent) |
| `flutter build apk --release --dart-define-from-file=config.prod.json` | local release build with production keys |

## Architecture

- **Single-package Flutter app** — entrypoint: `lib/main.dart`
- **Dual state management**: Riverpod (state, DI) + GetX (navigation, snackbars). Screens use `ConsumerStatefulWidget` + `ref.watch` for state, `Get.to()`/`Get.snackbar()` for imperative UI. Do not mix.
- **No local database** — `DbService.init()` is a no-op. Firestore is single source of truth at `users/{user.email}/tasks`. Templates at `users/{user.email}/templates`.
- **DI overrides** — `dbServiceProvider`, `sharedPreferencesProvider`, `subscriptionServiceProvider`, and `aiServiceProvider` throw `UnimplementedError` unless overridden in `main.dart`'s `ProviderScope(overrides: [...])`.
- **Auth gating** — `_AuthGate` in `main.dart` uses a `StreamBuilder<User?>` on `FirebaseAuth.instance.authStateChanges()` directly (not via Riverpod `authStateProvider`, which was unreliable). Non-null → `UnifiedScreen`, null → `LoginView`/`SignUpView`. Switching uses local `_showSignUp` state + callbacks, **not** `Get.to()` (stacks routes and breaks auth transition).
- **Onboarding** — shown before auth, stored in `SharedPreferences` key `onboarding_complete`. Gated via local `_onboardingComplete` state in `_AuthGate`.
- **`UnifiedScreen`** — root post-auth shell with frosted-glass bottom nav: 3 tabs (Timeline / Todos / Calendar). FAB opens `TaskEntryDialog` as modal bottom sheet; long-press FAB shows sheet with "AI Task Breakdown" and "Templates" (templates gated behind Pro).

## Firebase

- Android config: `android/app/google-services.json` (checked in). No `firebase_options.dart` — `Firebase.initializeApp()` uses platform-level config.
- iOS: requires `GoogleService-Info.plist` (not checked in).
- `AuthService` uses `GoogleSignIn.instance` singleton (google_sign_in 7.x API).
- Firestore persistence enabled via `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true)`.
- `firestore.rules` at repo root — basic data isolation by email. NOT deployed by CI; deploy manually.

## Codegen

- `lib/providers/providers.g.dart` — auto-generated from `lib/providers/providers.dart` via `@riverpod`/`@Riverpod` annotations. Must run build_runner after editing `providers.dart`.
- `**/*.g.dart` excluded from analyzer (`analysis_options.yaml`).
- Plain `Provider`/`StateProvider`/`FutureProvider`/`StreamProvider` declarations do NOT need annotations — only `@riverpod`/`@Riverpod` annotated functions need codegen.

## Key services

| Service | File | Notes |
|---------|------|-------|
| `AuthService` | `lib/services/auth_service.dart` | GoogleSignIn.instance singleton |
| `DbService` | `lib/services/db_service.dart` | Firestore CRUD on `users/{email}/tasks`, templates at `users/{email}/templates`. MergeOpts pattern. |
| `SettingsService` | `lib/services/settings_service.dart` | `ChangeNotifier` backed by `SharedPreferences`. Both `sharedPreferencesProvider` and `settingsServiceProvider` declared here, **not** in `providers.dart`. |
| `NotificationService` | `lib/services/notification_service.dart` | Singleton. 15-min-before reminders via `flutter_local_notifications`. Uses stable hashing (`_stableId`). |
| `SubscriptionService` | `lib/services/subscription_service.dart` | Firestore-backed tier system. Reads `userProfiles/{email}` doc for `tier` field and `isAdmin` flag. Exposes `tier`, `isPro`, `isProMax`, `isAdmin`, plus streams. Admin can set any user's tier via `setTier(email, tier)`. |
| `AiService` | `lib/services/ai_service.dart` | OpenRouter HTTP client (`openai/gpt-oss-120b:free`). Rate-limited (2s interval). |

## Subscriptions (Firestore-backed)

- **Tiers**: `free` / `pro` / `proMax`. Stored as `tier` field on `userProfiles/{email}` doc in Firestore.
- **Admin flag**: `isAdmin` field on `userProfiles/{email}`. Admin users see "Admin Settings" in settings page and can toggle any user's tier.
- **Provider pattern**: `subscriptionServiceProvider` is a plain `Provider<SubscriptionService>`. `isProProvider` is `StreamProvider<bool>` reading from `service.isProStream`.
- **Sync bool access**: `ref.read(subscriptionServiceProvider).isPro` in event handlers.
- **Reactive bool**: `ref.watch(isProProvider).valueOrNull ?? false` in build methods.
- **`isAdminProvider`**: `StreamProvider<bool>` for admin flag.
- **`tierProvider`**: `StreamProvider<String>` for current user's tier.
- **`PricingView`** (`lib/screens/pricing_view.dart`) — shows current tier and upgrade buttons. Sets Firestore `tier` field directly.
- **`AdminSettingsView`** (`lib/screens/admin_settings_view.dart`) — entry point for admin-only settings.
- **`ManageUsersView`** (`lib/screens/manage_users_view.dart`) — lists all users from `userProfiles` collection, dropdown to change each user's tier.
- **No RevenueCat** — the system uses Firestore directly with no third-party purchase SDK. All "upgrades" are free tier changes managed by admins.
- **DI override**: `subscriptionServiceProvider.overrideWithValue(subService)` in `main.dart`.
- **`ChangeNotifierProvider` does NOT have `.overrideWithValue()`** — use plain `Provider` instead.

## AI Service

- **OpenRouter free model**: `openai/gpt-oss-120b:free`. Key via `String.fromEnvironment('OPENROUTER_API_KEY')`.
- **Rate limiting**: enforced client-side with 2s minimum between calls via `_rateLimitedCall()`.
- **Free tier**: 3 AI actions/day via `aiUsageCountProvider` (`StateProvider<int>`). Pro = unlimited.
- **Methods**: `parseTaskFromText(text)` → `Map<String, dynamic>`, `breakdownTask(goal)` → `List<TimeTask>`, `dailyBriefing(todayTasks, userName)` → string.
- **Category mapping**: AI returns `growth` → mapped to `other`; `urgent` priority → mapped to `high`.
- **Fallback on error**: all methods return safe defaults instead of crashing.

## CI/CD

- Triggers on push to `master`/`main`. Skip with `[skip ci]` in commit message.
- **Version bump**: reads `VERSION_BUMP` file from repo root. Uncomment one: `major` / `minor` / `patch`. After CI runs, the keyword is commented out.
  - `major` → MAJOR+1, MINOR=0, PATCH=0
  - `minor` → MINOR+1, PATCH=0
  - `patch` → PATCH+1
  - Build number always +1. Invalid/missing keyword = workflow failure.
- Generates `app_version.json` on `master` — consumed by `UpdateController.checkForUpdates()` for OTA update prompts.
- Creates GitHub release with `app-release.apk`. Updates README badge.

## OTA update flow

- `UpdateController` fetches version JSON from `raw.githubusercontent.com/justaman045/agentic-todo/master/app_version.json`.
- Format: `{"version": "1.0.1+2", "changelog": "...", "downloadUrl": "..."}`.
- Semver comparison via `_compareSemVer()` which flattens `major.minor.patch+build` into a numeric power-of-1000 sum.

## Key gotchas

- **`QueryDocumentSnapshot.data()` is non-nullable** in cloud_firestore 4.x. Do NOT cast with `as Map<String, dynamic>` — triggers `unnecessary_cast` warning, exits non-zero in `flutter analyze`, fails CI.
- **`watchTimeline`** performs all recurring-task projection + deduplication client-side. No server-side date filtering for recurring tasks.
- **`TimeTask.fromJson`** uses `_parseDateTime`/`_parseDateList` helpers that handle both `String` and Firestore `Timestamp` — do not replace with direct casts.
- **Login/SignUp navigation** uses callbacks + local `_showSignUp` state in `_AuthGate`. Never use `Get.to()` between these two screens — it stacks routes and the auth-state rebuild can't reach the top route.
- **Auth gating** is a `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` (not Riverpod `authStateProvider`) — the provider was unreliable for auth transitions.
- **Providers declared outside `providers.dart`** — `sharedPreferencesProvider` and `settingsServiceProvider` live in `lib/services/settings_service.dart`, not in `lib/providers/providers.dart`.
- **`StreamProvider<bool>` returns `AsyncValue<bool>` from `ref.watch()`** — access `.valueOrNull ?? false` for a `bool`. Use `ref.read(service).isPro` for sync reads outside build.
- **`OutlinedButton.icon` uses `onPressed`**, `InkWell` uses `onTap` — mixing them causes `undefined_named_parameter` errors.
- **`withValues(alpha: ...)`** is used throughout (Flutter 3.27+). Do NOT use the deprecated `withOpacity()`.
- **AI task categories** — `TimeTask.category.name` values: `work`, `personal`, `health`, `finance`, `other` (no `growth`, no `urgent`). The AI service maps `growth` → `other`, `urgent` → `high`.
- **API keys** — passed via `--dart-define-from-file=config.*.json` at build time. Local dev uses `config.dev.json` (gitignored). CI uses GitHub Secrets `REVENUECAT_API_KEY` and `OPENROUTER_API_KEY` injected at build time. No `defaultValue` — build fails with clear error if keys missing.
- **`firestore.rules`** is checked in but NOT deployed by CI — deploy manually via Firebase Console or `firebase deploy --only firestore:rules`.
## Dismissible + tight height constraints

- **DO NOT** rely on `Positioned(height:)` or `SizedBox(height:)` wrapping a `TaskCard` (or any widget that internally uses `Dismissible`) to enforce tight height — `Dismissible` does NOT propagate tight constraints from its parent, causing the card to shrink to content height.
- **Fix**: Pass `height` as a constructor parameter and apply `SizedBox(height: widget.height)` **inside** the `Dismissible`'s child subtree, wrapping the card `Container` directly.
- **Lane overlap**: `_assignLanes` must use **visual bounds** (`_topForTime(start) + _taskHeight(task)`) instead of time-based bounds when `minTaskHeight` causes short tasks to visually extend past their end time. Otherwise expanded cards overlap.
- **`minTaskHeight` rule**: set to `hourHeight` (72px) so 30-min tasks extend exactly to the next half-hour boundary without overlapping the next task. Content must be compact enough to fit within this height (tighten padding/fonts).

## Key gotchas (continued)

- **SHA-1 fingerprints**: Google sign-in requires fingerprints in Firebase Console.
  - Local release keystore: auto-printed by `./release-build.sh`
  - Local release keystore (`~/local_release.keystore`): `8E:9D:C5:CC:5F:6A:E9:E5:EB:A9:F8:FB:49:7F:05:BB:90:9D:10:40` (same keystore set as `KEYSTORE_BASE64` secret for CI)
  - CI debug keystore (`KEYSTORE_BASE64` not set): `C6:A7:98:39:5F:57:0B:D8:4C:A2:5A:61:1F:4F:7B:CB:E3:B9:A9:C0` — CI skips release signing when secret is empty, falls back to debug keystore. Extract via: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>&1 | grep "SHA-1"`

## Animation System

### Shared Constants (`lib/utils/animations.dart`)

```dart
const kAnimFast = Duration(milliseconds: 200);
const kAnimNormal = Duration(milliseconds: 350);
const kAnimSlow = Duration(milliseconds: 500);
const kCurveSpring = Curves.easeOutBack;
const kCurveBounce = Curves.elasticOut;
const kCurveSmooth = Curves.easeInOutCubic;
```

Existing helpers: `animDuration(context, ms:)` (respects `disableAnimations`), `AnimatedContext.animateIfEnabled()` extension, `fadeSlideIn()`, `scaleIn()`.

### Animation Library Choice

- **Primary**: `flutter_animate` — for one-shot entrance/exit effects (staggered list appearance, page entrances). Already imported in 5 files.
- **State-driven transitions**: Use built-in `AnimatedContainer`, `AnimatedScale`, `AnimatedSwitcher`, `TweenAnimationBuilder` — these persist across rebuilds and don't retrigger on every frame.
- **Rule**: `flutter_animate` for entry animations; `Animated*` widgets for toggle/state transitions.

### Phase 1 — Quick Wins (Implemented)

| File | Animation | Mechanism |
|------|-----------|-----------|
| `lib/widgets/task_card.dart` | Checkmark pop on complete | `AnimatedContainer` (fill/border) + `AnimatedScale` (icon 0→1 with `easeOutBack`) |
| `lib/screens/todo_view.dart` | Checkbox fill + check pop | Same pattern as task_card |
| `lib/widgets/day_view.dart` | Drop zone highlight fade | `AnimatedContainer` on DragTarget builder decoration |
| `lib/screens/unified_screen.dart` | FAB press scale | `AnimatedScale` with `onTapDown`(0.92)→`onTapUp`(1.0) via setState |
| `lib/screens/calendar_view.dart` | Month slide transition | `AnimatedSwitcher` + `SlideTransition` with `ValueKey('grid_$_displayMonth')` |
| `lib/screens/pomodoro_view.dart` | Smooth progress arc | `TweenAnimationBuilder<double>` wrapping `CircularProgressIndicator` |

### Phase 2 — Core UX Polish (Planned)

| File | Animation | Approach |
|------|-----------|----------|
| `lib/widgets/day_view.dart` | Current time indicator | `AnimatedPositioned` red line at `DateTime.now()`, updated by `Timer.periodic(60s)` |
| `lib/screens/stats_view.dart` | Chart entrance animations | `fl_chart` built-in `fromY: 0` + animate duration |
| `lib/widgets/ai_task_breakdown_sheet.dart` | Staggered task appearance | Generated list items with `.fadeIn().slideY()` staggered 50ms |
| `lib/screens/pomodoro_view.dart` | Focus↔Break color transition | `AnimatedContainer` on phase label background |
| `lib/widgets/task_card.dart` | Overdue label pulse | `.animate().shimmer()` on overdue text |

### Phase 3 — Premium Feel (Planned)

| File | Animation | Approach |
|------|-----------|----------|
| `lib/screens/calendar_view.dart` | Today cell pulse | `.animate().scale()` repeating on today's date cell |
| `lib/screens/todo_view.dart` | Progress bars animated | `TweenAnimationBuilder<double>` for subtask `LinearProgressIndicator` |
| `lib/widgets/task_entry_dialog.dart` | Subtask list animations | `AnimatedList` for add/remove |
| `lib/screens/templates_view.dart` | Staggered item entrance | `.fadeIn().slideY()` on template cards at load |
| `lib/screens/stats_view.dart` | Number counting animation | `TweenAnimationBuilder<int>` on stat card values |
| `lib/screens/onboarding_view.dart` | Per-page content stagger | Icon → title → description with delayed fade+scale |

### Animation Gotchas

- **`Obx` + `TweenAnimationBuilder`**: Inside `Obx(() { ... })`, the entire subtree rebuilds on every observable change. A `TweenAnimationBuilder` inside will restart its tween each rebuild. Use a `key` that only changes on state transitions (e.g., `ValueKey('progress_${isBreak}')`) to prevent retriggering on every frame.
- **`AnimatedSwitcher` keying**: `AnimatedSwitcher` detects child changes via `Key`. Always provide a `ValueKey` on the child that changes when the content changes (e.g., `ValueKey('grid_$_displayMonth')`). Without it, the switcher won't animate.
- **`AnimatedContainer` with `null` decoration**: `AnimatedContainer` cannot tween to/from `null` decoration. If your state switches between a `BoxDecoration` and `null`, provide an empty `BoxDecoration()` instead of `null` so the container can interpolate.
- **FAB press + `GestureDetector`**: Adding `onTapDown`/`onTapUp` to a `GestureDetector` that wraps a `FloatingActionButton` works for scale animation. The `FloatingActionButton`'s internal `onPressed` fires on tap-up, so the scale is visible during the press. Always check `mounted` in `onTapUp`/`onTapCancel` callbacks to avoid calling `setState` after dispose.
- **`Container` → `AnimatedContainer`**: Plain `Container` with conditional decoration (e.g., `color: isCompleted ? primary : transparent`) is instant. Replacing with `AnimatedContainer` with a `duration` gives a smooth fill transition. Include the `curve` parameter for polish.
- **Border width animation**: `AnimatedContainer` supports animating `Border.width`. Use `width: isCompleted ? 0 : 2` for a smooth border disappearance.
- **CircularProgressIndicator intrinsic animation**: `CircularProgressIndicator` redraws immediately on value change — it does NOT interpolate between values internally. For smooth transitions (e.g., session mode switch), wrap in `TweenAnimationBuilder<double>`.
