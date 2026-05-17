# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Couple Alarm** (`couple_note` / `couple-alarm`) is a Flutter mobile application designed for couples to set shared alarms, reminders, and timers. The app features Firebase-backed authentication, real-time synchronization between partners, push notifications, and in-app alarm sounds.

**App ID:** `com.yorxbit.couplealarm`  
**Current Version:** 2.0.9+30  
**Flutter SDK:** >=3.8.1  
**Target:** Android 35+ (API 35), iOS support included

## Build & Development Commands

### Essential Commands

```bash
# Clean build and get dependencies
flutter clean
flutter pub get

# Code generation (required after modifying providers/models)
flutter pub run build_runner build --delete-conflicting-outputs

# Build debug APK for Android
flutter build apk --debug

# Build release APK for Android (requires signing)
flutter build apk --release

# Build for iOS
flutter build ios

# Run the app in debug mode
flutter run

# Run with verbose logging
flutter run -v

# Lint analysis
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

### Important Notes on Build Process

- The project uses **Riverpod code generation** (`riverpod_annotation` + `build_runner`). Always run code generation after modifying any provider with `@riverpod` annotation.
- Android release builds require a signing configuration (`android/app/key.properties`) with keystore credentials. The app uses Google Play Integrity for Firebase App Check in production.
- The `.env` file (not in git) contains Cloudflare R2 credentials for avatar uploads. See `.env.example` for required keys.

## Architecture & Code Structure

### High-Level Architecture

The project follows **Clean Architecture** with feature-based organization:

```
lib/
├── main.dart                    # Entry point; Firebase init, notifications setup
├── common/                      # Shared widgets (banners, dialogs, pickers, filters)
├── core/                        # Core utilities and services
│   ├── config/                  # Theme, routing, app constants
│   │   ├── routers/router.dart  # GoRouter setup with auth redirects
│   │   └── theme/               # Material Design 3 theme configuration
│   ├── services/                # Business logic services
│   │   ├── alarm/               # Alarm scheduling (AndroidAlarmManager)
│   │   ├── fcm_service.dart     # Firebase Cloud Messaging
│   │   ├── local_notification_service.dart  # Local notifications
│   │   ├── Admob/               # Google Mobile Ads integration
│   │   ├── auth_service.dart    # Firebase Auth wrapper
│   │   └── cloudfare_r2_service.dart  # R2 object storage
│   ├── providers/               # Global Riverpod providers
│   ├── utils/                   # Helper functions (date, UI, serialization)
│   ├── constants/               # Translation keys, app enums
│   ├── widgets/                 # Reusable UI components
│   └── tools/                   # Custom tools and extensions
└── features/                    # Feature modules (Clean Arch pattern)
    ├── auth/                    # Authentication (login, register, Firebase)
    ├── home/                    # Home tab with alarms and timer
    ├── reminder/                # Reminders (CRUD, notifications)
    ├── alarm/                   # Alarm screen (triggered by notifications)
    ├── couple/                  # Couple profile management
    ├── user/                    # User profile and settings
    ├── connect/                 # QR code pairing with partner
    ├── invitation/              # Couple invitation workflow
    ├── onboarding/              # First-time user onboarding
    ├── setting/                 # App settings
    └── welcome/                 # Welcome/splash screen
```

Each feature module follows the layered pattern:
- **data/:** Models, remote data sources (Firestore), repository implementations
- **domain/:** Business logic entities, use cases, abstract repositories
- **presentation/:** Pages, widgets, Riverpod notifiers/providers, view models

### State Management: Riverpod

The app uses **Flutter Riverpod** (v3.0.3) with `riverpod_annotation` for code generation. Key patterns:

```dart
// Typical feature provider setup
@riverpod
class ReminderNotifier extends _$ReminderNotifier {
  @override
  FutureOr<List<Reminder>> build() async {
    return await ref.read(reminderRepositoryProvider).getReminders();
  }
  
  Future<void> addReminder(Reminder reminder) async {
    await ref.read(reminderRepositoryProvider).addReminder(reminder);
    ref.invalidateSelf();
  }
}
```

Global providers are registered in `lib/core/providers/global_providers.dart`:
- `firestore`, `firebaseStorage` – Firebase instances
- `sharedPreferencesProvider` – Local storage (overridden at app startup)
- `localStorageService` – Wrapper around SharedPreferences
- `r2StorageService`, `avatarUploadService` – Avatar uploads
- `invitationRepository` – Invitation logic

### Routing: GoRouter

Navigation is handled by **GoRouter (v17.0.1)** with auth guards in `lib/core/config/routers/router.dart`:

**Route Structure:**
- `/` – Welcome page
- `/onboarding` – First-time setup
- `/login`, `/register` – Auth pages
- `/home`, `/reminder`, `/setting` – Bottom navigation tabs
- `/home/timer` – Timer page (nested)
- `/connect`, `/scanner` – QR pairing
- `/alarm/:id` – Full-screen alarm trigger
- `/reminder-form` – Add/edit reminders

**Auth Redirect Logic:**
- Unauthenticated users are redirected to `/login` (except public routes).
- First-time users see `/onboarding` instead of home.
- Pending deep links are stored and resumed after login.
- `GoRouterRefreshStream` listens to auth state changes via Riverpod.

### Firebase Integration

**Services:**
- **Firebase Auth:** Google Sign-In + email/password
- **Firestore:** Real-time user data, couple relationships, reminders, invitations
- **Cloud Storage:** User avatars
- **Cloud Functions:** Backend logic (called via `cloud_functions` package)
- **Firebase Messaging (FCM):** Push notifications
- **App Check:** Device integrity validation (Play Integrity on Android, Debug in dev)

**Key Collections:**
- `users/` – User profiles
- `couples/` – Couple relationships
- `reminders/` – Shared reminders
- `invitations/` – Pending couple requests

### Key Dependencies & Patterns

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management with code generation |
| `go_router` | Navigation with auth redirects |
| `firebase_*` | Authentication, Firestore, Storage, Messaging |
| `alarm` | Local alarm scheduling |
| `flutter_local_notifications` | Local notification display |
| `easy_localization` | i18n (Vietnamese, English) |
| `google_fonts`, Material Design 3 | UI theming |
| `qr_flutter`, `mobile_scanner` | QR code generation and scanning |
| `just_audio`, `audioplayers` | Sound playback for alarms |
| `dio` | HTTP client |
| `record` | Audio recording |
| `permission_handler`, `connectivity_plus` | Device permissions and network state |
| `in_app_update`, `in_app_review` | Play Store updates and reviews |

### Important Enums & Models

In `lib/core/config/app_constants.dart`:
- `NotificationType` – alarm, reminder_notification, invitation_response
- `RecurringType` – none, daily, weekly
- `ApprovalStatus` – none, pending, accepted, rejected
- `AssigneeType` – Determines who a reminder is assigned to
- `ReminderStatus` – Active, overdue, done, cancelled

## Localization (i18n)

The app supports **Vietnamese** and **English** using `easy_localization` v3.0.8.

**Translation Files:**
- `assets/translations/en.json` – English strings
- `assets/translations/vi.json` – Vietnamese strings

**Usage:**
```dart
import 'package:easy_localization/easy_localization.dart';

Text(TransKeys.some_key.tr())  // Uses TransKeys from lib/core/constants/trans_keys.dart
```

Supported locales are set in `main.dart` (`Locale('vi')`, `Locale('en')`). The selected locale is persisted via SharedPreferences.

## Notifications & Alarms

**Local Alarms (Device-level):**
- Scheduled via `android_alarm_manager_plus` and the `alarm` package
- Triggered by `AlarmService.initializeLocalNotifications()`
- Callbacks defined in `lib/core/services/alarm/alarm_callbacks.dart`
- Alarms are designed to show even when app is closed (fullscreen intent)

**Push Notifications (FCM):**
- Handled by `FCMService` in `lib/core/services/fcm_service.dart`
- Listens for remote messages and navigates accordingly
- Local notifications are displayed via `flutter_local_notifications`
- Payload carries notification type, ID, and navigation path

**Flow:**
1. Backend sends FCM message with payload
2. `FCMService.onMessage()` triggers local notification
3. User taps notification – `LocalNotifications` launches app with payload
4. `main.dart` parses payload and routes to appropriate screen (e.g., `/alarm/123`)

## Testing

Basic test setup exists in `test/widget_test.dart` but is mostly a smoke test template. The project currently lacks comprehensive unit and widget tests.

**To add tests:**
```bash
flutter test test/widget_test.dart
```

Consider adding tests for:
- Repository implementations (mocking Firestore)
- Riverpod notifiers (with `ProviderContainer` for testing)
- Utility functions and date/time logic

## Performance & Platform-Specific Notes

### Android
- **Min SDK:** Flutter default (19+)
- **Target SDK:** 35
- **NDK:** 28.2.13676358
- **Proguard:** Enabled for release builds (minification)
- **App Check:** Uses Play Integrity Provider in production, Debug Provider in dev
- **Build Variants:** Split APKs by ABI (armeabi-v7a, arm64-v8a, x86_64) with universal fallback

### Permissions Required
- `SCHEDULE_EXACT_ALARM` – For precise alarm scheduling
- `IGNORE_BATTERY_OPTIMIZATIONS` – To ensure alarms fire reliably
- Camera, microphone, contacts, calendar – Feature-specific (requested via permission_handler)

### Network Connectivity
- App monitors connectivity via `connectivity_plus` and `internet_connection_checker`
- A `ConnectivityService` notifies UI of network state changes

## Development Practices

### Code Generation
After modifying files with code generation annotations:
- `@riverpod` (providers/notifiers)
Run: `flutter pub run build_runner build --delete-conflicting-outputs`

### Debugging Tips
- **Firebase Auth issues:** Check `FirebaseAuth.instance.currentUser` and error messages
- **Firestore rules:** Ensure authenticated users have read/write access; rules are stored in Firebase Console
- **Deep links:** Test with `adb shell am start -a android.intent.action.VIEW -d "app://path"`
- **Notifications:** Verify FCM token in logcat; check foreground state (onMessage vs onMessageOpenedApp)
- **Alarms not triggering:** Confirm battery optimization exemption and SCHEDULE_EXACT_ALARM permission

### Common Issues
- **Generated files not updating:** Delete `.dart_tool/`, run `flutter clean`, then `flutter pub run build_runner build --delete-conflicting-outputs`
- **Firebase initialization fails:** Ensure `.env` is loaded and Firebase credentials in `firebase_options.dart` match your project
- **Locale not persisting:** Check SharedPreferences; ensure `saveLocale: true` in `easy_localization`

## Project Metadata

- **Package Name:** `couple_note` (ID: com.yorxbit.couplealarm)
- **Git:** Tracked via git (see `.gitignore` for excluded files)
- **Firebase Project:** `couple-alarm-569c8`
