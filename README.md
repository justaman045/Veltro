# Veltro

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)
[![Platform: iOS](https://img.shields.io/badge/Platform-iOS-000000?logo=apple)](https://apple.com)

<!-- LATEST_RELEASE_START -->

[![Download APK](https://img.shields.io/badge/Download_APK_v1.1.1+10-FCC624?style=for-the-badge&logo=android&logoColor=black)](https://github.com/justaman045/Veltro/releases/download/v1.1.1+10/app-arm64-v8a-release.apk)

<!-- LATEST_RELEASE_END -->

An AI-powered task manager built with Flutter and Firebase — featuring smart timeline scheduling, habit streaks, Pomodoro focus sessions, recurring tasks, and real-time sync across devices.

---

## Features

### 🤖 AI-Powered
- **AI Task Parsing** — type "Call dentist tomorrow at 3pm" and the AI auto-fills title, category, priority, date, time, and recurrence
- **AI Goal Breakdown** — long-press the + button and break a high-level goal into actionable subtasks with suggested scheduling
- **AI Daily Briefing** — see a 2-3 sentence AI summary of today's tasks every morning
- **AI Model Selection** — choose from any OpenRouter-free or paid model directly in Settings

### 📋 Smart Task Management
- **Priority Groups** — High / Medium / Low with color-coded sections and collapsible completed view
- **Recurring Tasks** — daily, weekly, monthly, and weekday repetition with streak tracking
- **Habit Streaks** — fire emoji counter for consecutive completions
- **Subtasks** — inline checkboxes with progress bars
- **Search & Filter** — cross-date search with category filter chips

### 📅 Timeline & Calendar
- **Scrollable Daily Timeline** — 24-hour view with drag-and-drop task scheduling
- **Date Picker** — jump to any date with the calendar picker
- **Calendar View** — month overview with color-coded category dots; tap to jump to that date
- **Swipe Navigation** — swipe left/right to change dates in timeline

### ⏱️ Pomodoro Timer
- 25-minute focus sessions with break reminders
- Tap the timer chip on any task to start a focused session

### 📦 Templates
- Save any task as a reusable template
- Long-press the + button to access templates (Pro feature)
- Reuse templates for quick task creation

### 🔄 Sync & Backup
- Real-time sync across devices via Firebase Firestore
- Google Sign-In for one-tap authentication
- CSV export with formula-injection protection

### 🎨 Customization
- Light / Dark / System theme modes
- Multiple accent color gradients
- AI model selection (free & paid models)

---

## Screenshots

<!-- TODO: Add screenshots here -->

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter (Material 3, Google Fonts) |
| State Management | Riverpod 2.x (state + DI) + GetX (navigation, snackbars) |
| Backend | Firebase Firestore + Firebase Auth |
| Crash Reporting | Firebase Crashlytics |
| Notifications | flutter_local_notifications |
| Payments / Subscriptions | RevenueCat v9 |
| AI | OpenRouter API (configurable model, free & paid) |
| CI/CD | GitHub Actions (auto version-bump + APK release) |
| Splash | flutter_native_splash |
| Icons | flutter_launcher_icons |

---

## Architecture

```
lib/
├── main.dart                  # Entrypoint, DI overrides, auth gating
├── controllers/               # GetX controllers (pomodoro, updates)
├── models/                    # Data models (TimeTask)
├── providers/                 # Riverpod providers (codegen + manual)
├── screens/                   # All UI screens
│   ├── unified_screen.dart    # Post-auth shell with bottom nav
│   ├── timeline_view.dart     # Daily timeline
│   ├── todo_view.dart         # Task list with priority groups
│   ├── calendar_view.dart     # Month calendar
│   ├── settings_view.dart     # Settings with pro gating
│   ├── ai_model_view.dart     # AI model picker
│   ├── ... (17+ screens)
├── services/                  # Business logic layer
│   ├── db_service.dart        # Firestore CRUD
│   ├── ai_service.dart        # OpenRouter HTTP client
│   ├── subscription_service.dart  # RevenueCat wrapper
│   ├── auth_service.dart      # Firebase Auth + Google Sign-In
│   ├── settings_service.dart  # SharedPreferences
│   ├── notification_service.dart  # Local notifications
├── utils/                     # Utility functions
│   ├── app_colors.dart        # Theme extensions
│   ├── csv_export.dart        # CSV escape utilities
│   ├── nlp_parser.dart        # Local NLP date/time parsing
├── widgets/                   # Reusable widgets
│   ├── task_entry_dialog.dart # Task create/edit bottom sheet
│   ├── timeline_item.dart     # Timeline card component
│   ├── ai_briefing_card.dart  # Daily briefing
│   ├── ai_task_breakdown_sheet.dart  # AI breakdown dialog
```

### Key Patterns

- **Auth gating**: StreamBuilder on `FirebaseAuth.instance.authStateChanges()` in `_AuthGate` widget
- **Onboarding**: Shown before auth, persisted in SharedPreferences
- **DI**: All services overridden via `ProviderScope(overrides: [...])` in `main.dart`
- **State**: Riverpod for reactive state; GetX only for navigation (`Get.to()`, `Get.snackbar()`)
- **AI rate limiting**: Client-side 2s interval between calls + circuit breaker after 5 consecutive failures

---

## Screens

| Screen | Route | Auth Required | Pro Required |
|--------|-------|---------------|--------------|
| Onboarding | `_AuthGate` | No | No |
| Login | `_AuthGate` | No | No |
| Sign Up | `_AuthGate` | No | No |
| Splash | `_AuthGate` | No | No |
| Unified (Tab Shell) | `UnifiedScreen` | Yes | No |
| Timeline | Tab 0 | Yes | No |
| Todos | Tab 1 | Yes | No |
| Calendar | Tab 2 | Yes | No |
| Task Entry | Bottom Sheet | Yes | No |
| AI Task Breakdown | Bottom Sheet | Yes | Free (3/day) |
| Settings | `Get.to` | Yes | No |
| Account Profile | `Get.to` | Yes | No |
| Notifications | `Get.to` | Yes | No |
| Appearance | `Get.to` | Yes | No |
| AI Model | `Get.to` | Yes | No |
| Pomodoro Timer | `Get.to` | Yes | No |
| Productivity Stats | `Get.to` | Yes | Yes |
| Task Templates | `Get.to` | Yes | Yes |
| Pricing | `Get.to` | Yes | No |
| About | `Get.to` | Yes | No |

---

## Prerequisites

- Flutter SDK ^3.11.1
- Dart SDK ^3.11.1
- A Firebase project (Android + iOS)
- A RevenueCat account (with entitlement ID `pro`)
- An OpenRouter API key

---

## Setup

### 1. Clone & install

```bash
git clone https://github.com/justaman045/Veltro.git
cd Veltro
flutter pub get
```

### 2. Generate Riverpod code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configure API keys

Create `config.dev.json` in the project root:

```json
{
  "REVENUECAT_API_KEY": "your_public_sdk_key",
  "OPENROUTER_API_KEY": "your_openrouter_key"
}
```

> **Note**: RevenueCat uses the **public SDK key** (found in the RevenueCat dashboard under "Keys"), not the secret key.

For production builds, set these as GitHub Secrets and the CI workflow will inject them automatically.

### 4. Firebase setup

- **Android**: `android/app/google-services.json` is already checked in
- **iOS**: Place `GoogleService-Info.plist` downloaded from Firebase Console at `ios/Runner/GoogleService-Info.plist`

### 5. Run

```bash
./run.sh
# or manually:
flutter run --dart-define-from-file=config.dev.json
```

---

## API Keys Reference

| Key | Source | Format | Used For |
|-----|--------|--------|----------|
| `REVENUECAT_API_KEY` | RevenueCat Dashboard | `test_...` or `appl_...` | Subscription management |
| `OPENROUTER_API_KEY` | OpenRouter Dashboard | `sk-or-v1-...` | AI task parsing, breakdown, briefing |

Both are injected via `--dart-define-from-file` at build time and accessed via `String.fromEnvironment()`.

---

## Available Scripts

| Command | Purpose |
|---------|---------|
| `./run.sh` | Run on device/emulator with local API keys |
| `./test.sh` | Run all unit tests |
| `flutter pub get` | Install dependencies |
| `flutter pub run build_runner build --delete-conflicting-outputs` | Regenerate Riverpod `.g.dart` files |
| `flutter analyze` | Static analysis (0 warnings required for CI) |
| `flutter test` | Run all tests |
| `flutter build apk --release --dart-define-from-file=config.prod.json` | Release APK with production keys |

---

## Testing

Run all tests:

```bash
./test.sh
# or: flutter test
```

Current test coverage: **47 tests** across 5 test files:

| Test File | Tests | What it covers |
|-----------|-------|----------------|
| `test/models/time_task_test.dart` | 16 | `fromJson`/`toJson` round-trip, defaults, fallbacks |
| `test/services/ai_service_test.dart` | 21 | `aiParsePriority`, `aiParseCategory` |
| `test/services/notification_service_test.dart` | 5 | `stableId` determinism |
| `test/utils/csv_escape_test.dart` | 10 | CSV injection prevention |
| `test/widget_test.dart` | 2 | Smoke tests |

---

## Pro Features

The following features require a Pro subscription via RevenueCat:

- 🔓 Unlimited AI actions (free tier: 3/day)
- 📊 Productivity Stats screen
- 📦 Task Templates
- 💾 CSV Export (free to export own data)

Pro status is checked client-side via `isProProvider` (StreamProvider) and `SubscriptionService.isPro` (sync bool).

---

## CI/CD

Every push to `master` triggers a GitHub Actions workflow that:

1. Reads `VERSION_BUMP` to decide the bump type (`major` / `minor` / `patch`)
2. Creates `config.ci.json` from GitHub Secrets
3. Bumps version in `pubspec.yaml` and comments out the used keyword
4. Generates `app_version.json` for in-app update checks
5. Runs `flutter build apk --release`
6. Publishes a GitHub Release with the APK attached
7. Updates the README badge

### How to bump versions

Before pushing, edit `VERSION_BUMP` and uncomment ONE keyword:

```
# Next version bump type (uncomment ONE):
patch
```

| You write | Result |
|-----------|--------|
| `major` | `1.2.3` → `2.0.0+1` |
| `minor` | `1.2.3` → `1.3.0+1` |
| `patch` | `1.2.3` → `1.2.4+1` |

After the CI run, the file is auto-commented for the next release.

### In-App Updates

The app checks for updates on launch via `UpdateController` which fetches `app_version.json` from the `master` branch's raw GitHub URL.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure `flutter analyze` passes with zero warnings before submitting.

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

---

## Acknowledgments

- [Firebase](https://firebase.google.com/) for backend infrastructure
- [RevenueCat](https://www.revenuecat.com/) for subscription management
- [OpenRouter](https://openrouter.ai/) for AI model access
- [Flutter](https://flutter.dev/) for the UI framework
- [Riverpod](https://riverpod.dev/) for state management
