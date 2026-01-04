# Design Document

## Overview

This design document outlines the architecture and implementation strategy for transforming NgonNest's budget management system from a static, disconnected feature into a dynamic, real-time, and intelligent system. The design addresses five critical gaps:

1. **Dynamic budgets**: Percentage-based allocation tied to household total budget
2. **Real notifications**: System-level alerts replacing console logs
3. **Auto-refresh**: Observer pattern for real-time UI updates
4. **Sync integration**: Complete cloud synchronization for budget operations
5. **Migration system**: Seamless upgrade path for existing users

The implementation follows Flutter best practices, maintains offline-first principles, and ensures backward compatibility.

## Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  BudgetScreen (Observer)                                        │
│  ├─ Listens to BudgetService changes                           │
│  ├─ Auto-refreshes on budget updates                           │
│  └─ Shows loading/error states                                 │
│                                                                  │
│  SettingsScreen                                                 │
│  └─ Budget management section                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  BudgetService (ChangeNotifier) ← NEW: Extends ChangeNotifier  │
│  ├─ Dynamic budget calculations                                │
│  ├─ Percentage-based allocation                                │
│  ├─ Real-time spending updates                                 │
│  ├─ Observer pattern implementation                            │
│  └─ Notification triggers                                      │
│                                                                  │
│  BudgetAllocationRules ← NEW                                   │
│  ├─ Household profile analysis                                 │
│  ├─ Multiplier calculations                                    │
│  └─ Recommended budget generation                              │
│                                                                  │
│  MigrationService ← NEW                                        │
│  ├─ Schema version management                                  │
│  ├─ Data migration execution                                   │
│  └─ Rollback handling                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Integration Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  NotificationService                                            │
│  └─ showBudgetAlert() ← ENHANCED                               │
│                                                                  │
│  SyncService                                                    │
│  └─ enqueueOperation() ← INTEGRATED                            │
│                                                                  │
│  AnalyticsService                                               │
│  └─ Budget event tracking ← ENHANCED                           │
│                                                                  │
│  InventoryRepository                                            │
│  └─ Triggers budget updates ← NEW INTEGRATION                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
├─────────────────────────────────────────────────────────────────┤
│  DatabaseService                                                │
│  ├─ budget_categories table (ENHANCED with percentage column)  │
│  ├─ foyer table (budgetMensuelEstime)                          │
│  └─ sync_outbox table (budget operations)                      │
│                                                                  │
│  BudgetCategory Model ← ENHANCED                               │
│  └─ Added percentage field                                     │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
User Action (Add/Edit Inventory Item)
           ↓
InventoryRepository.create/update()
           ↓
    [Local DB Update]
           ↓
SyncService.enqueueOperation('objet')
           ↓
BudgetService.checkBudgetAlertsAfterPurchase()
           ↓
    [Calculate spending]
           ↓
BudgetService.updateBudgetCategory()
           ↓
    [Update DB]
           ↓
SyncService.enqueueOperation('budget_categories')
           ↓
    [Check thresholds]
           ↓
IF over threshold → NotificationService.showBudgetAlert()
           ↓
BudgetService.notifyListeners()
           ↓
BudgetScreen auto-refreshes (if mounted)
```

## Components and Interfaces

### 1. Enhanced BudgetCategory Model

```dart
class BudgetCategory {
  final int? id;
  final String name;
  final double limit;
  final double spent;
  final String month;
  final double percentage; // NEW: Percentage of total budget (0.0 to 1.0)
  final DateTime createdAt;
  final DateTime updatedAt;

  // Existing getters remain unchanged
  double get spendingPercentage => limit > 0 ? (spent / limit) : 0.0;
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => spendingPercentage >= 0.8;
  double get remainingBudget => limit - spent;

  // NEW: Alert level getter
  BudgetAlertLevel get alertLevel {
    if (spendingPercentage >= 1.2) return BudgetAlertLevel.critical;
    if (spendingPercentage >= 1.0) return BudgetAlertLevel.alert;
    if (spendingPercentage >= 0.8) return BudgetAlertLevel.warning;
    return BudgetAlertLevel.normal;
  }
}

enum BudgetAlertLevel { normal, warning, alert, critical }
```

**Database Schema Changes:**
```sql
-- Migration V12: Add percentage column
ALTER TABLE budget_categories ADD COLUMN percentage REAL DEFAULT 0.25;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_budget_categories_month 
  ON budget_categories(month);
CREATE INDEX IF NOT EXISTS idx_budget_categories_name_month 
  ON budget_categories(name, month);
```

### 2. BudgetService as ChangeNotifier

```dart
class BudgetService extends ChangeNotifier {
  // Existing fields...
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  final NotificationService _notificationService = NotificationService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // NEW: Debounce timer for rapid updates
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // MODIFIED: All mutation methods now call notifyListeners()
  Future<int> createBudgetCategory(BudgetCategory category) async {
    final db = await _databaseService.database;
    final id = await db.insert('budget_categories', category.toMap());
    
    // Enqueue for sync
    await _syncService.enqueueOperation(
      operationType: 'CREATE',
      entityType: 'budget_categories',
      entityId: id,
      payload: category.toMap(),
    );
    
    // Track analytics
    await _analyticsService.logEvent('budget_category_added', 
      parameters: {'category_name': category.name});
    
    // Notify observers
    _notifyListenersDebounced();
    
    return id;
  }

  Future<void> updateBudgetCategory(BudgetCategory category) async {
    final db = await _databaseService.database;
    await db.update(
      'budget_categories',
      category.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    
    // Enqueue for sync
    await _syncService.enqueueOperation(
      operationType: 'UPDATE',
      entityType: 'budget_categories',
      entityId: category.id!,
      payload: category.toMap(),
    );
    
    // Notify observers
    _notifyListenersDebounced();
  }

  // NEW: Debounced notification to prevent excessive updates
  void _notifyListenersDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      notifyListeners();
    });
  }

  // NEW: Recalculate all category budgets based on new total
  Future<void> recalculateCategoryBudgets(int foyerId, double newTotalBudget) async {
    final categories = await getBudgetCategories();
    
    for (final category in categories) {
      final newLimit = newTotalBudget * category.percentage;
      final updated = category.copyWith(
        limit: newLimit,
        updatedAt: DateTime.now(),
      );
      await updateBudgetCategory(updated);
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### 3. BudgetAllocationRules Engine

```dart
class BudgetAllocationRules {
  // Default percentage allocations
  static const Map<String, double> defaultPercentages = {
    'Hygiène': 0.33,    // 33%
    'Nettoyage': 0.22,  // 22%
    'Cuisine': 0.28,    // 28%
    'Divers': 0.17,     // 17%
  };

  // Fallback base prices (in euros) when PriceService unavailable
  static const Map<String, double> fallbackBasePrices = {
    'Hygiène': 8.0,
    'Nettoyage': 8.0,
    'Cuisine': 8.33,
    'Divers': 7.5,
  };

  /// Calculate recommended budget allocations based on household profile
  static Future<Map<String, BudgetAllocation>> calculateRecommendedBudgets({
    required Foyer foyer,
    required PriceService priceService,
  }) async {
    final allocations = <String, BudgetAllocation>{};
    
    // Get household multipliers
    final personMultiplier = _calculatePersonMultiplier(foyer.nbPersonnes);
    final roomMultiplier = _calculateRoomMultiplier(foyer.nbPieces);
    final housingMultiplier = _calculateHousingMultiplier(foyer.typeLogement);
    final totalMultiplier = personMultiplier * roomMultiplier * housingMultiplier;

    // Calculate for each category
    for (final entry in defaultPercentages.entries) {
      final categoryName = entry.key;
      final percentage = entry.value;
      
      // Get average price from PriceService or use fallback
      final avgPrice = await priceService.getAverageCategoryPrice(categoryName)
        .catchError((_) => fallbackBasePrices[categoryName] ?? 8.0);
      
      // Calculate recommended amount based on category
      double recommendedAmount;
      switch (categoryName) {
        case 'Hygiène':
          recommendedAmount = (avgPrice * 15 * personMultiplier).clamp(80.0, 300.0);
          break;
        case 'Nettoyage':
          recommendedAmount = (avgPrice * 10 * roomMultiplier).clamp(60.0, 200.0);
          break;
        case 'Cuisine':
          recommendedAmount = (avgPrice * 12 * personMultiplier).clamp(70.0, 250.0);
          break;
        case 'Divers':
          recommendedAmount = (avgPrice * 8 * totalMultiplier).clamp(40.0, 150.0);
          break;
        default:
          recommendedAmount = avgPrice * 10;
      }
      
      allocations[categoryName] = BudgetAllocation(
        categoryName: categoryName,
        percentage: percentage,
        recommendedAmount: recommendedAmount,
        basePrice: avgPrice,
      );
    }
    
    return allocations;
  }

  /// Calculate multiplier based on number of people
  static double _calculatePersonMultiplier(int nbPersonnes) {
    return 1.0 + (nbPersonnes - 1) * 0.3; // +30% per additional person
  }

  /// Calculate multiplier based on number of rooms
  static double _calculateRoomMultiplier(int nbPieces) {
    return 1.0 + (nbPieces - 1) * 0.15; // +15% per additional room
  }

  /// Calculate multiplier based on housing type
  static double _calculateHousingMultiplier(String typeLogement) {
    return typeLogement.toLowerCase() == 'maison' ? 1.2 : 1.0; // +20% for house
  }

  /// Initialize budgets using total budget and percentages
  static Map<String, double> calculateFromTotal(double totalBudget) {
    return defaultPercentages.map(
      (category, percentage) => MapEntry(category, totalBudget * percentage),
    );
  }
}

class BudgetAllocation {
  final String categoryName;
  final double percentage;
  final double recommendedAmount;
  final double basePrice;

  BudgetAllocation({
    required this.categoryName,
    required this.percentage,
    required this.recommendedAmount,
    required this.basePrice,
  });
}
```

### 4. Enhanced NotificationService Integration

```dart
// Extension to NotificationService
extension BudgetNotifications on NotificationService {
  /// Show budget alert with appropriate severity
  static Future<void> showBudgetAlert({
    required BudgetCategory category,
    required AnalyticsService analytics,
  }) async {
    final percentage = (category.spendingPercentage * 100).round();
    final remaining = category.remainingBudget;
    
    String title;
    String body;
    Color color;
    
    switch (category.alertLevel) {
      case BudgetAlertLevel.warning:
        title = '⚠️ Budget ${category.name} à 80%';
        body = 'Il vous reste ${remaining.toStringAsFixed(2)}€ pour ce mois';
        color = const Color(0xFFFFA500); // Orange
        break;
      case BudgetAlertLevel.alert:
        title = '🚨 Budget ${category.name} dépassé';
        body = 'Vous avez dépensé ${category.spent.toStringAsFixed(2)}€ sur ${category.limit.toStringAsFixed(2)}€';
        color = const Color(0xFFFF4444); // Red
        break;
      case BudgetAlertLevel.critical:
        title = '⛔ Budget ${category.name} largement dépassé';
        body = 'Attention à vos dépenses - Dépassement de $percentage%';
        color = const Color(0xFFCC0000); // Dark red
        break;
      default:
        return; // No notification for normal level
    }
    
    // Show system notification
    await NotificationService.showBudgetAlert(
      id: category.id ?? DateTime.now().millisecondsSinceEpoch,
      categoryName: category.name,
      spentAmount: category.spent,
      limitAmount: category.limit,
      percentage: percentage,
    );
    
    // Track analytics
    await analytics.logEvent('budget_alert_triggered', parameters: {
      'category': category.name,
      'percentage': percentage,
      'alert_level': category.alertLevel.toString(),
      'spent': category.spent,
      'limit': category.limit,
    });
  }
}
```

### 5. MigrationService

```dart
class MigrationService {
  static const int currentSchemaVersion = 12; // V12 adds percentage column
  
  /// Execute all pending migrations
  static Future<void> executeMigrations(Database db) async {
    final currentVersion = await _getCurrentVersion(db);
    
    if (currentVersion >= currentSchemaVersion) {
      debugPrint('[Migration] Already at latest version $currentSchemaVersion');
      return;
    }
    
    debugPrint('[Migration] Migrating from v$currentVersion to v$currentSchemaVersion');
    
    try {
      // Execute migrations sequentially
      for (int version = currentVersion + 1; version <= currentSchemaVersion; version++) {
        await _executeMigration(db, version);
      }
      
      // Track successful migration
      await AnalyticsService().logEvent('budget_migration_completed', parameters: {
        'from_version': currentVersion,
        'to_version': currentSchemaVersion,
      });
      
      debugPrint('[Migration] Successfully migrated to v$currentSchemaVersion');
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'MigrationService',
        operation: 'executeMigrations',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.critical,
      );
      
      // Attempt rollback
      await _rollbackMigration(db, currentVersion);
      rethrow;
    }
  }
  
  /// Execute specific migration version
  static Future<void> _executeMigration(Database db, int version) async {
    switch (version) {
      case 12:
        await _migrateToV12(db);
        break;
      // Add future migrations here
    }
  }
  
  /// Migration V12: Add percentage column and calculate from existing data
  static Future<void> _migrateToV12(Database db) async {
    debugPrint('[Migration V12] Adding percentage column to budget_categories');
    
    await db.transaction((txn) async {
      // Add percentage column
      await txn.execute(
        'ALTER TABLE budget_categories ADD COLUMN percentage REAL DEFAULT 0.25'
      );
      
      // Get all existing categories
      final categories = await txn.query('budget_categories');
      
      if (categories.isEmpty) {
        debugPrint('[Migration V12] No existing categories to migrate');
        return;
      }
      
      // Group by month to calculate percentages
      final Map<String, List<Map<String, dynamic>>> byMonth = {};
      for (final cat in categories) {
        final month = cat['month'] as String;
        byMonth.putIfAbsent(month, () => []).add(cat);
      }
      
      // Calculate and update percentages for each month
      for (final entry in byMonth.entries) {
        final monthCategories = entry.value;
        final totalLimit = monthCategories.fold<double>(
          0.0,
          (sum, cat) => sum + (cat['limit_amount'] as double),
        );
        
        if (totalLimit == 0) continue;
        
        for (final cat in monthCategories) {
          final limit = cat['limit_amount'] as double;
          final percentage = limit / totalLimit;
          
          await txn.update(
            'budget_categories',
            {'percentage': percentage},
            where: 'id = ?',
            whereArgs: [cat['id']],
          );
        }
      }
      
      // Update foyer budgetMensuelEstime if not set
      final foyers = await txn.query('foyer');
      for (final foyer in foyers) {
        if (foyer['budget_mensuel_estime'] == null) {
          // Calculate from current month's categories
          final currentMonth = BudgetService.getCurrentMonth();
          final foyerCategories = categories.where(
            (cat) => cat['month'] == currentMonth
          );
          
          if (foyerCategories.isNotEmpty) {
            final totalBudget = foyerCategories.fold<double>(
              0.0,
              (sum, cat) => sum + (cat['limit_amount'] as double),
            );
            
            await txn.update(
              'foyer',
              {'budget_mensuel_estime': totalBudget},
              where: 'id = ?',
              whereArgs: [foyer['id']],
            );
          }
        }
      }
    });
    
    debugPrint('[Migration V12] ✅ Successfully migrated to V12');
  }
  
  static Future<int> _getCurrentVersion(Database db) async {
    return await db.getVersion();
  }
  
  static Future<void> _rollbackMigration(Database db, int targetVersion) async {
    debugPrint('[Migration] Rolling back to version $targetVersion');
    // Implement rollback logic if needed
    // For now, we'll just log the error and let the app continue
  }
}
```

### 6. InventoryRepository Integration

```dart
// Add to InventoryRepository
class InventoryRepository {
  final BudgetService _budgetService = BudgetService();
  
  Future<int> create(Objet objet) async {
    final db = await _databaseService.database;
    
    // Insert object
    final id = await db.insert('objet', objet.toMap());
    
    // Enqueue for sync
    await _syncService.enqueueOperation(
      operationType: 'CREATE',
      entityType: 'objet',
      entityId: id,
      payload: objet.toMap(),
    );
    
    // NEW: Trigger budget update
    if (objet.prixUnitaire != null && objet.prixUnitaire! > 0) {
      await _budgetService.checkBudgetAlertsAfterPurchase(
        objet.idFoyer,
        objet.categorie,
      );
    }
    
    return id;
  }
  
  Future<void> update(int id, Map<String, dynamic> updates) async {
    final db = await _databaseService.database;
    
    // Get original object to check if price changed
    final original = await getById(id);
    
    // Update object
    await db.update('objet', updates, where: 'id = ?', whereArgs: [id]);
    
    // Enqueue for sync
    await _syncService.enqueueOperation(
      operationType: 'UPDATE',
      entityType: 'objet',
      entityId: id,
      payload: updates,
    );
    
    // NEW: Trigger budget update if price changed
    final newPrice = updates['prix_unitaire'] as double?;
    if (newPrice != null && newPrice != original?.prixUnitaire) {
      await _budgetService.checkBudgetAlertsAfterPurchase(
        original!.idFoyer,
        original.categorie,
      );
    }
  }
}
```

## Data Models

### Enhanced BudgetCategory Schema

```sql
CREATE TABLE budget_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  limit_amount REAL NOT NULL,
  spent_amount REAL NOT NULL DEFAULT 0,
  percentage REAL NOT NULL DEFAULT 0.25, -- NEW: Percentage of total budget
  month TEXT NOT NULL, -- Format YYYY-MM
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(name, month)
);

-- Indexes for performance
CREATE INDEX idx_budget_categories_month ON budget_categories(month);
CREATE INDEX idx_budget_categories_name_month ON budget_categories(name, month);
```

### Foyer Schema (Existing)

```sql
CREATE TABLE foyer (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nb_personnes INTEGER NOT NULL,
  nb_pieces INTEGER NOT NULL DEFAULT 1,
  type_logement TEXT NOT NULL,
  langue TEXT NOT NULL,
  budget_mensuel_estime REAL -- Used for dynamic budget calculations
);
```

## Error Handling

### Error Handling Strategy

1. **Database Errors**: Wrap all DB operations in try-catch, log with ErrorLoggerService, return safe defaults
2. **Notification Failures**: Fall back to in-app banners if system notifications fail
3. **Sync Failures**: Queue operations locally, retry with exponential backoff
4. **Migration Failures**: Rollback to previous version, log error, allow app to continue
5. **Calculation Errors**: Use fallback values, log warning, continue operation

### Error Recovery Flow

```dart
try {
  // Attempt operation
  await budgetService.updateBudgetCategory(category);
} catch (e, stackTrace) {
  // Log error
  await ErrorLoggerService.logError(
    component: 'BudgetService',
    operation: 'updateBudgetCategory',
    error: e,
    stackTrace: stackTrace,
    severity: ErrorSeverity.high,
  );
  
  // Show user-friendly message
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la mise à jour du budget'),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () => _retryOperation(),
        ),
      ),
    );
  }
  
  // Return safe default or rethrow based on severity
  return category; // Return unchanged category
}
```

## Testing Strategy

### Unit Tests

1. **BudgetAllocationRules**
   - Test multiplier calculations with various household profiles
   - Test percentage-based budget calculations
   - Test fallback values when PriceService unavailable
   - Test clamping logic for min/max amounts

2. **BudgetService**
   - Test ChangeNotifier behavior (listeners notified correctly)
   - Test debouncing logic (multiple rapid updates → single notification)
   - Test recalculateCategoryBudgets with various scenarios
   - Test sync integration (operations enqueued correctly)

3. **MigrationService**
   - Test V12 migration with existing data
   - Test percentage calculation from existing limits
   - Test rollback on migration failure
   - Test migration with empty database

### Integration Tests

1. **End-to-End Budget Flow**
   - Create inventory item → budget updates → notification shown → UI refreshes
   - Update total budget → all categories recalculated → UI reflects changes
   - Delete category → sync enqueued → UI updates

2. **Observer Pattern**
   - BudgetScreen mounts → registers listener
   - Budget updated → screen refreshes automatically
   - Screen disposed → listener unregistered (no memory leak)

3. **Migration Flow**
   - Install app with old schema → migration runs → data preserved → new features work

### Widget Tests

1. **BudgetScreen**
   - Test loading state display
   - Test error state with retry button
   - Test category cards with different alert levels
   - Test pull-to-refresh functionality

2. **Budget Settings UI**
   - Test total budget edit dialog
   - Test validation (min/max values)
   - Test success/error messages

## Performance Considerations

### Optimization Strategies

1. **Debouncing**: Limit UI updates to max 1 per 500ms during rapid inventory changes
2. **Indexing**: Database indexes on month and (name, month) for fast queries
3. **Lazy Loading**: Load budget data only when BudgetScreen is visible
4. **Caching**: Cache foyer data in FoyerProvider to avoid repeated DB queries
5. **Batch Operations**: Group multiple budget updates in a single transaction

### Performance Targets

- BudgetScreen initial load: < 800ms
- Budget recalculation: < 200ms
- Notification trigger: < 100ms
- Migration execution: < 2 seconds
- Memory usage: < 50MB for budget operations
- O Complexity: Data structure complexity < O(n^2)

## Security Considerations

1. **Data Validation**: Validate all budget amounts (positive, reasonable ranges)
2. **SQL Injection**: Use parameterized queries for all DB operations
3. **Sync Security**: Ensure sync operations include foyer_id for multi-tenant isolation
4. **Permission Checks**: Verify notification permissions before showing alerts
5. **Error Messages**: Don't expose sensitive data in error messages

## Deployment Strategy

### Phased Rollout

**Phase 1: Core Infrastructure (Days 1-2)**
- Implement BudgetAllocationRules
- Add percentage column to BudgetCategory model
- Implement MigrationService V12
- Add unit tests

**Phase 2: Observer Pattern (Day 3)**
- Convert BudgetService to ChangeNotifier
- Implement debouncing logic
- Integrate with InventoryRepository
- Add integration tests

**Phase 3: Notifications & Sync (Day 4)**
- Implement real notification triggers
- Integrate SyncService for all budget operations
- Add analytics tracking
- Test notification flow

**Phase 4: UI & Settings (Day 5)**
- Enhance BudgetScreen with loading/error states
- Add budget management to SettingsScreen
- Implement visual indicators for alert levels
- Widget tests

**Phase 5: Testing & Polish (Day 6)**
- End-to-end integration tests
- Performance profiling and optimization
- Error handling verification
- Documentation updates

### Rollback Plan

If critical issues are discovered:
1. Disable new features via feature flag
2. Revert to previous schema version
3. Restore from backup if data corruption occurs
4. Deploy hotfix with fixes

## Monitoring and Analytics

### Key Metrics to Track

1. **Migration Success Rate**: % of users successfully migrated to V12
2. **Budget Alert Frequency**: Number of alerts per user per month
3. **Budget Adjustment Rate**: How often users modify their total budget
4. **Notification Engagement**: % of users who interact with budget alerts
5. **Error Rate**: Budget operation failures per 1000 operations
6. **Performance**: P95 latency for budget calculations

### Analytics Events

```dart
// Track all budget-related events
'budget_category_added'
'budget_category_edited'
'budget_category_deleted'
'budget_alert_triggered' // with alert_level
'budget_total_updated'
'budget_migration_completed'
'budget_screen_viewed'
'budget_savings_tips_clicked'
'onboarding_completed_with_budgets'
```

## Future Enhancements

1. **Budget Forecasting**: Predict end-of-month spending based on current trends
2. **Category Recommendations**: ML-based suggestions for optimal allocations
3. **Budget Sharing**: Share budget templates with other households
4. **Export/Import**: CSV export for external analysis
5. **Budget Goals**: Set savings goals and track progress
6. **Multi-Currency**: Support for multiple currencies beyond EUR
