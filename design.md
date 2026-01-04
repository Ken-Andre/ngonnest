# NGONNEST – DESIGN DOCUMENT (ARCHITECTURE TECHNIQUE)

## Overview

Ce document décrit les solutions techniques pour rendre NgonNest production-ready selon les phases V1/V2/V3.
Priorité : **V1 MVP Offline-Only** puis améliorations progressives.

---

## Architecture Générale

### État Actuel (Pre-V1)

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
├─────────────────────────────────────────────────────┤
│  Screens (Dashboard, Inventory, Budget, Settings)   │
│  - Certains liens morts ou non fonctionnels         │
│  - Messages d'erreur techniques                     │
│  - Pas d'onboarding                                 │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                Business Logic Layer                  │
├─────────────────────────────────────────────────────┤
│  Services (Auth, Budget, Alert, Sync)               │
│  - Sync partiellement implémenté                    │
│  - Alertes non persistées                           │
│  - Clés API potentiellement en code                 │
│  - Pas de feature flags                             │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                     Data Layer                       │
├─────────────────────────────────────────────────────┤
│  SQLite Database                                    │
│  - Schéma incomplet (manque alert_states)          │
│  - Prix possiblement outdated                      │
│                                                     │
│  Supabase (si connecté)                            │
│  - Active même en release (non souhaité V1)        │
└─────────────────────────────────────────────────────┘
```

### État Cible V1 (MVP Offline-Only)

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
├─────────────────────────────────────────────────────┤
│  OnboardingFlow (4 slides)                          │
│  ✅ Welcome → Inventory → Budget → Alerts           │
│                                                     │
│  DashboardScreen                                    │
│  ✅ Quick actions (add, inventory, budget, settings)│
│  ✅ Pagination/lazy loading                         │
│  ✅ Performance <2s avec 500+ produits              │
│                                                     │
│  AddProductScreen                                   │
│  ✅ Validation en temps réel                        │
│  ✅ Prix suggérés (RegionConfig)                    │
│                                                     │
│  BudgetScreen                                       │
│  ✅ Vue simple : budget, dépensé, reste             │
│  ✅ Alertes 90%/100%                                │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                Business Logic Layer                  │
├─────────────────────────────────────────────────────┤
│  FeatureFlagService                                 │
│  ✅ isCloudSyncEnabled = false (V1)                 │
│  ✅ isPremiumEnabled = false (V1)                   │
│                                                     │
│  BudgetService                                      │
│  ✅ Calculs offline, alertes 90%/100%               │
│                                                     │
│  AlertService                                       │
│  ✅ Fusion avec AlertStateRepository                │
│  ✅ Persistence état lu/résolu                      │
│                                                     │
│  PriceService + RegionConfig                        │
│  ✅ Multi-pays (CM, NG, CI...)                      │
│  ✅ Prix locaux Cameroun (500+ produits)            │
│                                                     │
│  ErrorMessageService                                │
│  ✅ Messages FR user-friendly                       │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                     Data Layer                       │
├─────────────────────────────────────────────────────┤
│  SQLite Database (Source de vérité V1)              │
│  ✅ Table alert_states (migration 0012)             │
│  ✅ Table prices (500+ produits Cameroun)           │
│  ✅ Indexes optimisés                               │
│  ✅ Schéma validé pour store compliance             │
│                                                     │
│  Supabase (V3+ uniquement)                         │
│  ❌ Désactivé en V1 (feature flag)                  │
└─────────────────────────────────────────────────────┘
```

### État Cible V2 (Post-MVP)

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
├─────────────────────────────────────────────────────┤
│  BudgetScreen + Graphs                              │
│  ✅ Graphiques barres/camembert (fl_chart)          │
│  ✅ Export PDF rapports                             │
│                                                     │
│  DashboardScreen + AI Predictions                   │
│  ✅ Suggestions "Rupture dans X jours"              │
│                                                     │
│  PaywallScreen                                      │
│  ✅ Premium : achat unique ou abonnement            │
│                                                     │
│  Micro-interactions                                 │
│  ✅ Haptic feedback, animations, confetti           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                Business Logic Layer                  │
├─────────────────────────────────────────────────────┤
│  FeatureFlagService                                 │
│  ✅ isPremiumEnabled = true (si acheté)             │
│                                                     │
│  AiPredictionService                                │
│  ✅ TensorFlow Lite on-device                       │
│  ✅ Prédiction consommation locale                  │
│                                                     │
│  PdfExportService                                   │
│  ✅ Génération rapports budget                      │
│                                                     │
│  RevenueCat Integration                             │
│  ✅ Achat unique / abonnement                       │
└─────────────────────────────────────────────────────┘
```

### État Cible V3+ (Cloud & Entreprise)

```
┌─────────────────────────────────────────────────────┐
│                Business Logic Layer                  │
├─────────────────────────────────────────────────────┤
│  FeatureFlagService                                 │
│  ✅ isCloudSyncEnabled = true (si opt-in)           │
│                                                     │
│  SyncService (Supabase)                             │
│  ✅ Queue-based sync bidirectionnelle               │
│  ✅ Conflict resolution (local wins)                │
│                                                     │
│  FamilySharingService                               │
│  ✅ Invitations, permissions, multi-user            │
│                                                     │
│  EnterpriseService                                  │
│  ✅ Multi-espaces (hôtel/resto)                     │
│  ✅ Analytics avancées                              │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                     Data Layer                       │
├─────────────────────────────────────────────────────┤
│  SQLite (toujours source de vérité locale)          │
│  + sync_queue pour opérations offline               │
│                                                     │
│  Supabase Cloud                                     │
│  ✅ Tables households, products, budgets            │
│  ✅ Row Level Security (RLS)                        │
│  ✅ Real-time subscriptions                         │
└─────────────────────────────────────────────────────┘
```

---

## Composants Clés V1

### 1. Security & Configuration (Requirement V1.1)

**Problème** : Clés API en code source, pas de séparation environnements.

**Solution** :
- `flutter_dotenv` pour variables d'environnement
- `.env`, `.env.dev`, `.env.prod` (non commités)
- Service `EnvConfig` pour accès sécurisé
- Obfuscation release builds

```dart
// lib/config/env_config.dart
class EnvConfig {
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw StateError('SUPABASE_URL not found in environment');
    }
    return url;
  }
}
```

### 2. Feature Flags (Requirement V1.2)

**Problème** : Pas de mécanisme pour désactiver features non prêtes.

**Solution** :
- Service `FeatureFlagService` central
- Flags basés sur build mode (kDebugMode, kReleaseMode)
- UI conditionnelle (cachée ou grisée)

```dart
// lib/services/feature_flag_service.dart
class FeatureFlagService {
  bool get isDevMode => kDebugMode || kProfileMode;

  bool isCloudSyncEnabled() {
    // V1: false en production, true en dev pour tests
    return isDevMode;
  }

  bool isPremiumEnabled() {
    // V1: toujours false
    return false;
  }
}
```

### 3. Alert Persistence (Requirement V1.3)

**Problème** : États alertes (lu/résolu) non persistés.

**Solution** :
- Table SQLite `alert_states`
- Repository `AlertStateRepository`
- Fusion états au chargement

```sql
-- Migration 0012
CREATE TABLE alert_states (
  id INTEGER PRIMARY KEY,
  alert_id TEXT UNIQUE NOT NULL,
  is_read INTEGER DEFAULT 0,
  is_resolved INTEGER DEFAULT 0,
  updated_at TEXT NOT NULL
);

CREATE INDEX idx_alert_states_alert_id ON alert_states(alert_id);
```

```dart
// lib/repository/alert_state_repository.dart
class AlertStateRepository {
  final DatabaseService _db;

  Future<void> saveAlertState(AlertState state) async {
    await _db.database.insert(
      'alert_states',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, AlertState>> getAllAlertStates() async {
    final maps = await _db.database.query('alert_states');
    return {
      for (var map in maps)
        map['alert_id'] as String: AlertState.fromMap(map)
    };
  }
}
```

### 4. Prix Multi-Région (Requirement V1.6)

**Problème** : Prix hardcodés Cameroun uniquement, pas extensible.

**Solution** :
- Classe `RegionConfig` avec détection auto pays
- Table `prices` avec source/date
- Service `PriceService` pour moyennes

```dart
// lib/config/region_config.dart
class RegionConfig {
  final String countryCode;
  final String currencyCode;
  final String currencySymbol;

  const RegionConfig(this.countryCode, this.currencyCode, this.currencySymbol);

  static const regions = {
    'CM': RegionConfig('CM', 'XAF', 'FCFA'),
    'NG': RegionConfig('NG', 'NGN', '₦'),
    'CI': RegionConfig('CI', 'XOF', 'FCFA'),
  };

  static RegionConfig detect() {
    // Détection via Intl.systemLocale ou Platform
    final locale = Intl.systemLocale; // ex: "fr_CM"
    final countryCode = locale.split('_').last;
    return regions[countryCode] ?? regions['CM']!; // Fallback Cameroun
  }
}
```

---

## Patterns & Best Practices

### Repository Pattern

```dart
// lib/repository/inventory_repository.dart
class InventoryRepository {
  final DatabaseService _db;

  Future<List<Product>> getAllProducts() async {
    final maps = await _db.database.query('products');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> addProduct(Product product) async {
    return await _db.database.insert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db.database.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    await _db.database.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### Service Layer avec Error Handling

```dart
// lib/services/budget_service.dart
class BudgetService {
  final BudgetRepository _budgetRepo;
  final ErrorLoggerService _logger;
  final ErrorMessageService _errorMessages;

  Future<BudgetSummary> getBudgetSummary(int month, int year) async {
    try {
      final budget = await _budgetRepo.getBudget(month, year);
      final spent = await _budgetRepo.getTotalSpent(month, year);
      return BudgetSummary(
        budget: budget,
        spent: spent,
        remaining: budget - spent,
        percentageUsed: (spent / budget) * 100,
      );
    } catch (e, stackTrace) {
      _logger.log(e, stackTrace, severity: Severity.error);
      throw BudgetException(_errorMessages.getUserMessage(e));
    }
  }
}
```

### Provider Setup (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Charger .env

  runApp(
    MultiProvider(
      providers: [
        Provider<FeatureFlagService>(
          create: (_) => FeatureFlagService(),
        ),
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        ProxyProvider<DatabaseService, InventoryRepository>(
          update: (_, db, __) => InventoryRepository(db),
        ),
        ProxyProvider<DatabaseService, BudgetRepository>(
          update: (_, db, __) => BudgetRepository(db),
        ),
        // ... autres providers
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Performance Optimizations V1

### Pagination

```dart
// ListView.builder avec lazy loading
class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  int _currentPage = 0;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    final products = await _repo.getProducts(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );
    setState(() {
      _products.addAll(products);
      _currentPage++;
    });
  }
}
```

### SQLite Indexes

```sql
-- Indexes critiques pour performance
CREATE INDEX idx_products_household_id ON products(household_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_budgets_household_month_year ON budgets(household_id, month, year);
CREATE INDEX idx_alert_states_alert_id ON alert_states(alert_id);
```

---

## Testing Strategy

### Unit Tests
- Services : BudgetService, AlertService, PriceService (≥80% coverage)
- Repositories : CRUD operations
- Models : toMap/fromMap, copyWith

### Widget Tests
- DashboardScreen, AddProductScreen, BudgetScreen, SettingsScreen
- QuickActionButton, OnboardingFlow

### Integration Tests
- Flux principal : Onboarding → Add Product → View Inventory → Budget
- Persistence : données survivent redémarrage

---

## Deployment (V1)

### Build Commands

```bash
# Android Release
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# iOS Release
flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
```

### Store Checklist
- ✅ Privacy Policy URL
- ✅ Pas de crash sur flux principaux
- ✅ Toutes permissions justifiées
- ✅ Pas de boutons morts
- ✅ Target SDK ≥ API 33 (Android)

---

**Notes** :
- Ce document est aligné avec AI_RULES.md et requirements.md.
- Prioriser V1, ignorer V2/V3 sauf mention explicite.
- Architecture évolutive : V1 offline → V2 premium → V3 cloud.
