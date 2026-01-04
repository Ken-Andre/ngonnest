# Design Document

## Overview

Ce document décrit les solutions techniques pour rendre NgoNest prête pour la production avec toutes les fonctionnalités critiques implémentées, à l'exception de la synchronisation cloud qui sera désactivée en production. L'approche privilégie les corrections par priorité, les tests et le perfectionnement de l'interface utilisateur.

## Architecture

### Current State (Pre-Production)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  DashboardScreen                                                 │
│  ├─ Onboarding sometimes skipped                                 │
│  ├─ Error messages sometimes technical                          │
│  ├─ Quick actions not fully implemented                         │
│  └─ Performance issues with large datasets                      │
│                                                                  │
│  AddProductScreen                                               │
│  ├─ Complex form without simplified mode                        │
│  └─ No real-time validation feedback                            │
│                                                                  │
│  BudgetScreen                                                   │
│  └─ May have sync-related UI elements                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  AuthService                                                    │
│  └─ May contain Supabase keys in code                          │
│                                                                  │
│  BudgetService                                                  │
│  └─ Missing some alert persistence logic                       │
│                                                                  │
│  AlertService                                                   │
│  └─ No persistence for alert states                            │
│                                                                  │
│  FeatureFlagService                                             │
│  └─ Not fully implemented for conditional features             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
├─────────────────────────────────────────────────────────────────┤
│  SQLite Database                                                │
│  ├─ Missing alert_states table migration                       │
│  └─ Price data may be outdated                                 │
│                                                                  │
│  Supabase Sync                                                  │
│  └─ Active in all environments                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Target State (Production Ready)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  OnboardingFlow (4 slides)                                       │
│  ├─ ✅ Welcome slide with illustration                          │
│  ├─ ✅ Inventory management explanation                         │
│  ├─ ✅ Budget tracking overview                                 │
│  └─ ✅ Smart alerts introduction                                │
│                                                                  │
│  DashboardScreen                                                 │
│  ├─ ✅ Quick actions with proper icons/labels                   │
│  ├─ ✅ Pagination for large lists                               │
│  ├─ ✅ Lazy loading for statistics                              │
│  └─ ✅ Performance optimized (loads <2s with 500+ products)     │
│                                                                  │
│  AddProductScreen                                               │
│  ├─ ✅ Simple/Advanced mode toggle                              │
│  ├─ ✅ Real-time validation with clear messages                 │
│  └─ ✅ Contextual help with "?" icons                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  AuthService                                                    │
│  ├─ ✅ Supabase keys from environment variables                │
│  └─ ✅ Code obfuscation for release builds                     │
│                                                                  │
│  BudgetService                                                  │
│  ├─ ✅ Automatic purchase sync with budget                      │
│  ├─ ✅ Graphical expense representations                        │
│  └─ ✅ Budget alerts at 90% and overrun                         │
│                                                                  │
│  AlertService                                                   │
│  ├─ ✅ SQLite alert_states table with proper migration          │
│  ├─ ✅ Persistence for read/resolved alert states               │
│  └─ ✅ Performance tested with 1000+ alerts                     │
│                                                                  │
│  FeatureFlagService                                             │
│  ├─ ✅ Manage conditional features                             │
│  ├─ ✅ Disable sync in release builds                          │
│  └─ ✅ Enable sync in dev builds                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
├─────────────────────────────────────────────────────────────────┤
│  SQLite Database                                                │
│  ├─ ✅ alert_states table with proper schema                   │
│  └─ ✅ Updated/verified price data for Cameroon markets        │
│                                                                  │
│  Supabase Sync                                                  │
│  ├─ ✅ Disabled in release builds                              │
│  └─ ✅ Active in dev builds                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Security and Configuration Management

**Problem:** API keys in source code and no build configuration separation.

**Solution:** Implement environment-based configuration and code obfuscation.

```dart
// In config/supabase_config.dart
class SupabaseConfig {
  static String get apiKey {
    // ✅ Get from environment variables
    const key = String.fromEnvironment('SUPABASE_API_KEY');
    if (key.isEmpty) {
      throw Exception('SUPABASE_API_KEY not found in environment');
    }
    return key;
  }
  
  static String get projectId {
    const id = String.fromEnvironment('SUPABASE_PROJECT_ID');
    if (id.isEmpty) {
      throw Exception('SUPABASE_PROJECT_ID not found in environment');
    }
    return id;
  }
}
```

```yaml
# In build configurations (pubspec.yaml or build files)
# ✅ Separate build configurations
dev:
  environment_variables:
    SUPABASE_API_KEY: "dev_key_here"
    SUPABASE_PROJECT_ID: "dev_project_id"
    
staging:
  environment_variables:
    SUPABASE_API_KEY: "staging_key_here"
    SUPABASE_PROJECT_ID: "staging_project_id"
    
prod:
  environment_variables:
    SUPABASE_API_KEY: ""  # Empty or secured differently
    SUPABASE_PROJECT_ID: "prod_project_id"
```

### 2. Alert Persistence System

**Problem:** Alert states (read/resolved) not persisted across sessions.

**Solution:** Create SQLite migration and implement alert state persistence.

```sql
-- In database/migrations/0012_alert_states_table.sql
CREATE TABLE IF NOT EXISTS alert_states (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  alert_id TEXT NOT NULL UNIQUE,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alert_states_alert_id ON alert_states(alert_id);
CREATE INDEX idx_alert_states_is_read ON alert_states(is_read);
CREATE INDEX idx_alert_states_is_resolved ON alert_states(is_resolved);
```

```dart
// In models/alert_state.dart
class AlertState {
  final int? id;
  final String alertId;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlertState({
    this.id,
    required this.alertId,
    this.isRead = false,
    this.isResolved = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alert_id': alertId,
      'is_read': isRead ? 1 : 0,
      'is_resolved': isResolved ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  factory AlertState.fromMap(Map<String, dynamic> map) {
    return AlertState(
      id: map['id'],
      alertId: map['alert_id'],
      isRead: map['is_read'] == 1,
      isResolved: map['is_resolved'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
```

```dart
// In repository/alert_repository.dart
class AlertRepository {
  final DatabaseService _dbService;
  
  AlertRepository(this._dbService);
  
  Future<AlertState?> getAlertState(String alertId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'alert_states',
      where: 'alert_id = ?',
      whereArgs: [alertId],
      limit: 1,
    );
    
    return result.isNotEmpty ? AlertState.fromMap(result.first) : null;
  }
  
  Future<void> saveAlertState(AlertState state) async {
    final db = await _dbService.database;
    await db.insert(
      'alert_states',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> markAlertAsRead(String alertId) async {
    final state = await getAlertState(alertId) ?? 
        AlertState(alertId: alertId, createdAt: DateTime.now(), updatedAt: DateTime.now());
    
    final updatedState = AlertState(
      id: state.id,
      alertId: state.alertId,
      isRead: true,
      isResolved: state.isResolved,
      createdAt: state.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await saveAlertState(updatedState);
  }
}
```

### 3. Price Database Validation

**Problem:** Product prices may be outdated or incorrect for Cameroon markets.

**Solution:** Audit and update price database with verified sources.

```dart
// In services/price_validation_service.dart
class PriceValidationService {
  final DatabaseService _dbService;
  
  PriceValidationService(this._dbService);
  
  Future<void> auditPrices() async {
    // ✅ Get list of common products in Cameroon markets
    final commonProducts = await _getCommonCameroonProducts();
    
    for (final product in commonProducts) {
      // ✅ Check against verified sources
      final verifiedPrice = await _getVerifiedPrice(
        product.name,
        product.category,
      );
      
      if (verifiedPrice != null && verifiedPrice != product.currentPrice) {
        // ✅ Update with verified price and source information
        await _updateProductPrice(
          product.id,
          verifiedPrice,
          'Verified from ${verifiedPrice.source} on ${verifiedPrice.date}',
        );
      }
    }
  }
  
  Future<double?> _getVerifiedPrice(String name, String category) async {
    // ✅ Implementation to fetch from verified sources
    // This could connect to price APIs, supermarket databases, etc.
    // For v1, this might be manual verification process
    return null;
  }
}
```

### 4. Disabled Cloud Sync Service

**Problem:** Cloud sync visible and accessible in production when it should be disabled.

**Solution:** Implement FeatureFlagService to control sync availability.

```dart
// In services/feature_flag_service.dart
class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();
  
  // ✅ Determine build mode
  bool get isReleaseMode {
    bool inReleaseMode = false;
    assert(() {
      inReleaseMode = false;
      return true;
    }());
    return inReleaseMode;
  }
  
  bool isFeatureEnabled(Feature feature) {
    switch (feature) {
      case Feature.cloudSync:
        // ✅ Disable sync in release builds
        return !isReleaseMode;
      case Feature.premiumFeatures:
        // ✅ Disable premium features temporarily
        return false;
      default:
        return true;
    }
  }
}

enum Feature {
  cloudSync,
  premiumFeatures,
  // Add other features as needed
}
```

```dart
// In screens/settings_screen.dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final featureService = FeatureFlagService();
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Other settings...
          
          // ✅ Conditionally show sync option
          if (featureService.isFeatureEnabled(Feature.cloudSync))
            ListTile(
              title: Text(l10n.syncSettings),
              onTap: () => _navigateToSyncSettings(context),
            )
          else
            ListTile(
              title: Text(l10n.syncSettings),
              subtitle: Text(l10n.comingSoon), // "Fonctionnalité bientôt disponible"
              enabled: false,
              trailing: Icon(Icons.info_outline),
            ),
        ],
      ),
    );
  }
}
```

### 5. Premium Features - Temporary Removal

**Problem:** Premium features visible but not ready for MVP.

**Solution:** Comment out premium code and replace with feedback option.

```dart
// In screens/dashboard_screen.dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final featureService = FeatureFlagService();
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Column(
        children: [
          // Other dashboard content...
          
          // ✅ Remove premium banner
          // if (featureService.isFeatureEnabled(Feature.premiumFeatures))
          //   PremiumBanner(),
          
          // ✅ Option: Add feedback banner instead
          if (!featureService.isFeatureEnabled(Feature.premiumFeatures))
            FeedbackBanner(), // Collect user feedback instead
        ],
      ),
    );
  }
}
```

### 6. Enhanced Onboarding Experience

**Problem:** Basic onboarding without proper guidance.

**Solution:** Create comprehensive 4-slide onboarding with illustrations.

```dart
// In screens/onboarding_screen.dart
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Bienvenue sur NgoNest",
      description: "Gérez votre inventaire et votre budget facilement",
      illustration: "assets/illustrations/welcome.png",
    ),
    OnboardingPage(
      title: "Gérez votre inventaire facilement",
      description: "Ajoutez vos produits, suivez les dates d'expiration et les quantités",
      illustration: "assets/illustrations/inventory.png",
    ),
    OnboardingPage(
      title: "Suivez votre budget mensuel",
      description: "Définissez votre budget et suivez vos dépenses en temps réel",
      illustration: "assets/illustrations/budget.png",
    ),
    OnboardingPage(
      title: "Recevez des alertes intelligentes",
      description: "Soyez alerté pour les produits à expirer et les dépassements budgétaires",
      illustration: "assets/illustrations/alerts.png",
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPageWidget(page: _pages[index]);
            },
          ),
          
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => _skipOnboarding(context),
              child: Text(l10n.skip),
            ),
          ),
          
          // Page indicators
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildPageIndicator(index == _currentPage),
              ),
            ),
          ),
          
          // Navigation buttons
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: Text(l10n.previous),
                  )
                else
                  Container(), // Empty container for spacing
                
                if (_currentPage < _pages.length - 1)
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(l10n.next),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _finishOnboarding(context),
                    child: Text(l10n.getStarted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
  
  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _previousPage() {
    _pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _skipOnboarding(BuildContext context) {
    // Save that onboarding was completed
    // Navigate to main app
  }
  
  void _finishOnboarding(BuildContext context) {
    // Save that onboarding was completed
    // Navigate to main app with guided first product creation
  }
}
```

### 7. User-Friendly Error Messages

**Problem:** Technical error messages not helpful to users.

**Solution:** Implement ErrorMessageService with user-friendly messages.

```dart
// In services/error_message_service.dart
class ErrorMessageService {
  static String getErrorMessage(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    
    // ✅ Map technical errors to user-friendly messages
    if (error is SocketException) {
      return l10n.noInternetConnection;
    } else if (error is TimeoutException) {
      return l10n.connectionTimeout;
    } else if (error is DatabaseException) {
      return l10n.databaseError;
    } else if (error is FormatException) {
      return l10n.invalidDataFormat;
    } else {
      // ✅ Default to generic message
      return l10n.somethingWentWrong;
    }
  }
  
  static String getSolution(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    
    if (error is SocketException) {
      return l10n.checkInternetConnectionSolution;
    } else if (error is TimeoutException) {
      return l10n.checkConnectionAndRetrySolution;
    } else if (error is DatabaseException) {
      return l10n.restartAppSolution;
    } else {
      return l10n.tryAgainLaterSolution;
    }
  }
  
  static void showErrorDialog(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final errorMessage = getErrorMessage(context, error);
    final solution = getSolution(context, error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text(l10n.error),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            SizedBox(height: 10),
            Text(solution, style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(l10n.retry),
            ),
        ],
      ),
    );
  }
}
```

### 8. Simplified Product Addition Form

**Problem:** Complex form without simplified option for quick entry.

**Solution:** Create Simple/Advanced mode toggle with real-time validation.

```dart
// In screens/add_product_screen.dart
class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool _isAdvancedMode = false;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Advanced fields
  final _priceController = TextEditingController();
  final _expirationController = TextEditingController();
  final _locationController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addProduct),
        actions: [
          // ✅ Toggle between simple and advanced mode
          IconButton(
            icon: Icon(_isAdvancedMode ? Icons.view_headline : Icons.view_agenda),
            onPressed: _toggleMode,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // ✅ Simple mode fields (always visible)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.productName,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: () => _showHelp(context, 'product_name'),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterProductName;
                  }
                  return null;
                },
              ),
              
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: l10n.quantity,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: () => _showHelp(context, 'quantity'),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterQuantity;
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return l10n.pleaseEnterValidQuantity;
                  }
                  return null;
                },
              ),
              
              DropdownButtonFormField<String>(
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                decoration: InputDecoration(
                  labelText: l10n.category,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: () => _showHelp(context, 'category'),
                  ),
                ),
                items: _getCategoryItems(context),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseSelectCategory;
                  }
                  return null;
                },
              ),
              
              // ✅ Advanced mode fields (conditionally visible)
              if (_isAdvancedMode) ...[
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: l10n.price,
                    prefixText: 'FCFA ',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.help_outline),
                      onPressed: () => _showHelp(context, 'price'),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                
                TextFormField(
                  controller: _expirationController,
                  decoration: InputDecoration(
                    labelText: l10n.expirationDate,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectExpirationDate(context),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectExpirationDate(context),
                ),
                
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: l10n.location,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.help_outline),
                      onPressed: () => _showHelp(context, 'location'),
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 20),
              
              // ✅ Real-time validation feedback
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(l10n.addProduct),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _toggleMode() {
    setState(() {
      _isAdvancedMode = !_isAdvancedMode;
    });
    
    // Save preference
    PreferenceService().setBool('add_product_advanced_mode', _isAdvancedMode);
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Submit form with validation feedback
      _saveProduct(context);
    }
  }
  
  void _saveProduct(BuildContext context) async {
    try {
      // Show loading indicator
      LoadingIndicator.show(context);
      
      // Save product
      final product = Objet(
        // ... map form fields to product object
      );
      
      await InventoryRepository().create(product);
      
      // Hide loading indicator
      LoadingIndicator.hide();
      
      // ✅ Show success feedback with animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.productAddedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      // Hide loading indicator
      LoadingIndicator.hide();
      
      // Show error with user-friendly message
      ErrorMessageService.showErrorDialog(context, e);
    }
  }
}
```

### 9. Functional Quick Actions

**Problem:** Quick actions not fully implemented or inconsistent.

**Solution:** Implement consistent quick actions with proper navigation.

```dart
// In widgets/quick_actions_row.dart
class QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionButton(
            icon: Icons.add_shopping_cart,
            label: l10n.addArticle,
            onTap: () => _navigateToAddProduct(context),
          ),
          _QuickActionButton(
            icon: Icons.inventory,
            label: l10n.inventory,
            onTap: () => _navigateToInventory(context),
          ),
          _QuickActionButton(
            icon: Icons.account_balance_wallet,
            label: l10n.budget,
            onTap: () => _navigateToBudget(context),
          ),
          _QuickActionButton(
            icon: Icons.settings,
            label: l10n.settings,
            onTap: () => _navigateToSettings(context),
          ),
        ],
      ),
    );
  }
  
  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductScreen()),
    );
  }
  
  void _navigateToInventory(BuildContext context) {
    Navigator.pushNamed(context, '/inventory');
  }
  
  void _navigateToBudget(BuildContext context) {
    Navigator.pushNamed(context, '/budget');
  }
  
  void _navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
```

### 10. Dashboard Performance Optimization

**Problem:** Dashboard performance issues with large datasets.

**Solution:** Implement pagination, lazy loading, and caching.

```dart
// In screens/dashboard_screen.dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardDataFuture;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  List<Objet> _products = [];
  final Map<String, dynamic> _cachedCalculations = {};
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // ✅ Lazy load statistics
      final dashboardData = await DashboardService().getDashboardData(
        useCache: _cachedCalculations.isNotEmpty,
        cache: _cachedCalculations,
      );
      
      // Cache calculations
      _cachedCalculations.addAll(dashboardData.calculations);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorMessageService.showErrorDialog(context, e);
    }
  }
  
  Future<void> _loadProductsPage(int page) async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // ✅ Pagination for product list
      final products = await InventoryRepository().getProducts(
        offset: page * _pageSize,
        limit: _pageSize,
      );
      
      setState(() {
        _products.addAll(products);
        _currentPage = page;
        _hasMoreData = products.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorMessageService.showErrorDialog(context, e);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<DashboardData>(
          future: _dashboardDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: ErrorMessageWidget(
                  error: snapshot.error!,
                  onRetry: () => _loadDashboardData(),
                ),
              );
            }
            
            final data = snapshot.data!;
            
            return CustomScrollView(
              slivers: [
                // Dashboard header with statistics
                SliverAppBar(
                  // ... app bar implementation
                ),
                
                // Quick actions
                SliverToBoxAdapter(
                  child: QuickActionsRow(),
                ),
                
                // ✅ Performance optimized product list with pagination
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _products.length) {
                        // Load more when reaching the end
                        if (!_isLoading && _hasMoreData) {
                          _loadProductsPage(_currentPage + 1);
                        }
                        return _isLoading ? Center(child: CircularProgressIndicator()) : null;
                      }
                      
                      final product = _products[index];
                      return ProductListItem(product: product);
                    },
                    childCount: _products.length + (_hasMoreData ? 1 : 0),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Future<void> _refreshData() async {
    // Clear cache and reload
    _cachedCalculations.clear();
    _products.clear();
    _currentPage = 0;
    _hasMoreData = true;
    await _loadDashboardData();
    await _loadProductsPage(0);
  }
}
```

## Data Models

### AlertState Model
```dart
// In models/alert_state.dart
class AlertState {
  final int? id;
  final String alertId;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlertState({
    this.id,
    required this.alertId,
    this.isRead = false,
    this.isResolved = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // toMap and fromMap methods...
}
```

## Error Handling

### Error Handling Strategy

1. **UI Errors**: Show user-friendly localized messages with retry options
2. **Service Errors**: Log with ErrorLoggerService, don't block operations
3. **Database Errors**: Retry with exponential backoff, fallback to cached data
4. **Network Errors**: Graceful degradation to offline mode
5. **Validation Errors**: Real-time feedback in forms

### Error Severity Levels

- **INFO**: User actions, successful operations (for analytics)
- **LOW**: Non-critical issues, warnings
- **MEDIUM**: Feature degradation, recoverable errors
- **HIGH**: Data access failures, operation failures
- **CRITICAL**: App crashes, data corruption

## Testing Strategy

### Unit Tests

1. **FeatureFlagService**
   - Test isFeatureEnabled returns correct values for different build modes
   - Test cloud sync disabled in release mode
   - Test premium features disabled

2. **AlertRepository**
   - Test alert state persistence
   - Test performance with large datasets
   - Test concurrent access handling

3. **ErrorMessageService**
   - Test error mapping to user-friendly messages
   - Test solution suggestions
   - Test dialog presentation

### Integration Tests

1. **Security Configuration Flow**
   - Environment variables correctly loaded
   - API keys not exposed in release builds
   - Code obfuscation applied

2. **Alert Persistence Flow**
   - Alert created → state saved → app restart → state restored
   - Multiple alerts → performance testing → UI responsiveness

3. **Onboarding to Main App Flow**
   - Complete onboarding → guided first product creation → main dashboard
   - Skip onboarding → main dashboard → quick actions work

### Widget Tests

1. **AddProductScreen**
   - Test simple/advanced mode toggle
   - Test form validation
   - Test real-time feedback

2. **DashboardScreen**
   - Test quick actions navigation
   - Test pagination with loading indicators
   - Test refresh functionality

## Performance Considerations

### Optimization Strategies

1. **Database Indexing**: Proper indexes on alert_states table
2. **Memory Management**: Dispose controllers, cancel futures on widget disposal
3. **Network Optimization**: Batch requests, cache responses
4. **UI Virtualization**: Pagination for large lists
5. **Lazy Loading**: Defer heavy calculations until needed

### Performance Targets

- Dashboard load time: < 2 seconds with 500+ products
- Alert state operations: < 50ms
- Form validation feedback: immediate
- Memory usage: < 100MB with 1000+ products
- Battery drain: < 5% per hour of active use

## Security Considerations

1. **API Key Protection**: Environment variables, not in source code
2. **Code Obfuscation**: Release build protection
3. **Data Validation**: Input sanitization, SQL injection prevention
4. **Privacy**: No personal data collection without consent
5. **Secure Storage**: Encrypted local database
6. **Permission Management**: Minimal required permissions with clear explanations

## Deployment Strategy

### Phased Rollout

**Phase 1: Core Security and Configuration (Week 1)**
- Environment variable configuration
- Code obfuscation
- Feature flags implementation
- Sync service disabled in production

**Phase 2: Critical Fixes (Weeks 2-4)**
- Alert persistence system
- Price database validation
- Premium features removal

**Phase 3: UX Improvements (Weeks 5-7)**
- Enhanced onboarding
- User-friendly error messages
- Simplified product form
- Quick actions implementation

**Phase 4: Performance Optimization (Weeks 8-10)**
- Dashboard optimization
- Pagination implementation
- Caching strategies

**Phase 5: Advanced Features (Weeks 11-12)**
- Calendar service
- Notifications system
- Budget enhancements

**Phase 6: Polish and Testing (Weeks 13-15)**
- Accessibility improvements
- Complete internationalization
- Simplified mode implementation
- Design polish

**Phase 7: Launch Preparation (Week 16)**
- Beta testing
- Store preparation
- Marketing materials
- Launch

### Rollback Plan

If critical issues discovered:
1. Revert to previous stable version via app store procedures
2. Disable problematic features via remote feature flags
3. Deploy hotfix with specific fix
4. Communicate with users about the issue

## Monitoring and Analytics

### Key Metrics to Track

1. **User Engagement**: Daily/Monthly Active Users
2. **Feature Usage**: Which features are most used
3. **Error Rates**: Frequency and types of errors
4. **Performance**: Load times, memory usage
5. **Retention**: User retention rates
6. **Onboarding Completion**: Percentage of users completing onboarding

### Analytics Events

```dart
'analytics_event_onboarding_started'
'analytics_event_onboarding_completed'
'analytics_event_product_added'
'analytics_event_product_edited'
'analytics_event_budget_viewed'
'analytics_event_alert_triggered'
'analytics_event_error_occurred'
'analytics_event_feature_used' // with feature_name parameter
```

## Future Enhancements

1. **AI-Powered Suggestions**: Recommend products based on consumption patterns
2. **Voice Commands**: Add products via voice input
3. **Barcode Scanning**: Scan products for quick addition
4. **Recipe Integration**: Suggest recipes based on available ingredients
5. **Family Sharing**: Share inventory with family members
6. **Advanced Analytics**: Predictive analytics for shopping needs