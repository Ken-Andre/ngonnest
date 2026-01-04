# NgonNest - Project Structure

## Repository Layout
```
ngonnest/
├── code/
│   ├── flutter/ngonnest_app/    # Main Flutter application
│   └── telegram_bot/             # Telegram bot for GitHub issues
├── docs/                         # Product & technical documentation
│   ├── cahier_des_charges/       # Requirements specifications
│   ├── specs/                    # Technical specifications
│   ├── tests/                    # Test plans
│   ├── ui_improvements/          # UI/UX documentation
│   └── user_guide/               # User documentation
├── issues/                       # GitHub issue templates
│   ├── bug_template.md
│   └── feedback_template.md
├── .kiro/                        # Kiro AI assistant configuration
│   ├── steering/                 # AI guidance rules
│   └── specs/                    # Feature specifications
├── AGENTS.md                     # AI agent guidelines
└── README.md                     # Project overview
```

## Flutter App Structure
```
code/flutter/ngonnest_app/
├── lib/
│   ├── config/                   # Configuration files
│   │   ├── cameroon_prices.dart  # Local product prices (FCFA)
│   │   ├── categories_durables.dart
│   │   └── supabase_config.dart
│   ├── l10n/                     # Internationalization
│   │   ├── app_en.arb            # English translations
│   │   ├── app_fr.arb            # French translations (primary)
│   │   └── app_es.arb            # Spanish translations
│   ├── models/                   # Data models
│   │   ├── objet.dart            # Product/inventory item
│   │   ├── foyer.dart            # Household
│   │   ├── budget_category.dart  # Budget category
│   │   ├── alert.dart            # Notification alert
│   │   └── household_profile.dart
│   ├── providers/                # State management
│   │   ├── foyer_provider.dart   # Household state
│   │   └── locale_provider.dart  # Language state
│   ├── repository/               # Data access layer
│   │   ├── foyer_repository.dart
│   │   └── inventory_repository.dart
│   ├── screens/                  # UI screens
│   │   ├── dashboard_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── add_product_screen.dart
│   │   ├── edit_product_screen.dart
│   │   ├── budget_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── onboarding_screen.dart
│   │   └── authentication_screen.dart
│   ├── services/                 # Business logic
│   │   ├── database_service.dart # SQLite operations
│   │   ├── sync_service.dart     # Offline/online sync
│   │   ├── budget_service.dart   # Budget management
│   │   ├── household_service.dart
│   │   ├── notification_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── auth_service.dart     # Supabase authentication
│   │   ├── analytics_service.dart # Firebase Analytics
│   │   ├── error_logger_service.dart
│   │   └── price_service.dart    # Product pricing
│   ├── theme/                    # Theming
│   │   ├── app_theme.dart        # Light/dark themes
│   │   └── theme_mode_notifier.dart
│   ├── utils/                    # Utilities
│   │   ├── accessibility_utils.dart
│   │   └── id_utils.dart         # UUID generation
│   ├── widgets/                  # Reusable components
│   │   ├── connectivity_banner.dart
│   │   ├── main_navigation_wrapper.dart
│   │   ├── inventory_search_bar.dart
│   │   ├── inventory_filter_panel.dart
│   │   ├── quick_quantity_update.dart
│   │   ├── budget_category_card.dart
│   │   └── sync_status_indicator.dart
│   ├── db.dart                   # Database constants
│   └── main.dart                 # App entry point
├── test/                         # Tests
│   ├── integration/              # Integration tests
│   ├── services/                 # Service unit tests
│   ├── widgets/                  # Widget tests
│   └── helpers/                  # Test helpers
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── supabase/                     # Supabase migrations
│   └── migrations/
├── pubspec.yaml                  # Dependencies
├── analysis_options.yaml         # Linter rules
└── l10n.yaml                     # i18n configuration
```

## Key Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Private members**: `_leadingUnderscore`
- **Constants**:  `camelCase` for const

## Navigation Structure
Main app has 5 tabs:
1. **Dashboard** (`/dashboard`) - Overview with stats
2. **Inventory** (`/inventory`) - Product list with search/filters
3. **Add Product** (`/add-product`) - Quick add form
4. **Budget** (`/budget`) - Budget categories and tracking expenses ...
5. **Settings** (`/settings`) - App configuration

## Data Flow
1. **UI (Screens/Widgets)** → User interactions
2. **Providers** → State management
3. **Services** → Business logic
4. **Repositories** → Data abstraction
5. **DatabaseService** → SQLite persistence
6. **SyncService** → Optional cloud sync (Supabase)

## Model Requirements
All models must implement:
- `toMap()` - Convert to Map for SQLite
- `fromMap(Map)` - Create from SQLite Map
- `copyWith()` - Immutable updates (recommended)
- Null-safety with proper `?` and `!` usage unless if dead code might happen
