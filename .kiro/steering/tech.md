# NgonNest - Technical Stack

## Framework & Language
- **Flutter 3.x** with **Dart 3.9+**
- Null-safety required
- Platform: Android (primary), iOS, Web, Desktop (Windows/Linux/macOS)

## Core Dependencies
- **Database**: `sqflite` (local SQLite), `sqflite_common_ffi` (desktop)
- **State Management**: `provider` (ChangeNotifierProvider for mutable state)
- **Backend**: `supabase_flutter` (optional cloud sync)
- **Notifications**: `flutter_local_notifications`, `workmanager` (background tasks)
- **Connectivity**: `connectivity_plus`
- **i18n**: `flutter_localizations`, `intl`
- **Firebase**: `firebase_core`, `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`
- **Security**: `flutter_secure_storage`, AES-256 encryption

## Architecture Patterns
- **Repository pattern**: Data abstraction layer
- **Service layer**: Business logic (one service per domain)
- **Provider pattern**: State management and dependency injection
- **Offline-first**: Local SQLite as source of truth, optional cloud sync

## Project Structure
```
lib/
├── config/          # App configuration (prices, categories, Supabase)
├── l10n/            # Internationalization (FR/EN/ES .arb files)
├── models/          # Data models with toMap()/fromMap()
├── providers/       # State management (Provider/ChangeNotifier)
├── repository/      # Data access layer
├── screens/         # UI screens
├── services/        # Business logic services
├── theme/           # AppTheme, ThemeModeNotifier
├── utils/           # Utilities (accessibility, ID generation)
├── widgets/         # Reusable UI components
├── db.dart          # Database constants
└── main.dart        # App entry point
```

## Common Commands
```bash
# Install dependencies
flutter pub get

# Format code
flutter format --set-exit-if-changed lib test

# Analyze code
flutter analyze

# Run tests
flutter test

# Generate code (mocks, i18n)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Build APK
flutter build apk --release
```

## Database
- **SQLite** via `sqflite` with migrations in `DatabaseService`
- Models require `toMap()` and `fromMap()` methods
- Indexes on foreign keys and search fields
- AES-256 encryption for sensitive data

## Testing
- **Unit tests**: Services, repositories (≥80% coverage target)
- **Widget tests**: Complex widgets and critical screens
- **Integration tests**: End-to-end flows
- **Mocks**: `mockito` with `build_runner`
- Test location: `test/` directory

## Performance
- Lazy loading for large lists
- Pagination for >50 items
- Image compression and caching
- Dispose controllers and streams properly
- Avoid unnecessary rebuilds (use `const` constructors)

## Security
- AES-256 encryption for local data
- Explicit permission requests with justification
- No sensitive data in logs
- Input sanitization and validation
