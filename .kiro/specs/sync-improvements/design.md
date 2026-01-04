# Design Document

## Overview

This design document outlines the architecture and implementation strategy for transforming NgonNest's synchronization system from a basic unidirectional sync into a complete, bidirectional, user-friendly cloud synchronization experience with authentication. The design addresses seven critical gaps:

1. **Onboarding authentication**: Offer cloud sync during user onboarding
2. **Cloud data import**: Check for and import existing cloud data when authenticating
3. **Settings auth flow**: Complete authentication flow when enabling sync from settings
4. **Bidirectional sync**: Implement cloud→local sync with real-time listeners
5. **Conflict resolution**: Intelligent merging when both local and cloud data exist
6. **Supabase migrations**: Developer tooling to keep cloud schema in sync
7. **Automatic background sync**: Trigger sync on reconnection and app foreground

The implementation follows Flutter best practices, maintains the offline-first principle, and ensures data security.

## Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  OnboardingScreen                                               │
│  └─ Offers cloud sync after profile creation                   │
│                                                                  │
│  AuthenticationScreen                                           │
│  ├─ Email/password authentication                              │
│  ├─ OAuth (Google, Apple)                                      │
│  └─ Sign up / Sign in modes                                    │
│                                                                  │
│  SettingsScreen                                                 │
│  ├─ Sync toggle with auth check                               │
│  └─ Sync status display                                        │
│                                                                  │
│  CloudImportDialog                                              │
│  └─ Import/Merge/Skip options                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  AuthService (ChangeNotifier) ← NEW                            │
│  ├─ Session management                                         │
│  ├─ Email/OAuth authentication                                 │
│  ├─ Token refresh                                              │
│  └─ Sign out                                                   │
│                                                                  │
│  CloudImportService ← NEW                                      │
│  ├─ Check cloud data existence                                 │
│  ├─ Download all entities                                      │
│  ├─ Import to local database                                   │
│  └─ Merge with local data                                      │
│                                                                  │
│  BidirectionalSyncService (ChangeNotifier) ← NEW               │
│  ├─ Real-time listeners setup                                  │
│  ├─ Cloud→local sync                                           │
│  ├─ Change detection                                           │
│  └─ Conflict resolution trigger                                │
│                                                                  │
│  ConflictResolver ← NEW                                        │
│  ├─ Timestamp comparison                                       │
│  ├─ Strategy selection (lastModifiedWins, localWins, etc.)    │
│  └─ Entity-specific merge logic                               │
│                                                                  │
│  SyncService (ENHANCED)                                        │
│  ├─ Existing local→cloud sync                                  │
│  ├─ Background sync trigger                                    │
│  └─ Integration with bidirectional sync                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Integration Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  SupabaseApiService (ENHANCED)                                  │
│  ├─ Existing sync operations                                   │
│  ├─ getLatestChanges() ← ENHANCED                             │
│  ├─ getUserHouseholds() ← NEW                                  │
│  └─ Real-time subscriptions ← NEW                              │
│                                                                  │
│  ConnectivityService                                            │
│  └─ Triggers background sync on reconnection ← ENHANCED        │
│                                                                  │
│  AnalyticsService                                               │
│  └─ Sync and auth event tracking ← ENHANCED                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
├─────────────────────────────────────────────────────────────────┤
│  DatabaseService (Local SQLite)                                 │
│  ├─ Existing tables (foyer, objet, budget_categories, etc.)   │
│  ├─ sync_outbox (existing)                                     │
│  └─ auth_sessions ← NEW                                        │
│                                                                  │
│  Supabase (Cloud PostgreSQL)                                    │
│  ├─ households, products, budget_categories, purchases         │
│  ├─ profiles (auth.users linked)                              │
│  └─ schema_versions ← NEW                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagrams

#### Onboarding with Cloud Sync Flow

```
User completes profile
         ↓
OnboardingScreen shows "Sync cloud?" dialog
         ↓
    [User accepts]
         ↓
Navigate to AuthenticationScreen
         ↓
User authenticates (email/OAuth)
         ↓
AuthService.signIn()
         ↓
    [Success]
         ↓
CloudImportService.checkCloudData()
         ↓
Query Supabase for user's households
         ↓
    [Cloud data exists]
         ↓
Show CloudImportDialog
         ↓
User selects "Importer"
         ↓
CloudImportService.importAllData()
         ↓
Download: households → products → budgets → purchases
         ↓
Save to local SQLite
         ↓
SyncService.enableSync(userConsent: true)
         ↓
BidirectionalSyncService.enableBidirectionalSync()
         ↓
Navigate to Dashboard
```

#### Bidirectional Sync Flow

```
BidirectionalSyncService.enableBidirectionalSync()
         ↓
Set up Supabase real-time listeners
         ↓
    [Cloud change detected]
         ↓
Receive change notification
         ↓
Fetch changed entity from Supabase
         ↓
Query local database for same entity
         ↓
    [Local version exists]
         ↓
ConflictResolver.resolveConflict(local, cloud)
         ↓
Compare updated_at timestamps
         ↓
    [Cloud is newer]
         ↓
Apply cloud version to local DB
         ↓
Skip sync_outbox enqueue (avoid loop)
         ↓
Notify UI listeners
```

#### Settings Sync Enable Flow

```
User toggles "Sync" ON in settings
         ↓
Check AuthService.isAuthenticated
         ↓
    [Not authenticated]
         ↓
Navigate to AuthenticationScreen
         ↓
User authenticates
         ↓
    [Success]
         ↓
CloudImportService.checkCloudData()
         ↓
    [Cloud data exists]
         ↓
Show import options dialog
         ↓
User selects "Conserver local"
         ↓
SyncService.enableSync(userConsent: true)
         ↓
Trigger initial sync (upload local data)
         ↓
BidirectionalSyncService.enableBidirectionalSync()
         ↓
Show success message
```

## Components and Interfaces

### 1. AuthService

```dart
class AuthService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  User? _currentUser;
  
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  
  /// Initialize and check for existing session
  Future<void> initialize() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      _isAuthenticated = true;
      _currentUser = session.user;
      notifyListeners();
    }
    
    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _isAuthenticated = true;
        _currentUser = data.session?.user;
      } else if (event == AuthChangeEvent.signedOut) {
        _isAuthenticated = false;
        _currentUser = null;
      }
      notifyListeners();
    });
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.session != null) {
      _isAuthenticated = true;
      _currentUser = response.user;
      await _storeSession(response.session!);
      notifyListeners();
    }
    
    return response;
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    
    if (response.session != null) {
      _isAuthenticated = true;
      _currentUser = response.user;
      await _storeSession(response.session!);
      notifyListeners();
    }
    
    return response;
  }
  
  /// Sign in with OAuth provider
  Future<bool> signInWithOAuth(Provider provider) async {
    final result = await _client.auth.signInWithOAuth(provider);
    return result;
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    await _secureStorage.deleteAll();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
  
  /// Store session securely
  Future<void> _storeSession(Session session) async {
    await _secureStorage.write(
      key: 'access_token',
      value: session.accessToken,
    );
    await _secureStorage.write(
      key: 'refresh_token',
      value: session.refreshToken,
    );
  }
}
```

### 2. CloudImportService

```dart
class CloudImportService {
  final SupabaseClient _client = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Check if cloud data exists for the current user
  Future<bool> checkCloudData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      
      final response = await _client
        .from('households')
        .select('id')
        .eq('user_id', userId)
        .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      ConsoleLogger.error('CloudImportService', 'checkCloudData', e);
      return false;
    }
  }
  
  /// Import all data from cloud to local
  Future<ImportResult> importAllData() async {
    final result = ImportResult();
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // 1. Import households
      final households = await _importHouseholds(userId);
      result.householdsImported = households.length;
      
      // 2. Import products for each household
      for (final household in households) {
        final products = await _importProducts(household['id']);
        result.productsImported += products.length;
      }
      
      // 3. Import budget categories
      for (final household in households) {
        final budgets = await _importBudgetCategories(household['id']);
        result.budgetsImported += budgets.length;
      }
      
      // 4. Import purchases
      final purchases = await _importPurchases();
      result.purchasesImported = purchases.length;
      
      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_sync_time',
        DateTime.now().toIso8601String(),
      );
      
      // Log analytics
      await _analytics.logEvent('cloud_data_imported', parameters: {
        'households': result.householdsImported,
        'products': result.productsImported,
        'budgets': result.budgetsImported,
        'purchases': result.purchasesImported,
      });
      
      result.success = true;
    } catch (e, stackTrace) {
      result.success = false;
      result.error = e.toString();
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: 'importAllData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
    }
    
    return result;
  }
  
  /// Import households
  Future<List<Map<String, dynamic>>> _importHouseholds(String userId) async {
    final response = await _client
      .from('households')
      .select()
      .eq('user_id', userId);
    
    final db = await _databaseService.database;
    
    for (final household in response) {
      await db.insert(
        'foyer',
        {
          'id': household['id'],
          'nb_personnes': household['nb_personnes'],
          'nb_pieces': household['nb_pieces'],
          'type_logement': household['type_logement'],
          'langue': household['langue'],
          'budget_mensuel_estime': household['budget_mensuel_estime'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Import products
  Future<List<Map<String, dynamic>>> _importProducts(String householdId) async {
    final response = await _client
      .from('products')
      .select()
      .eq('household_id', householdId);
    
    final db = await _databaseService.database;
    
    for (final product in response) {
      await db.insert(
        'objet',
        _mapProductToLocal(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Import budget categories
  Future<List<Map<String, dynamic>>> _importBudgetCategories(
    String householdId,
  ) async {
    final response = await _client
      .from('budget_categories')
      .select()
      .eq('household_id', householdId);
    
    final db = await _databaseService.database;
    
    for (final budget in response) {
      await db.insert(
        'budget_categories',
        {
          'id': budget['id'],
          'name': budget['name'],
          'limit_amount': budget['limit_amount'],
          'spent_amount': budget['spent_amount'],
          'month': budget['month'],
          'created_at': budget['created_at'],
          'updated_at': budget['updated_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Import purchases
  Future<List<Map<String, dynamic>>> _importPurchases() async {
    final response = await _client.from('purchases').select();
    
    final db = await _databaseService.database;
    
    for (final purchase in response) {
      await db.insert(
        'reachat_log',
        {
          'id': purchase['id'],
          'id_objet': purchase['product_id'],
          'date': purchase['date'],
          'quantite': purchase['quantite'],
          'prix_total': purchase['prix_total'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Map cloud product schema to local schema
  Map<String, dynamic> _mapProductToLocal(Map<String, dynamic> product) {
    return {
      'id': product['id'],
      'id_foyer': product['household_id'],
      'nom': product['nom'],
      'categorie': product['categorie'],
      'type': product['type'],
      'date_achat': product['date_achat'],
      'duree_vie_prev_jours': product['duree_vie_prev_jours'],
      'date_rupture_prev': product['date_rupture_prev'],
      'quantite_initiale': product['quantite_initiale'],
      'quantite_restante': product['quantite_restante'],
      'unite': product['unite'],
      'taille_conditionnement': product['taille_conditionnement'],
      'prix_unitaire': product['prix_unitaire'],
      'methode_prevision': product['methode_prevision'],
      'frequence_achat_jours': product['frequence_achat_jours'],
      'consommation_jour': product['consommation_jour'],
      'seuil_alerte_jours': product['seuil_alerte_jours'],
      'seuil_alerte_quantite': product['seuil_alerte_quantite'],
      'commentaires': product['commentaires'],
      'room': product['room'],
      'date_modification': product['date_modification'],
    };
  }
}

class ImportResult {
  bool success = false;
  int householdsImported = 0;
  int productsImported = 0;
  int budgetsImported = 0;
  int purchasesImported = 0;
  String? error;
}
```

### 3. BidirectionalSyncService

```dart
class BidirectionalSyncService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService();
  final ConflictResolver _conflictResolver = ConflictResolver();
  
  final Map<String, RealtimeChannel> _subscriptions = {};
  bool _isEnabled = false;
  
  bool get isEnabled => _isEnabled;
  
  /// Enable bidirectional sync with real-time listeners
  Future<void> enableBidirectionalSync() async {
    if (_isEnabled) return;
    
    try {
      // Subscribe to households changes
      _subscriptions['households'] = _client
        .channel('households_changes')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'households',
          ),
          (payload, [ref]) => _handleHouseholdChange(payload),
        )
        .subscribe();
      
      // Subscribe to products changes
      _subscriptions['products'] = _client
        .channel('products_changes')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'products',
          ),
          (payload, [ref]) => _handleProductChange(payload),
        )
        .subscribe();
      
      // Subscribe to budget_categories changes
      _subscriptions['budget_categories'] = _client
        .channel('budget_categories_changes')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'budget_categories',
          ),
          (payload, [ref]) => _handleBudgetChange(payload),
        )
        .subscribe();
      
      _isEnabled = true;
      notifyListeners();
      
      ConsoleLogger.info('[BidirectionalSync] Enabled with real-time listeners');
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BidirectionalSyncService',
        operation: 'enableBidirectionalSync',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
    }
  }
  
  /// Disable bidirectional sync
  Future<void> disableBidirectionalSync() async {
    for (final subscription in _subscriptions.values) {
      await subscription.unsubscribe();
    }
    _subscriptions.clear();
    _isEnabled = false;
    notifyListeners();
    
    ConsoleLogger.info('[BidirectionalSync] Disabled');
  }
  
  /// Handle household change from cloud
  Future<void> _handleHouseholdChange(Map<String, dynamic> payload) async {
    try {
      final eventType = payload['eventType'] as String;
      final newRecord = payload['new'] as Map<String, dynamic>?;
      final oldRecord = payload['old'] as Map<String, dynamic>?;
      
      if (eventType == 'INSERT' || eventType == 'UPDATE') {
        if (newRecord != null) {
          await _applyHouseholdChange(newRecord);
        }
      } else if (eventType == 'DELETE') {
        if (oldRecord != null) {
          await _deleteLocalHousehold(oldRecord['id']);
        }
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BidirectionalSyncService',
        operation: 'handleHouseholdChange',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
    }
  }
  
  /// Apply household change to local database
  Future<void> _applyHouseholdChange(Map<String, dynamic> cloudData) async {
    final db = await _databaseService.database;
    
    // Check if local version exists
    final local = await db.query(
      'foyer',
      where: 'id = ?',
      whereArgs: [cloudData['id']],
    );
    
    if (local.isNotEmpty) {
      // Conflict resolution
      final resolved = await _conflictResolver.resolveConflict(
        entityType: 'foyer',
        localData: local.first,
        cloudData: cloudData,
      );
      
      if (resolved.useCloud) {
        await db.update(
          'foyer',
          _mapHouseholdToLocal(cloudData),
          where: 'id = ?',
          whereArgs: [cloudData['id']],
        );
      }
    } else {
      // No conflict, insert
      await db.insert(
        'foyer',
        _mapHouseholdToLocal(cloudData),
      );
    }
    
    notifyListeners();
  }
  
  // Similar handlers for products and budgets...
  
  Map<String, dynamic> _mapHouseholdToLocal(Map<String, dynamic> cloud) {
    return {
      'id': cloud['id'],
      'nb_personnes': cloud['nb_personnes'],
      'nb_pieces': cloud['nb_pieces'],
      'type_logement': cloud['type_logement'],
      'langue': cloud['langue'],
      'budget_mensuel_estime': cloud['budget_mensuel_estime'],
    };
  }
}
```

### 4. ConflictResolver

```dart
class ConflictResolver {
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Resolve conflict between local and cloud data
  Future<ConflictResolution> resolveConflict({
    required String entityType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> cloudData,
  }) async {
    try {
      // Default strategy: lastModifiedWins
      final strategy = ConflictStrategy.lastModifiedWins;
      
      final resolution = _applyStrategy(
        strategy: strategy,
        localData: localData,
        cloudData: cloudData,
        entityType: entityType,
      );
      
      // Log analytics
      await _analytics.logEvent('conflict_resolved', parameters: {
        'entity_type': entityType,
        'strategy': strategy.toString(),
        'winner': resolution.useCloud ? 'cloud' : 'local',
      });
      
      return resolution;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'ConflictResolver',
        operation: 'resolveConflict',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      
      // Default to local wins on error
      return ConflictResolution(useCloud: false, useLocal: true);
    }
  }
  
  /// Apply conflict resolution strategy
  ConflictResolution _applyStrategy({
    required ConflictStrategy strategy,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> cloudData,
    required String entityType,
  }) {
    switch (strategy) {
      case ConflictStrategy.lastModifiedWins:
        return _lastModifiedWins(localData, cloudData, entityType);
      case ConflictStrategy.localWins:
        return ConflictResolution(useCloud: false, useLocal: true);
      case ConflictStrategy.cloudWins:
        return ConflictResolution(useCloud: true, useLocal: false);
      case ConflictStrategy.merge:
        return _mergeData(localData, cloudData, entityType);
    }
  }
  
  /// Last modified wins strategy
  ConflictResolution _lastModifiedWins(
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
    String entityType,
  ) {
    // Get timestamps
    final localTimestamp = _getTimestamp(localData, entityType);
    final cloudTimestamp = _getTimestamp(cloudData, entityType);
    
    if (localTimestamp == null && cloudTimestamp == null) {
      // No timestamps, default to local
      return ConflictResolution(useCloud: false, useLocal: true);
    }
    
    if (localTimestamp == null) {
      return ConflictResolution(useCloud: true, useLocal: false);
    }
    
    if (cloudTimestamp == null) {
      return ConflictResolution(useCloud: false, useLocal: true);
    }
    
    // Compare timestamps
    if (cloudTimestamp.isAfter(localTimestamp)) {
      return ConflictResolution(useCloud: true, useLocal: false);
    } else {
      return ConflictResolution(useCloud: false, useLocal: true);
    }
  }
  
  /// Merge data strategy (entity-specific)
  ConflictResolution _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
    String entityType,
  ) {
    Map<String, dynamic> merged = {};
    
    switch (entityType) {
      case 'objet':
        // For products, preserve local quantite_restante
        merged = Map<String, dynamic>.from(cloudData);
        merged['quantite_restante'] = localData['quantite_restante'];
        break;
      
      case 'budget_categories':
        // For budgets, preserve local spent_amount
        merged = Map<String, dynamic>.from(cloudData);
        merged['spent_amount'] = localData['spent_amount'];
        break;
      
      default:
        // Default: use cloud data
        merged = Map<String, dynamic>.from(cloudData);
    }
    
    return ConflictResolution(
      useCloud: false,
      useLocal: false,
      mergedData: merged,
    );
  }
  
  /// Get timestamp from entity data
  DateTime? _getTimestamp(Map<String, dynamic> data, String entityType) {
    String? timestampField;
    
    switch (entityType) {
      case 'objet':
        timestampField = 'date_modification';
        break;
      case 'budget_categories':
        timestampField = 'updated_at';
        break;
      case 'foyer':
        // Foyer doesn't have timestamp, use null
        return null;
      default:
        timestampField = 'updated_at';
    }
    
    final timestampStr = data[timestampField] as String?;
    if (timestampStr == null) return null;
    
    return DateTime.tryParse(timestampStr);
  }
}

enum ConflictStrategy {
  lastModifiedWins,
  localWins,
  cloudWins,
  merge,
}

class ConflictResolution {
  final bool useCloud;
  final bool useLocal;
  final Map<String, dynamic>? mergedData;
  
  ConflictResolution({
    required this.useCloud,
    required this.useLocal,
    this.mergedData,
  });
}
```

### 5. Supabase Migration System

#### Migration File Structure

```
supabase/
├── migrations/
│   ├── 20241201_initial_schema.sql
│   ├── 20241202_add_percentage_to_budgets.sql
│   └── 20241203_add_room_to_products.sql
└── migration_tool.dart
```

#### Migration Tool

```dart
class SupabaseMigrationTool {
  final SupabaseClient _client = Supabase.instance.client;
  
  /// Generate a new migration file
  static Future<void> generateMigration(String name) async {
    final timestamp = DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '');
    final filename = '${timestamp}_$name.sql';
    final path = 'supabase/migrations/$filename';
    
    final template = '''
-- Migration: $name
-- Created: ${DateTime.now().toIso8601String()}

-- Add your SQL statements here

-- Example:
-- ALTER TABLE products ADD COLUMN new_field TEXT;

-- Don't forget to update the schema_versions table
INSERT INTO schema_versions (version, description, applied_at)
VALUES (${timestamp}, '$name', NOW());
''';
    
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(template);
    
    print('✅ Migration file created: $path');
  }
  
  /// Apply pending migrations
  Future<void> applyMigrations() async {
    try {
      // Get applied migrations from Supabase
      final appliedMigrations = await _getAppliedMigrations();
      
      // Get local migration files
      final localMigrations = await _getLocalMigrations();
      
      // Find pending migrations
      final pending = localMigrations.where(
        (local) => !appliedMigrations.contains(local.version),
      ).toList();
      
      if (pending.isEmpty) {
        print('✅ No pending migrations');
        return;
      }
      
      print('📦 Applying ${pending.length} migrations...');
      
      for (final migration in pending) {
        await _applyMigration(migration);
      }
      
      print('✅ All migrations applied successfully');
    } catch (e, stackTrace) {
      print('❌ Migration failed: $e');
      await ErrorLoggerService.logError(
        component: 'SupabaseMigrationTool',
        operation: 'applyMigrations',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.critical,
      );
      rethrow;
    }
  }
  
  /// Get applied migrations from Supabase
  Future<List<String>> _getAppliedMigrations() async {
    final response = await _client
      .from('schema_versions')
      .select('version')
      .order('version', ascending: true);
    
    return response.map((row) => row['version'] as String).toList();
  }
  
  /// Get local migration files
  Future<List<Migration>> _getLocalMigrations() async {
    final directory = Directory('supabase/migrations');
    if (!await directory.exists()) {
      return [];
    }
    
    final files = await directory.list().toList();
    final migrations = <Migration>[];
    
    for (final file in files) {
      if (file is File && file.path.endsWith('.sql')) {
        final filename = path.basename(file.path);
        final version = filename.split('_')[0];
        final content = await file.readAsString();
        
        migrations.add(Migration(
          version: version,
          filename: filename,
          content: content,
        ));
      }
    }
    
    migrations.sort((a, b) => a.version.compareTo(b.version));
    return migrations;
  }
  
  /// Apply a single migration
  Future<void> _applyMigration(Migration migration) async {
    print('  Applying ${migration.filename}...');
    
    try {
      // Execute SQL in a transaction
      await _client.rpc('exec_sql', params: {
        'sql': migration.content,
      });
      
      print('  ✅ ${migration.filename} applied');
    } catch (e) {
      print('  ❌ ${migration.filename} failed: $e');
      rethrow;
    }
  }
}

class Migration {
  final String version;
  final String filename;
  final String content;
  
  Migration({
    required this.version,
    required this.filename,
    required this.content,
  });
}
```

## Data Models

### Enhanced Supabase Schema

```sql
-- Add percentage column to budget_categories (matches local V12)
ALTER TABLE budget_categories ADD COLUMN IF NOT EXISTS percentage REAL DEFAULT 0.25;

-- Create schema_versions table for migration tracking
CREATE TABLE IF NOT EXISTS schema_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  applied_at TIMESTAMP DEFAULT NOW(),
  created_by TEXT DEFAULT 'system'
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_budget_categories_month 
  ON budget_categories(month);
CREATE INDEX IF NOT EXISTS idx_budget_categories_household_month 
  ON budget_categories(household_id, month);
CREATE INDEX IF NOT EXISTS idx_products_household 
  ON products(household_id);
CREATE INDEX IF NOT EXISTS idx_products_category 
  ON products(categorie);
```

### Local Auth Sessions Table

```sql
-- Migration V12: Add auth_sessions table
CREATE TABLE IF NOT EXISTS auth_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL UNIQUE,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## Error Handling

### Error Handling Strategy

1. **Authentication Errors**: Show user-friendly messages, offer retry
2. **Network Errors**: Retry with exponential backoff, fall back to offline mode
3. **Conflict Resolution Errors**: Default to localWins, log for review
4. **Import Errors**: Show partial success, allow retry for failed entities
5. **Migration Errors**: Rollback transaction, log critical error

### Error Recovery Flow

```dart
try {
  await authService.signInWithEmail(email: email, password: password);
} catch (e) {
  if (e is AuthException) {
    if (e.statusCode == '400') {
      showError('Email ou mot de passe incorrect');
    } else if (e.statusCode == '429') {
      showError('Trop de tentatives. Réessayez dans quelques minutes.');
    } else {
      showError('Erreur d\'authentification. Vérifiez votre connexion.');
    }
  } else {
    showError('Une erreur est survenue. Réessayez plus tard.');
  }
  
  await ErrorLoggerService.logError(
    component: 'AuthenticationScreen',
    operation: 'signIn',
    error: e,
    stackTrace: stackTrace,
    severity: ErrorSeverity.medium,
  );
}
```

## Testing Strategy

### Unit Tests

1. **AuthService**
   - Test sign in with valid/invalid credentials
   - Test OAuth flow
   - Test session refresh
   - Test sign out

2. **CloudImportService**
   - Test checkCloudData with/without data
   - Test importAllData with various datasets
   - Test partial import failures

3. **ConflictResolver**
   - Test lastModifiedWins with different timestamps
   - Test merge strategy for products and budgets
   - Test edge cases (null timestamps, same timestamps)

4. **BidirectionalSyncService**
   - Test real-time listener setup
   - Test change handling (INSERT, UPDATE, DELETE)
   - Test conflict resolution integration

### Integration Tests

1. **Onboarding Flow**
   - Complete onboarding → accept sync → authenticate → import data
   - Complete onboarding → decline sync → verify local-only mode

2. **Settings Sync Enable**
   - Enable sync when not authenticated → authenticate → import
   - Enable sync when authenticated → immediate sync

3. **Bidirectional Sync**
   - Make cloud change → verify local update
   - Make local change → verify cloud update
   - Simultaneous changes → verify conflict resolution

4. **Device Migration**
   - Sign in on new device → import all data → verify completeness

### Widget Tests

1. **AuthenticationScreen**
   - Test email/password validation
   - Test OAuth button interactions
   - Test loading states
   - Test error messages

2. **CloudImportDialog**
   - Test import/merge/skip options
   - Test progress indicators
   - Test success/error states

## Performance Considerations

### Optimization Strategies

1. **Pagination**: Fetch cloud data in batches of 50 records
2. **Indexing**: Add indexes on frequently queried fields
3. **Debouncing**: Debounce real-time listener events (500ms)
4. **Lazy Loading**: Load data only when needed
5. **Compression**: Use gzip for large payloads

### Performance Targets

- Authentication: < 2 seconds
- Cloud data check: < 1 second
- Import 100 products: < 5 seconds
- Conflict resolution: < 100ms per entity
- Real-time sync latency: < 2 seconds

## Security Considerations

1. **Token Storage**: Use flutter_secure_storage for auth tokens
2. **HTTPS Only**: All API calls use HTTPS
3. **Row Level Security**: Enforce RLS on all Supabase tables
4. **No Service Role Key**: Use anon key only in client
5. **Session Expiry**: Auto-refresh tokens, sign out on failure
6. **Data Isolation**: Filter all queries by user_id/household_id

## Deployment Strategy

### Phased Rollout

**Phase 1: Authentication & Import (Days 1-3)**
- Implement AuthService
- Implement CloudImportService
- Add authentication UI
- Add cloud import dialog
- Unit tests

**Phase 2: Bidirectional Sync (Days 4-6)**
- Implement BidirectionalSyncService
- Implement ConflictResolver
- Set up real-time listeners
- Integration tests

**Phase 3: Onboarding & Settings Integration (Days 7-8)**
- Add sync offer to onboarding
- Enhance settings screen
- Add sync status indicators
- Widget tests

**Phase 4: Migration Tool & Background Sync (Days 9-10)**
- Implement Supabase migration tool
- Enhance background sync triggers
- Performance optimization
- End-to-end tests

**Phase 5: Polish & Documentation (Day 11)**
- Error handling improvements
- Analytics integration
- Documentation updates
- Final testing

### Rollback Plan

If critical issues are discovered:
1. Disable bidirectional sync via feature flag
2. Revert to unidirectional sync only
3. Fix issues and redeploy
4. Re-enable bidirectional sync

## Monitoring and Analytics

### Key Metrics

1. **Authentication Success Rate**: % of successful sign-ins
2. **Import Success Rate**: % of successful data imports
3. **Conflict Resolution Rate**: Conflicts per 1000 sync operations
4. **Sync Latency**: P95 latency for bidirectional sync
5. **Error Rate**: Sync errors per 1000 operations

### Analytics Events

```dart
'auth_success' // method, duration
'auth_failed' // error_type
'sync_enabled' // source (onboarding/settings)
'cloud_data_imported' // entity_counts
'conflict_resolved' // strategy, entity_type
'bidirectional_sync_enabled'
'background_sync_completed' // duration, operation_count
'device_migration' // data_imported
```

## Future Enhancements

1. **Selective Sync**: Allow users to choose which data to sync
2. **Offline Queue Management**: UI to view and manage pending operations
3. **Multi-Device Notifications**: Notify when changes occur on other devices
4. **Sync History**: Show detailed sync history and logs
5. **Advanced Conflict UI**: Let users manually resolve conflicts
6. **Backup/Restore**: Export/import data as JSON
