# Plan d'Action - Correction UI Budget

## 🎯 Objectif
Rendre l'écran budget fonctionnel sur le téléphone en corrigeant les problèmes d'affichage et de synchronisation.

## 📋 Résumé des Problèmes

| # | Problème | Impact | Priorité |
|---|----------|--------|----------|
| 1 | Devise en € au lieu de FCFA | Confusion utilisateur | 🔴 CRITIQUE |
| 2 | Catégories non créées au démarrage | Écran vide | 🔴 CRITIQUE |
| 3 | Incohérence casse catégories | Achats non comptabilisés | 🟡 IMPORTANT |
| 4 | Sync silencieuse sans feedback | Dépenses à 0 | 🟡 IMPORTANT |
| 5 | Messages d'erreur génériques | Difficile à déboguer | 🟢 MINEUR |

## 🚀 Actions Immédiates

### Action 1: Créer le Helper de Devise (15 min)

**Fichier à créer**: `lib/utils/currency_formatter.dart`

```dart
import 'package:intl/intl.dart';

/// Helper pour formater les montants en FCFA (devise camerounaise)
class CurrencyFormatter {
  /// Format simple: "5000 FCFA"
  static String formatFCFA(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }
  
  /// Format avec séparateur de milliers: "5 000 FCFA"
  static String formatFCFAWithSeparator(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }
  
  /// Format compact pour petits espaces: "5k FCFA"
  static String formatFCFACompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k FCFA';
    }
    return '${amount.toStringAsFixed(0)} FCFA';
  }
}
```

### Action 2: Remplacer € par FCFA (30 min)

**Fichiers à modifier**:

#### `lib/screens/budget_screen.dart`
Remplacer lignes 265, 271, 277:
```dart
// AVANT
value: '${(_budgetSummary['totalSpent'] ?? 0.0).toStringAsFixed(1)} €',

// APRÈS
value: CurrencyFormatter.formatFCFA(_budgetSummary['totalSpent'] ?? 0.0),
```

Ajouter l'import en haut du fichier:
```dart
import '../utils/currency_formatter.dart';
```

#### `lib/widgets/budget_category_card.dart`
Remplacer lignes 127, 195, 207:
```dart
// AVANT
'${category.spent.toStringAsFixed(1)} € / ${category.limit.toStringAsFixed(1)} €'

// APRÈS
'${CurrencyFormatter.formatFCFA(category.spent)} / ${CurrencyFormatter.formatFCFA(category.limit)}'
```

Ajouter l'import:
```dart
import '../utils/currency_formatter.dart';
```

### Action 3: Créer Configuration Centralisée des Catégories (20 min)

**Fichier à créer**: `lib/config/categories.dart`

```dart
/// Configuration centralisée des catégories de produits et budgets
class AppCategories {
  /// Liste complète des catégories avec leurs propriétés
  static const List<Map<String, dynamic>> all = [
    {
      'id': 'hygiène',
      'name': 'Hygiène',
      'icon': '🧴',
      'color': '#22C55E',
      'defaultBudget': 120.0,
    },
    {
      'id': 'nettoyage',
      'name': 'Nettoyage',
      'icon': '🧹',
      'color': '#3B82F6',
      'defaultBudget': 80.0,
    },
    {
      'id': 'cuisine',
      'name': 'Cuisine',
      'icon': '🍳',
      'color': '#F59E0B',
      'defaultBudget': 100.0,
    },
    {
      'id': 'bureau',
      'name': 'Bureau',
      'icon': '📋',
      'color': '#8B5CF6',
      'defaultBudget': 50.0,
    },
    {
      'id': 'maintenance',
      'name': 'Maintenance',
      'icon': '🔧',
      'color': '#EF4444',
      'defaultBudget': 70.0,
    },
  ];
  
  /// Obtenir le nom d'affichage d'une catégorie
  static String getDisplayName(String id) {
    final category = all.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {'name': id},
    );
    return category['name'] as String;
  }
  
  /// Obtenir le budget par défaut d'une catégorie
  static double getDefaultBudget(String id) {
    final category = all.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {'defaultBudget': 50.0},
    );
    return category['defaultBudget'] as double;
  }
}
```

### Action 4: Utiliser la Config dans BudgetService (10 min)

**Fichier à modifier**: `lib/services/budget_service.dart`

Ajouter l'import:
```dart
import '../config/categories.dart';
```

Modifier la méthode `initializeDefaultCategories` (ligne 433):
```dart
Future<void> initializeDefaultCategories({String? month}) async {
  try {
    final targetMonth = month ?? getCurrentMonth();

    // Check if categories already exist for this month
    final existing = await getBudgetCategories(month: targetMonth);
    if (existing.isNotEmpty) return;

    // Create default categories from centralized config
    final defaultCategories = AppCategories.all.map((cat) {
      return BudgetCategory(
        name: cat['id'] as String,  // Utiliser l'ID en minuscules
        limit: cat['defaultBudget'] as double,
        month: targetMonth,
      );
    }).toList();

    for (final category in defaultCategories) {
      await createBudgetCategory(category, notify: false);
    }
    
    ConsoleLogger.info('[BudgetService] Created ${defaultCategories.length} default categories');
  } catch (e, stackTrace) {
    await ErrorLoggerService.logError(
      component: 'BudgetService',
      operation: 'initializeDefaultCategories',
      error: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.low,
    );
  }
}
```

### Action 5: Initialiser Budget dans Onboarding (15 min)

**Fichier à modifier**: `lib/screens/onboarding_screen.dart`

Trouver la méthode où le foyer est créé (probablement `_createHousehold` ou similaire) et ajouter:

```dart
// Après la création du foyer
try {
  // Initialize default budget categories
  await BudgetService().initializeDefaultCategories();
  ConsoleLogger.info('[Onboarding] Default budget categories created');
} catch (e, stackTrace) {
  ConsoleLogger.error('[Onboarding]', 'Failed to create budget categories', e);
  await ErrorLoggerService.logError(
    component: 'OnboardingScreen',
    operation: 'initializeBudgetCategories',
    error: e,
    stackTrace: stackTrace,
    severity: ErrorSeverity.medium,
  );
  // Don't block onboarding if budget init fails
}
```

### Action 6: Améliorer les Logs de Synchronisation (10 min)

**Fichier à modifier**: `lib/screens/budget_screen.dart`

Remplacer la section de synchronisation (lignes 88-93):
```dart
// Ensure spending is up-to-date with purchases for this foyer
final foyerId = context.read<FoyerProvider>().foyerId;
if (foyerId == null) {
  ConsoleLogger.warning('[BudgetScreen] No foyerId found, cannot sync budget');
  // Continue loading with empty data
} else {
  try {
    await _budgetService?.syncBudgetWithPurchases(
      foyerId,
      month: _currentMonth,
    );
    ConsoleLogger.info('[BudgetScreen] Budget synced successfully for foyer $foyerId');
  } catch (e, stackTrace) {
    ConsoleLogger.error('[BudgetScreen]', 'Failed to sync budget', e);
    await ErrorLoggerService.logError(
      component: 'BudgetScreen',
      operation: 'syncBudgetWithPurchases',
      error: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.medium,
      metadata: {'foyerId': foyerId, 'month': _currentMonth},
    );
    // Continue loading even if sync fails
  }
}
```

### Action 7: Afficher le Nom de Catégorie Formaté (10 min)

**Fichier à modifier**: `lib/widgets/budget_category_card.dart`

Ajouter l'import:
```dart
import '../config/categories.dart';
```

Modifier l'affichage du nom (ligne 95):
```dart
// AVANT
Text(
  category.name,
  style: TextStyle(...),
),

// APRÈS
Text(
  AppCategories.getDisplayName(category.name),  // Affiche "Hygiène" au lieu de "hygiène"
  style: TextStyle(...),
),
```

## 📝 Checklist de Validation

Après avoir fait toutes les modifications, teste sur le téléphone:

- [ ] **Test 1**: Désinstaller et réinstaller l'app
- [ ] **Test 2**: Compléter l'onboarding
- [ ] **Test 3**: Aller sur l'écran Budget
- [ ] **Test 4**: Vérifier que 5 catégories sont affichées (Hygiène, Nettoyage, Cuisine, Bureau, Maintenance)
- [ ] **Test 5**: Vérifier que tous les montants sont en FCFA, pas en €
- [ ] **Test 6**: Ajouter un produit "Savon" (catégorie hygiène) à 500 FCFA
- [ ] **Test 7**: Retourner sur l'écran Budget
- [ ] **Test 8**: Vérifier que la catégorie "Hygiène" affiche "500 FCFA" dépensés
- [ ] **Test 9**: Vérifier que la barre de progression se remplit
- [ ] **Test 10**: Ajouter plus de produits pour dépasser 80% du budget
- [ ] **Test 11**: Vérifier qu'une alerte orange s'affiche

## 🐛 Débogage

Si ça ne fonctionne toujours pas après les modifications:

### Vérifier les Logs
```dart
// Dans developer_console_screen.dart, ajouter un bouton de test:
ElevatedButton(
  onPressed: () async {
    final foyerId = context.read<FoyerProvider>().foyerId;
    print('=== BUDGET DEBUG ===');
    print('FoyerId: $foyerId');
    
    final categories = await BudgetService().getBudgetCategories();
    print('Nombre de catégories: ${categories.length}');
    for (var cat in categories) {
      print('  - ${cat.name}: ${cat.spent} / ${cat.limit} FCFA');
    }
    
    final summary = await BudgetService().getBudgetSummary();
    print('Résumé: $summary');
    print('===================');
  },
  child: Text('Test Budget'),
)
```

### Vérifier la Base de Données
```dart
// Vérifier si des achats existent
final db = await DatabaseService().database;
final objets = await db.query('objets', where: 'type = ?', whereArgs: ['consommable']);
print('Nombre d\'achats: ${objets.length}');
for (var obj in objets) {
  print('  - ${obj['nom']}: ${obj['prix_unitaire']} FCFA (catégorie: ${obj['categorie']})');
}
```

## ⏱️ Temps Estimé Total

- Action 1: 15 min
- Action 2: 30 min
- Action 3: 20 min
- Action 4: 10 min
- Action 5: 15 min
- Action 6: 10 min
- Action 7: 10 min
- **Total: ~2 heures**

## 📚 Fichiers à Créer/Modifier

### À Créer (2 fichiers)
1. `lib/utils/currency_formatter.dart`
2. `lib/config/categories.dart`

### À Modifier (4 fichiers)
1. `lib/services/budget_service.dart`
2. `lib/screens/budget_screen.dart`
3. `lib/screens/onboarding_screen.dart`
4. `lib/widgets/budget_category_card.dart`

## 🎉 Résultat Attendu

Après ces modifications:
- ✅ L'écran budget affiche 5 catégories dès le premier lancement
- ✅ Tous les montants sont en FCFA
- ✅ Les achats se reflètent automatiquement dans le budget
- ✅ Les alertes s'affichent quand le budget est dépassé
- ✅ Les noms de catégories sont cohérents et bien formatés
- ✅ Les logs permettent de déboguer facilement

Bonne chance ! 🚀
