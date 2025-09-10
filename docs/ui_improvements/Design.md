# Design Document

## Overview
Ce document décrit l'approche de conception pour les améliorations UI/UX proposées dans NgonNest. Les changements visent une interface plus interactive, personnalisable et accessible.

## Architecture
- **Dashboard** : les cartes de statistiques deviennent des widgets cliquables redirigeant vers des vues filtrées.
- **Inventaire** : ajout d'un `SearchBar` et d'un `FilterPanel` reposant sur l'état local du `InventoryViewModel`.
- **Budget** : intégration d'un service de suivi des dépenses par catégorie avec stockage dans la base locale.
- **Paramètres** : utilisation de `SharedPreferences` pour la persistance et d'un `LocaleProvider` pour le changement de langue.

## Data Flow
1. Les vues interrogent le `Repository` local (SQLite) pour récupérer ou modifier les données.
2. Les filtres de recherche agissent en mémoire, puis synchronisent les modifications via le `Repository`.
3. Les alertes de budget déclenchent des notifications locales lorsque le seuil est dépassé.

## Components and Interfaces
- `StatsCard` (dashboard) → navigue vers les écrans détaillés.
- `InventorySearchBar` et `FilterPanel` → exposent des callbacks pour mettre à jour le `InventoryViewModel`.
- `BudgetCategoryCard` → affiche la progression et gère les alertes.
- `SettingsPage` → widgets de sélection de langue et de notifications reliés à `SettingsService`.

## Data Models
- **Item**: ajout d'attributs `room` et `expiryDate` pour le filtrage.
- **BudgetCategory**: champs `limit`, `spent`, `month`.
- **Settings**: `language`, `notificationsEnabled` stockés via `SharedPreferences`.

## Error Handling
- Les erreurs de synchronisation affichent une bannière avec option de réessai.
- Les actions critiques (modification de budget) sont confirmées via dialogues modaux.

## Testing Strategy
- Tests unitaires pour `InventoryViewModel` (filtrage, recherche).
- Tests widget pour la navigation à partir des `StatsCard`.
- Tests d'intégration simulant le changement de langue et la persistance des paramètres.

## Implementation Notes
- Respecter les couleurs et le typographie définies dans `AppTheme`.
- Prévoir la compatibilité avec les modes clair et sombre.

