# Design Document

## Overview

Ce document décrit les solutions techniques pour corriger les 10 bugs critiques identifiés dans le système de gestion budgétaire de NgonNest. L'approche privilégie des corrections minimales et ciblées pour restaurer la fonctionnalité sans refactoring majeur.

## Architecture

### Current State (Broken)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  BudgetScreen                                                    │
│  ├─ ❌ No listener registration to BudgetService                │
│  ├─ ❌ Uses local state instead of Provider                     │
│  ├─ ❌ Pull-to-refresh not connected                            │
│  └─ ❌ Error handling shows technical messages                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  BudgetService (extends ChangeNotifier)                         │
│  ├─ ❌ notifyListeners() not called consistently               │
│  ├─ ❌ Not provided as singleton via Provider                  │
│  └─ ❌ _triggerBudgetAlert() uses debugPrint()                 │
│                                                                  │
│  AnalyticsService                                               │
│  └─ ❌ Accepts boolean parameters (Firebase rejects)           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Integration Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  InventoryRepository                                            │
│  └─ ❌ Doesn't call BudgetService after create/update          │
│                                                                  │
│  NotificationService                                            │
│  └─ ❌ showBudgetAlert() not implemented                       │
│                                                                  │
│  SyncService                                                    │
│  └─ ❌ Budget operations not enqueued                          │
└─────────────────────────────────────────────────────────────────┘
```

### Target State (Fixed)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  BudgetScreen (StatefulWidget)                                  │
│  ├─ ✅ Registers listener in initState()                       │
│  ├─ ✅ Uses context.watch<BudgetService>()                     │
│  ├─ ✅ RefreshIndicator connected to _loadBudgetData()         │
│  ├─ ✅ Shows user-friendly French error messages or in the language of the user               │
│  └─ ✅ Unregisters listener in dispose()                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  BudgetService (extends ChangeNotifier)                         │
│  ├─ ✅ Calls notifyListeners() after all mutations             │
│  ├─ ✅ Provided as singleton via ChangeNotifierProvider        │
│  ├─ ✅ _triggerBudgetAlert() calls NotificationService         │
│  └─ ✅ Logs all operations via ErrorLoggerService              │
│                                                                  │
│  AnalyticsService                                               │
│  └─ ✅ Converts boolean to string before logging               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Integration Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  InventoryRepository                                            │
│  └─ ✅ Calls BudgetService.checkBudgetAlertsAfterPurchase()    │
│                                                                  │
│  NotificationService                                            │
│  └─ ✅ showBudgetAlert() implemented with flutter_local_notif  │
│                                                                  │
│  SyncService                                                    │
│  └─ ✅ Budget operations enqueued for sync                     │
└─────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. BudgetService Provider Setup

**Problem:** BudgetService extends ChangeNotifier but is not provided via Provider, so listeners can't register.

**Solution:** Add BudgetService to main.dart providers list.

```dart
// In main.dart
MultiProvider(
  providers: [
    // Existing providers...
    ChangeNotifierProvider<BudgetService>(
      create: (_) => BudgetService(),
    ),
    // Other providers...
  ],
  child: MyApp(),
)
```

### 2. BudgetScreen Listener Registration

**Problem:** BudgetScreen doesn't register as listener, so it never auto-refreshes.

**Solution:** Register listener in initState(), unregister in dispose().

```dart
class _BudgetScreenState extends State<BudgetScreen> {
  BudgetService? _budgetService;
  
  @override
  void initState() {
    super.initState();
    
    // Get BudgetService instance from Provider
    _budgetService = context.read<BudgetService>();
    
    // Register as listener
    _budgetService?.addListener(_onBudgetChanged);
    
    // Load initial data
    _loadBudgetData();
  }
  
  @override
  void dispose() {
    // Unregister listener to prevent memory leaks
    _budgetService?.removeListener(_onBudgetChanged);
    super.dispose();
  }
  
  /// Callback when BudgetService notifies changes
  void _onBudgetChanged() {
    if (mounted) {
      _loadBudgetData();
    }
  }
  
  Future<void> _loadBudgetData() async {
    // Load data from BudgetService
    final categories = await _budgetService?.getBudgetCategories() ?? [];
    // Update UI...
  }
}
```

### 3. Fix notifyListeners() Calls

**Problem:** BudgetService doesn't call notifyListeners() consistently after mutations.

**Solution:** Add notifyListeners() to all mutation methods.

```dart
// In BudgetService
Future<void> updateBudgetCategory(BudgetCategory category) async {
  // ... existing update logic ...
  
  // ✅ ADD THIS: Notify listeners after update
  notifyListeners();
}

Future<void> recalculateCategoryBudgets(String idFoyer, double newTotal) async {
  // ... existing recalculation logic ...
  
  // ✅ ADD THIS: Notify listeners after recalculation
  notifyListeners();
}

Future<void> checkBudgetAlertsAfterPurchase(String idFoyer, String category) async {
  // ... existing alert check logic ...
  
  // ✅ ADD THIS: Notify listeners after spending update
  notifyListeners();
}
```

### 4. Fix Firebase Analytics Boolean Parameters

**Problem:** Firebase Analytics rejects boolean parameters, causing errors.

**Solution:** Convert booleans to strings in AnalyticsService.

```dart
// In AnalyticsService
Future<void> logEvent(
  String eventName, {
  Map<String, Object>? parameters,
}) async {
  try {
    // ✅ ADD THIS: Convert boolean parameters to strings
    final sanitizedParams = parameters?.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value ? 'true' : 'false');
      }
      return MapEntry(key, value);
    });
    
    await _analytics?.logEvent(
      name: eventName,
      parameters: sanitizedParams,
    );
  } catch (e, stackTrace) {
    await ErrorLoggerService.logError(
      component: 'AnalyticsService',
      operation: 'logEvent',
      error: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.low,
    );
  }
}
```

**Alternative:** Fix at call site in BudgetService.

```dart
// In BudgetService.updateBudgetCategory()
await AnalyticsService().logEvent(
  'budget_category_edited',
  parameters: {
    'category_name': category.name,
    'limit_changed': limitChanged ? 'true' : 'false', // ✅ String not bool
    'old_limit': oldCategory?.limit?.toString() ?? 'null',
    'new_limit': category.limit.toString(),
  },
);
```

### 5. Implement Real Budget Notifications

**Problem:** _triggerBudgetAlert() uses debugPrint() instead of showing real notifications.

**Solution:** Implement NotificationService.showBudgetAlert() and call it after log it with the appropriate for devs.

```dart
// In NotificationService
extension BudgetNotifications on NotificationService {
  static Future<void> showBudgetAlert({
    required BudgetCategory category,
    required AnalyticsService analytics,
  }) async {
    try {
      // Determine notification content based on alert level
      String title;
      String body;
      NotificationPriority priority;
      
      switch (category.alertLevel) {
        case BudgetAlertLevel.warning:
          title = '⚠️ Budget ${category.name} à 80%';
          body = 'Il vous reste ${category.remainingBudget.toStringAsFixed(2)}€';
          priority = NotificationPriority.defaultPriority;
          break;
        case BudgetAlertLevel.alert:
          title = '🚨 Budget ${category.name} dépassé';
          body = 'Vous avez dépensé ${category.spent.toStringAsFixed(2)}€ sur ${category.limit.toStringAsFixed(2)}€';
          priority = NotificationPriority.high;
          break;
        case BudgetAlertLevel.critical:
          title = '⛔ Budget ${category.name} largement dépassé';
          body = 'Attention à vos dépenses - Dépassement de ${(category.spendingPercentage * 100).round()}%';
          priority = NotificationPriority.max;
          break;
        default:
          return; // No notification for normal level
      }
      
      // ✅ Show real system notification
      await NotificationService().showNotification(
        id: category.id ?? DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        channelId: 'budget_alerts',
        channelName: 'Alertes Budgétaires',
        priority: priority,
      );
      
      // ✅ Log for debugging (keep logs!)
      await ErrorLoggerService.logError(
        component: 'BudgetNotifications',
        operation: 'showBudgetAlert',
        error: 'Budget alert triggered',
        severity: ErrorSeverity.info,
        metadata: {
          'category': category.name,
          'alert_level': category.alertLevel.toString(),
          'spending_percentage': category.spendingPercentage,
          'spent': category.spent,
          'limit': category.limit,
        },
      );
      
      // Track analytics
      await analytics.logEvent('budget_alert_triggered', parameters: {
        'category': category.name,
        'percentage': (category.spendingPercentage * 100).round(),
        'alert_level': category.alertLevel.toString(),
        'spent': category.spent,
        'limit': category.limit,
      });
    } catch (e, stackTrace) {
      // ✅ Log notification failures
      await ErrorLoggerService.logError(
        component: 'BudgetNotifications',
        operation: 'showBudgetAlert',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.error,
        metadata: {
          'category_name': category.name,
          'context_message': 'Failed to show budget notification',
        },
      );
      
      // Don't rethrow - notification failure shouldn't block budget operations
    }
  }
}
```

```dart
// In BudgetService._triggerBudgetAlert()
Future<void> _triggerBudgetAlert(BudgetCategory category) async {
  try {
    // ✅ REPLACE debugPrint() with real notification
    await BudgetNotifications.showBudgetAlert(
      category: category,
      analytics: AnalyticsService(),
    );
  } catch (e, stackTrace) {
    await ErrorLoggerService.logError(
      component: 'BudgetService',
      operation: '_triggerBudgetAlert',
      error: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.medium,
    );
  }
}
```

### 6. Connect Inventory to Budget Updates

**Problem:** Adding/updating products doesn't trigger budget updates.

**Solution:** Call BudgetService.checkBudgetAlertsAfterPurchase() in InventoryRepository.

```dart
// In InventoryRepository
class InventoryRepository {
  final BudgetService _budgetService = BudgetService();
  
  Future<int> create(Objet objet) async {
    // ... existing create logic ...
    
    // ✅ ADD THIS: Trigger budget update after product creation
    if (objet.prixUnitaire != null && objet.prixUnitaire! > 0) {
      try {
        await _budgetService.checkBudgetAlertsAfterPurchase(
          objet.idFoyer,
          objet.categorie,
        );
      } catch (e) {
        // Log but don't block inventory operation
        await ErrorLoggerService.logError(
          component: 'InventoryRepository',
          operation: 'create',
          error: e,
          severity: ErrorSeverity.low,
          metadata: {'context': 'Budget update failed but inventory created'},
        );
      }
    }
    
    return id;
  }
  
  Future<void> update(int id, Map<String, dynamic> updates) async {
    // Get original object to check if price changed
    final original = await getById(id);
    
    // ... existing update logic ...
    
    // ✅ ADD THIS: Trigger budget update if price changed
    final newPrice = updates['prix_unitaire'] as double?;
    if (newPrice != null && newPrice != original?.prixUnitaire) {
      try {
        await _budgetService.checkBudgetAlertsAfterPurchase(
          original!.idFoyer,
          original.categorie,
        );
      } catch (e) {
        // Log but don't block inventory operation
        await ErrorLoggerService.logError(
          component: 'InventoryRepository',
          operation: 'update',
          error: e,
          severity: ErrorSeverity.low,
          metadata: {'context': 'Budget update failed but inventory updated'},
        );
      }
    }
  }
}
```

### 7. Fix BudgetScreen Data Source

**Problem:** BudgetScreen uses local state instead of Provider data.

**Solution:** Use context.watch<FoyerProvider>() for total budget.

```dart
// In BudgetScreen._loadBudgetData()
Future<void> _loadBudgetData() async {
  try {
    // Load categories from BudgetService
    final categories = await _budgetService?.getBudgetCategories() ?? [];
    
    // ✅ CHANGE THIS: Load foyer total budget from FoyerProvider
    final foyerBudget = context.read<FoyerProvider>().foyer?.budgetMensuelEstime ?? 0.0;
    
    // Calculate summary with foyer total
    final summary = {
      'totalBudget': foyerBudget, // ✅ Use foyer budget not sum of limits
      'totalSpent': categories.fold<double>(0.0, (sum, cat) => sum + cat.spent),
      'remaining': foyerBudget - categories.fold<double>(0.0, (sum, cat) => sum + cat.spent),
      'categories': categories,
    };
    
    setState(() {
      _categories = categories;
      _budgetSummary = summary;
      _isLoading = false;
    });
  } catch (e) {
    // Handle error...
  }
}
```

### 8. Implement Pull-to-Refresh

**Problem:** Pull-to-refresh not connected to data reload.

**Solution:** Wrap content in RefreshIndicator.

```dart
// In BudgetScreen.build()
Expanded(
  child: RefreshIndicator(
    onRefresh: _loadBudgetData, // ✅ Connect to data reload
    child: ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return BudgetCategoryCard(category: _categories[index]);
      },
    ),
  ),
)
```

**Apply same pattern to InventoryScreen and DashboardScreen.**

### 9. Fix Error Handling in UI

**Problem:** Error messages are technical and not localized.

**Solution:** Show user-friendly localized error messages using AppLocalizations.

```dart
// First, add error messages to l10n files:

// app_fr.arb
{
  "budgetLoadError": "Impossible de charger les données budgétaires. Vérifiez votre connexion.",
  "budgetRetry": "Réessayer",
  "budgetUpdateError": "Erreur lors de la mise à jour du budget",
  "budgetDeleteError": "Erreur lors de la suppression de la catégorie"
}

// app_en.arb
{
  "budgetLoadError": "Unable to load budget data. Check your connection.",
  "budgetRetry": "Retry",
  "budgetUpdateError": "Error updating budget",
  "budgetDeleteError": "Error deleting category"
}

// app_es.arb
{
  "budgetLoadError": "No se pueden cargar los datos del presupuesto. Verifique su conexión.",
  "budgetRetry": "Reintentar",
  "budgetUpdateError": "Error al actualizar el presupuesto",
  "budgetDeleteError": "Error al eliminar la categoría"
}
```

```dart
// In BudgetScreen
Future<void> _loadBudgetData() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  try {
    // ... load data ...
  } catch (e) {
    // ✅ CHANGE THIS: User-friendly localized error message
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = false;
      _errorMessage = l10n.budgetLoadError;
    });
    
    // Log technical error for debugging
    await ErrorLoggerService.logError(
      component: 'BudgetScreen',
      operation: '_loadBudgetData',
      error: e,
      severity: ErrorSeverity.medium,
    );
  }
}

// Show error state with retry button
if (_errorMessage != null) {
  final l10n = AppLocalizations.of(context)!;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadBudgetData,
          icon: Icon(Icons.refresh),
          label: Text(l10n.budgetRetry), // ✅ Localized button text
        ),
      ],
    ),
  );
}
```

### 10. Integrate SyncService

**Problem:** Budget operations not enqueued for sync.

**Solution:** Call SyncService.enqueueOperation() after mutations.

```dart
// In BudgetService
Future<void> createBudgetCategory(BudgetCategory category) async {
  // ... existing create logic ...
  
  // ✅ ADD THIS: Enqueue for sync
  try {
    await SyncService().enqueueOperation(
      operationType: 'CREATE',
      entityType: 'budget_categories',
      entityId: id,
      payload: category.toMap(),
    );
  } catch (e) {
    // Log but don't block local operation
    await ErrorLoggerService.logError(
      component: 'BudgetService',
      operation: 'createBudgetCategory',
      error: e,
      severity: ErrorSeverity.low,
      metadata: {'context': 'Sync enqueue failed but category created locally'},
    );
  }
  
  notifyListeners();
}

// Apply same pattern to updateBudgetCategory() and deleteBudgetCategory()
```

## Data Models

No model changes required. All fixes are in service and UI layers.

## Error Handling

### Error Handling Strategy

1. **UI Errors**: Show user-friendly French messages with retry button
2. **Service Errors**: Log with ErrorLoggerService, don't block operations
3. **Notification Errors**: Fall back to in-app SnackBar, log error
4. **Sync Errors**: Retry with exponential backoff, log failures
5. **Analytics Errors**: Log but never block app functionality

### Error Severity Levels

- **INFO**: Budget alerts triggered (for debugging)
- **LOW**: Sync enqueue failures, analytics failures
- **MEDIUM**: Budget calculation failures, notification failures
- **HIGH**: Database operation failures
- **CRITICAL**: App crashes, data corruption

## Testing Strategy

### Unit Tests

1. **BudgetService**
   - Test notifyListeners() called after mutations
   - Test checkBudgetAlertsAfterPurchase() updates spending
   - Test recalculateCategoryBudgets() maintains percentages

2. **AnalyticsService**
   - Test boolean parameters converted to strings
   - Test invalid parameters handled gracefully

3. **NotificationService**
   - Test showBudgetAlert() creates notifications
   - Test fallback to SnackBar when permissions denied

### Integration Tests

1. **Inventory → Budget Flow**
   - Add product → budget updates → notification shown → UI refreshes
   - Update product price → budget recalculates → UI reflects changes

2. **Settings → Budget Flow**
   - Update total budget → categories recalculated → UI updates

3. **Observer Pattern**
   - BudgetScreen mounts → registers listener
   - Budget updated → screen refreshes
   - Screen disposed → listener unregistered (no memory leak)

### Widget Tests

1. **BudgetScreen**
   - Test loading state displays
   - Test error state with retry button
   - Test pull-to-refresh triggers reload
   - Test listener registration/cleanup

## Performance Considerations

### Optimization Strategies

1. **Debouncing**: Limit notifyListeners() to max 1 per 500ms during rapid updates
2. **Conditional Refresh**: Only reload BudgetScreen if mounted and visible
3. **Lazy Loading**: Don't load expense history until user taps category
4. **Error Recovery**: Cache last known good data, show stale data with warning banner

### Performance Targets

- BudgetScreen refresh: < 300ms
- Notification trigger: < 100ms
- Budget recalculation: < 200ms
- Pull-to-refresh: < 500ms

## Security Considerations

1. **Data Validation**: Validate all budget amounts (positive, reasonable ranges)
2. **Permission Checks**: Verify notification permissions before showing alerts
3. **Error Messages**: Don't expose sensitive data in user-facing errors
4. **Logging**: Sanitize PII from error logs
5. **Write Rules**: Validate with me for doc before execution of the creation. Create it only md within my approbation and search something similar to update instead of creating a new one
6. **Up to date library**: Use the most recent docs adapted to version of package of dependancies used in the code for securities and follow the guidelines of Dart.

## Deployment Strategy

### Phased Rollout
**Phase 1: Core Fixes (Day 1)**
- Fix ChangeNotifier implementation
- Fix Firebase Analytics boolean parameters
- Add BudgetService to Provider
- Register BudgetScreen as listener

**Phase 2: Notifications (Day 2)**
- Implement NotificationService.showBudgetAlert()
- Replace debugPrint() with real notifications
- Add fallback to SnackBar

**Phase 3: Integration (Day 3)**
- Connect InventoryRepository to BudgetService
- Implement pull-to-refresh
- Fix BudgetScreen data source

**Phase 4: Polish (Day 4)**
- Fix error handling and messages
- Integrate SyncService
- Add comprehensive logging

**Phase 5: Testing (Day 5)**
- Unit tests for all fixes
- Integration tests for flows
- Widget tests for UI

### Rollback Plan

If critical issues discovered:
1. Revert to previous version via Git
2. Disable budget features via feature flag
3. Deploy hotfix with specific fix

## Monitoring and Analytics

### Key Metrics to Track

1. **Budget Alert Success Rate**: % of alerts successfully shown
2. **UI Refresh Rate**: How often BudgetScreen auto-refreshes
3. **Error Rate**: Budget operation failures per 1000 operations
4. **Notification Permission Rate**: % of users who grant permissions
5. **Sync Success Rate**: % of budget operations successfully synced

### Analytics Events

```dart
'budget_screen_loaded'
'budget_auto_refreshed'
'budget_alert_triggered' // with alert_level
'budget_notification_shown'
'budget_notification_failed'
'budget_sync_enqueued'
'budget_error_occurred' // with error_type
```

## Future Enhancements

1. **Smart Notifications**: Only notify during waking hours (8am-10pm)
2. **Notification Grouping**: Group multiple budget alerts into one notification
3. **Predictive Alerts**: Warn user before reaching limit based on spending trends
4. **Offline Queue**: Queue notifications to show when app reopens
5. **Custom Alert Thresholds**: Let users set custom alert percentages (not just 80/100/120%)

