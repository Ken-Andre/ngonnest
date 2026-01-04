# System Patterns - NgoNest

## Architecture Overview

### MVVM + Repository Pattern Implementation
```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (MVVM)                         │
├─────────────────────────────────────────────────────────────┤
│  Screens/Views  ←→  ViewModels/Providers  ←→  Services      │
├─────────────────────────────────────────────────────────────┤
│               Repository Layer (Data Access)                │
├─────────────────────────────────────────────────────────────┤
│  Repositories  ←→  Services  ←→  Database (SQLite)          │
│                    │                                        │
│                    ↓                                        │
│              External APIs (Optional)                       │
└─────────────────────────────────────────────────────────────┘
```

### Core Architecture Principles
1. **Separation of Concerns**: Clear boundaries between UI, business logic, and data
2. **Dependency Injection**: Services injected via Provider pattern
3. **Error Handling**: Centralized error management with user-friendly messages
4. **Offline First**: All repositories work with local SQLite database
5. **State Management**: Provider pattern for reactive UI updates

## Key Technical Decisions

### Database Strategy
- **SQLite** as primary data store with AES-256 encryption
- **Repository Pattern** for data access abstraction
- **Migration System** for schema evolution
- **Backup/Restore** functionality for data portability

### State Management
- **Provider Pattern** for dependency injection and state management
- **ViewModels** for UI-specific business logic
- **Repository Pattern** for data access abstraction
- **Service Layer** for complex business operations

### Error Management
- **ErrorLoggerService** for comprehensive error tracking
- **User-friendly error messages** in French/English/local languages
- **Graceful degradation** when services fail
- **Retry mechanisms** for transient failures

## Component Relationships

### Core Dependencies
```
main.dart
    ↓
App (MaterialApp)
    ↓
Providers (MultiProvider)
    ├── LocaleProvider (internationalization)
    ├── FoyerProvider (household management)
    └── ThemeProvider (UI theming)
    ↓
MainNavigationWrapper
    ↓
Screens (BottomNavigationBar)
    ├── DashboardScreen
    ├── InventoryScreen
    ├── BudgetScreen
    ├── SettingsScreen
    └── OnboardingScreen
```

### Service Layer Architecture
```
Services/
├── Core Services
│   ├── ErrorLoggerService (error tracking)
│   ├── ConnectivityService (real-time network monitoring with pre-flight checks)
│   ├── AnalyticsService (usage tracking + connectivity events)
│   └── BackgroundTaskService (scheduled tasks)
│
├── Business Services (Static)
│   ├── BudgetService (financial calculations - static methods)
│   ├── BudgetAllocationRules (household-based budget recommendations)
│   ├── PredictionService (consumption forecasting)
│   ├── AlertGenerationService (notifications)
│   ├── ExportImportService (data portability)
│   └── CalendarSyncService (external integration)
│
└── Data Services
    ├── Database (SQLite - encryption planned)
    ├── RemoteConfigService (Firebase config)
    └── SyncService (cloud synchronization - blocked by schema mismatch)
```

## Design Patterns in Use

### 1. Repository Pattern
**Purpose**: Abstract data access and provide consistent interface
**Implementation**:
- `BaseRepository<T>` interface for all repositories
- `InventoryRepository`, `BudgetRepository`, `FoyerRepository`
- Centralized error handling and data transformation

### 2. Provider Pattern (State Management)
**Purpose**: Dependency injection and reactive state management
**Implementation**:
- `ChangeNotifierProvider` for simple state
- `FutureProvider` for async operations
- `StreamProvider` for real-time data

### 3. Service Layer Pattern
**Purpose**: Encapsulate business logic and external integrations
**Implementation**:
- `BudgetService` for financial calculations (static methods)
- `BudgetAllocationRules` for household-based budget recommendations
- `PredictionService` for ML-based forecasting
- `AlertGenerationService` for notification management
**Note**: BudgetService uses static methods instead of ChangeNotifier for simplicity

### 4. Factory Pattern
**Purpose**: Object creation abstraction
**Implementation**:
- `ProductFactory` for creating product instances
- `AlertFactory` for notification creation
- `ExportFactory` for different export formats

### 5. Observer Pattern
**Purpose**: Reactive updates across components
**Implementation**:
- Provider pattern enables reactive UI updates
- Alert system notifies users of important events
- Budget tracking updates in real-time

## Critical Implementation Paths

### 1. User Onboarding Flow
```
OnboardingScreen
    ↓
Household Profile Creation (FoyerProvider)
    ↓
Initial Inventory Setup (InventoryRepository)
    ↓
Budget Configuration (BudgetService)
    ↓
Dashboard Display (DashboardScreen)
```

### 2. Inventory Management Flow
```
Product Addition (AddProductScreen)
    ↓
Smart Categorization (CategoriesDurables)
    ↓
Quantity Tracking (SmartQuantitySelector)
    ↓
Consumption Logging (ConsumptionInputField)
    ↓
Prediction Updates (PredictionService)
    ↓
Alert Generation (AlertGenerationService)
```

### 3. Budget Tracking Flow
```
Expense Logging (BudgetScreen)
    ↓
Category Classification (BudgetCategory with percentage)
    ↓
Budget Analysis (BudgetService - static methods)
    ↓
Dynamic Recalculation (BudgetAllocationRules)
    ↓
Visual Reporting (Charts/Graphs - pending)
    ↓
Predictive Alerts (AlertGenerationService - console only, Task 6 pending)
    ↓
Sync Operations (SyncService integration - Task 5 pending)
    ↓
Export Functionality (ExportImportService)
```

### 4. Connectivity Monitoring Flow
```
App Startup
    ↓
ConnectivityService Initialization
    ↓
Stream Subscription (connectivity_plus)
    ↓
Network Status Change Detection
    ↓
ConnectivityBanner Display (if offline/reconnected)
    ↓
Auto-dismiss after 4 seconds
    ↓
Analytics Event Tracking (connectivity_change)
```

## Data Flow Architecture

### Offline-First Strategy
1. **Local Storage**: All data stored in encrypted SQLite
2. **Service Layer**: Business logic operates on local data
3. **Optional Sync**: Cloud synchronization when connectivity available
4. **Conflict Resolution**: Last-write-wins with user notification

### Error Recovery Patterns
1. **Circuit Breaker**: Services temporarily disable on repeated failures
2. **Retry Logic**: Exponential backoff for transient failures
3. **Fallback UI**: Graceful degradation with user feedback
4. **Data Validation**: Input sanitization and constraint checking

## Performance Optimizations

### Database Optimizations
- **Indexes** on foreign keys and search fields
- **Batch Operations** for bulk data changes
- **Lazy Loading** for large datasets
- **Connection Pooling** for database efficiency
- **Schema Versioning**: Local DB at v12 with percentage column
- **Migration Strategy**: Cloud migration SQL ready but not applied
- **Critical Issue**: INTEGER vs UUID ID mismatch blocks cloud sync

### UI Optimizations
- **List Virtualization** for large inventory lists
- **Image Caching** for product photos
- **Background Tasks** for heavy computations
- **Memory Management** for low-end devices
- **Search Debouncing** (150ms) for real-time search without lag
- **Theme-aware Colors** using colorScheme for automatic light/dark mode
- **AnimatedOpacity** for smooth banner transitions

## Windows Development Environment

### Development Setup
- **Platform**: Windows 11 Pro (x64)
- **IDE Options**: VS Code-based , Android Studio
- **Flutter SDK**: Windows-compatible installation
- **Android SDK**: Windows paths and environment variables
- **Database Tools**: SQLite browser/command-line for Windows

### Path Management (Windows-Specific)
- **Project Path**: `c:\Users\yoann\Documents\School\Xp-X4\Busi\NgoNest\ngonnest\`
- **Flutter Path**: `%LOCALAPPDATA%\Flutter` or custom installation directory
- **Android SDK**: `%LOCALAPPDATA%\Android\sdk` or custom path
- **Command Format**: Use backslashes (`\`) in Windows paths and PowerShell commands

### Build Commands (Windows Compatible)
```powershell
# Navigation dans le projet
cd c:\Users\yoann\Documents\School\Xp-X4\Busi\NgoNest\ngonnest\code\flutter\ngonnest_app

# Installation des dépendances
flutter pub get

# Vérification du code
flutter analyze
flutter format --set-exit-if-changed lib test

# Tests unitaires et d'intégration
flutter test --coverage

# Build pour Android
flutter build apk --release

# Build pour développement
flutter build apk --debug

# Lancement en mode développement
flutter run --hot
```


## Recent Architectural Decisions

### ConnectivityService with Real-time Monitoring (December 2024)
**Decision**: Implemented ConnectivityService with ChangeNotifier pattern for network status

**Implementation**:
- Real-time network monitoring via connectivity_plus stream
- Pre-flight checks for critical operations (DNS test to Supabase)
- Network error detection helper methods
- Analytics integration for connectivity events
- ConnectivityBanner widget with theme-aware colors
- AppWithConnectivityOverlay for global banner display

**Benefits**:
- ✅ Non-intrusive UX with auto-dismiss banners
- ✅ Proactive network checks before sync operations
- ✅ Better error messages for network-related failures
- ✅ Analytics tracking for connectivity patterns
- ✅ WCAG AA compliant with theme integration

### BudgetService Static Architecture (November 2024)
**Decision**: Converted BudgetService from ChangeNotifier to static class

**Rationale**:
- All callers throughout codebase use static method calls
- No UI components actually listening to BudgetService
- BudgetScreen uses FutureBuilder and manual refresh, not listeners
- Simpler architecture without ChangeNotifier overhead
- Easier to test with static methods
- Consistent with existing usage patterns

**Trade-offs**:
- ❌ Lost automatic UI updates via listeners
- ✅ Simpler code, no memory management concerns
- ✅ No need for Provider setup
- ✅ Matches actual usage patterns

**Alternative Considered**: Keep ChangeNotifier and update all callers to use instance methods. Rejected because it would require changes to 10+ files and the UI doesn't actually need reactive updates.

### Budget Percentage System (November 2024)
**Decision**: Implement percentage-based dynamic budget allocation

**Implementation**:
- BudgetCategory model enhanced with percentage field (default 0.25)
- BudgetAllocationRules engine for household-based calculations
- recalculateCategoryBudgets() method for automatic updates
- Default percentages: Hygiène 33%, Nettoyage 22%, Cuisine 28%, Divers 17%

**Benefits**:
- Dynamic budgets adjust when total budget changes
- Household size and type influence recommendations
- More flexible than hardcoded values
- Better user experience with proportional allocations

## Security Patterns

### Data Protection
- **AES-256 Encryption** for SQLite database (planned, not implemented)
- **Secure Storage** for sensitive configuration
- **Input Validation** to prevent injection attacks
- **Access Control** for feature permissions

### Privacy Protection
- **Local-First** approach minimizes data exposure
- **Optional Analytics** with user consent
- **Data Export** for user data control
- **Clear Privacy Policy** in multiple languages
