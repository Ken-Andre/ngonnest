# Documentation Technique - Gestion Budgétaire

Version : v1.0 — Décembre 2024

## Vue d'ensemble

NgonNest implémente un système de gestion budgétaire complet permettant aux utilisateurs de suivre leurs dépenses domestiques par catégories avec des alertes intelligentes. Cette fonctionnalité aide les ménages camerounais à mieux contrôler leurs finances et optimiser leurs achats de produits ménagers.

## Architecture

### Composants Principaux

#### Modèle BudgetCategory
Le modèle `BudgetCategory` représente une catégorie de budget mensuel avec toutes les fonctionnalités nécessaires :

```dart
class BudgetCategory {
  final int? id;
  final String name;
  final double limit;
  final double spent;
  final String month; // Format: YYYY-MM
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Propriétés principales :**
- **id** : Identifiant unique en base de données (nullable pour nouveaux objets)
- **name** : Nom de la catégorie (ex: "Alimentation", "Hygiène", "Entretien")
- **limit** : Limite budgétaire mensuelle en euros
- **spent** : Montant déjà dépensé dans la catégorie
- **month** : Mois concerné au format YYYY-MM (ex: "2024-12")
- **createdAt/updatedAt** : Horodatage pour l'audit et la synchronisation

#### Calculs Automatiques
Le modèle intègre des getters pour les calculs fréquents :

```dart
// Pourcentage de dépenses par rapport à la limite
double get spendingPercentage => limit > 0 ? (spent / limit) : 0.0;

// Vérification si le budget est dépassé
bool get isOverBudget => spent > limit;

// Vérification si proche de la limite (>80%)
bool get isNearLimit => spendingPercentage >= 0.8;

// Calcul du budget restant
double get remainingBudget => limit - spent;
```

#### Persistance et Sérialisation
Support complet pour la base de données SQLite :

```dart
// Conversion vers Map pour stockage
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'limit_amount': limit,
    'spent_amount': spent,
    'month': month,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// Création depuis Map (lecture base)
factory BudgetCategory.fromMap(Map<String, dynamic> map) {
  return BudgetCategory(
    id: map['id']?.toInt(),
    name: map['name'] ?? '',
    limit: (map['limit_amount'] ?? 0.0).toDouble(),
    spent: (map['spent_amount'] ?? 0.0).toDouble(),
    month: map['month'] ?? '',
    createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
  );
}
```

## Fonctionnalités

### Gestion Mensuelle
- **Format standardisé** : Utilisation du format YYYY-MM pour cohérence
- **Isolation temporelle** : Chaque mois est géré indépendamment
- **Historique** : Conservation des données des mois précédents
- **Transition automatique** : Création de nouvelles catégories pour le mois courant

### Alertes Intelligentes
Le système détecte automatiquement :
- **Dépassement de budget** : `isOverBudget` pour alertes critiques
- **Approche de limite** : `isNearLimit` (>80%) pour alertes préventives
- **Budget restant** : Calcul en temps réel du montant disponible

### Intégration Interface
- **BudgetScreen** : Écran principal avec vue d'ensemble et gestion
- **BudgetCategoryCard** : Widget d'affichage avec navigation vers l'historique
- **BudgetExpenseHistory** : Écran détaillé d'historique des dépenses
- **Cartes statistiques** : Affichage visuel des pourcentages et états
- **Notifications** : Alertes push pour dépassements et seuils
- **Thème adaptatif** : Support automatique light/dark

### BudgetExpenseHistory - Historique Détaillé
Nouvel écran permettant de visualiser l'historique des dépenses sur 12 mois :

```dart
class BudgetExpenseHistory extends StatefulWidget {
  final BudgetCategory category;
  final int idFoyer;
}
```

**Fonctionnalités principales :**
- **Historique 12 mois** : Affichage chronologique des dépenses mensuelles
- **Carte de résumé** : Total et moyenne des dépenses avec gradient visuel
- **Indicateurs de performance** : Barres de progression colorées selon le statut
- **Marquage mois actuel** : Badge "Actuel" pour le mois en cours
- **Alertes de dépassement** : Indicateurs visuels pour budgets dépassés
- **Performance optimisée** : Chargement garanti en moins de 2 secondes
- **Gestion d'erreurs** : États d'erreur avec possibilité de retry
- **Actualisation** : Pull-to-refresh et bouton actualiser

**Interface utilisateur :**
- **AppBar** : Titre dynamique avec nom de catégorie et bouton refresh
- **Carte résumé** : Gradient avec totaux et moyennes sur 12 mois
- **Liste historique** : Cards mensuelles avec progression et pourcentages
- **États vides** : Messages informatifs quand aucune donnée disponible
- **Thème cohérent** : Utilisation du colorScheme pour compatibilité light/dark

## Utilisation

### Création d'une Catégorie
```dart
final category = BudgetCategory(
  name: 'Alimentation',
  limit: 200.0,
  month: '2024-12',
);
```

### Mise à Jour des Dépenses
```dart
final updatedCategory = category.copyWith(
  spent: category.spent + 25.0,
  updatedAt: DateTime.now(),
);
```

### Vérification des Alertes
```dart
if (category.isOverBudget) {
  // Déclencher alerte critique
  showCriticalAlert('Budget dépassé pour ${category.name}');
} else if (category.isNearLimit) {
  // Déclencher alerte préventive
  showWarningAlert('Attention: ${category.name} à ${(category.spendingPercentage * 100).round()}%');
}
```

## Base de Données

### Structure Table
```sql
CREATE TABLE budget_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  limit_amount REAL NOT NULL,
  spent_amount REAL DEFAULT 0.0,
  month TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(name, month)
);
```

### Index Recommandés
```sql
CREATE INDEX idx_budget_month ON budget_categories(month);
CREATE INDEX idx_budget_name_month ON budget_categories(name, month);
```

## Tests

### Tests Unitaires
- **Calculs** : Vérification des getters `spendingPercentage`, `isOverBudget`, etc.
- **Sérialisation** : Tests `toMap()` et `fromMap()` avec données variées
- **Immutabilité** : Validation `copyWith()` et `operator==`
- **Edge cases** : Gestion limite zéro, dépenses négatives, dates invalides

### Tests d'Intégration
- **Persistance** : Sauvegarde et lecture depuis SQLite
- **Interface** : Interaction avec BudgetScreen et widgets
- **Notifications** : Déclenchement des alertes selon les seuils

## Performance

### Optimisations
- **Calculs lazy** : Getters calculés à la demande
- **Index base** : Requêtes optimisées par mois et nom
- **Sérialisation efficace** : Conversion directe sans parsing complexe
- **Mémoire** : Objets immutables pour éviter les fuites

### Métriques Cibles
- **Créat