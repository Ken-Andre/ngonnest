# Documentation Technique - Gestion d'Inventaire Avancée

Version : v1.2 — Décembre 2024

## Vue d'ensemble

NgonNest implémente un système de gestion d'inventaire avancé avec recherche en temps réel, filtres intelligents et mise à jour rapide des quantités. Cette fonctionnalité améliore significativement l'expérience utilisateur en permettant une gestion efficace des produits domestiques avec support des localisations.

## Architecture

### Composants Principaux

#### Modèle Objet Étendu
Le modèle `Objet` a été enrichi avec le support des localisations :

```dart
class Objet {
  final String nom;
  final String categorie;
  final TypeObjet type; // consommable ou durable
  final String? room; // Pièce/localisation où l'objet est stocké
  final double quantiteRestante;
  final String unite;
  final String? commentaires; // Commentaires pour durables
  // ... autres propriétés
}
```

**Nouveautés :**
- **Champ `room`** : Localisation optionnelle pour organiser les objets par pièce
- **Commentaires** : Notes personnalisées pour les biens durables
- **Sérialisation complète** : Support dans `toMap()` et `fromMap()`
- **CopyWith étendu** : Mise à jour immutable avec tous les champs

#### InventorySearchBar
Widget de recherche avec debounce optimisé :

```dart
class InventorySearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String hintText;
  final String? initialValue;
}
```

**Fonctionnalités :**
- **Debounce de 150ms** : Optimise les performances en évitant les recherches excessives
- **Recherche multi-critères** : Nom, catégorie et pièce/localisation
- **Bouton de suppression** : Apparaît automatiquement quand du texte est saisi
- **État persistant** : Maintient la valeur lors des reconstructions

#### InventoryFilterPanel
Panneau de filtres avancés avec état persistant :

```dart
class InventoryFilterPanel extends StatefulWidget {
  final InventoryFilterState filterState;
  final Function(InventoryFilterState) onFilterChanged;
  final List<String> availableRooms;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
}
```

**États de filtre :**
```dart
class InventoryFilterState {
  final String? selectedRoom;
  final ExpiryFilter expiryFilter; // all, expiringSoon, expired
}
```

**Caractéristiques :**
- **Filtrage par pièce** : Chips sélectionnables basés sur les pièces disponibles
- **Filtrage par expiration** : Tous, expire bientôt (≤7 jours), expirés
- **Compteur actif** : Badge indiquant le nombre de filtres appliqués
- **Interface collapsible** : Économise l'espace écran
- **Bouton de réinitialisation** : Efface tous les filtres d'un coup

#### QuickQuantityUpdate
Widget de mise à jour rapide des quantités :

```dart
class QuickQuantityUpdate extends StatefulWidget {
  final Objet objet;
  final Function(double newQuantity) onQuantityChanged;
}
```

**Comportement :**
- **Édition en place** : Transformation du texte en champ éditable
- **Validation temps réel** : Vérification des valeurs numériques
- **Sauvegarde automatique** : Confirmation par Enter ou bouton check
- **Gestion d'erreurs** : Messages explicites en cas d'échec
- **Indicateur de chargement** : Feedback visuel pendant la mise à jour

## Intégration

### Dans InventoryScreen

L'écran d'inventaire intègre tous les composants avancés :

```dart
class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  InventoryFilterState _filterState = const InventoryFilterState();
  bool _isFilterExpanded = false;

  void _applySearchAndFilters() {
    // Logique de filtrage combinée
    // 1. Recherche textuelle
    // 2. Filtre par pièce
    // 3. Filtre par expiration (consommables uniquement)
  }
}
```

### Logique de Filtrage

Le système applique les filtres dans l'ordre suivant :
1. **Recherche textuelle** : Nom, catégorie, pièce (insensible à la casse)
2. **Filtre par pièce** : Si une pièce spécifique est sélectionnée
3. **Filtre par expiration** : Pour les consommables uniquement

## Comportement

### Recherche en Temps Réel

1. **Saisie utilisateur** : Déclenchement du timer de debounce
2. **Attente 150ms** : Évite les recherches excessives
3. **Exécution filtre** : Application des critères de recherche
4. **Mise à jour UI** : Affichage des résultats filtrés

### Gestion des Filtres

1. **Sélection filtre** : Mise à jour de `InventoryFilterState`
2. **Persistance état** : Maintien lors de la navigation
3. **Combinaison filtres** : Application cumulative des critères
4. **Réinitialisation** : Retour à l'état par défaut

### Mise à Jour Quantités

1. **Tap sur quantité** : Activation du mode édition
2. **Saisie valeur** : Validation en temps réel
3. **Confirmation** : Sauvegarde via callback
4. **Feedback** : SnackBar de confirmation ou d'erreur

## Interface Utilisateur

### Recherche
- **Position** : En haut de l'écran, sous l'AppBar
- **Style** : Container arrondi avec bordure subtile
- **Icônes** : Loupe (recherche) et croix (suppression)
- **Placeholder** : "Rechercher par nom, catégorie ou pièce..."

### Filtres
- **Header cliquable** : Icône filtre + compteur + bouton expand
- **Chips de pièce** : Style FilterChip avec sélection unique
- **Chips d'expiration** : Trois options pour les consommables
- **Bouton effacer** : Visible uniquement si filtres actifs

### Quantités
- **État normal** : Container coloré avec icône édition
- **État édition** : TextField + boutons validation/annulation
- **État chargement** : CircularProgressIndicator miniature

## Tests

### Tests Unitaires
- `inventory_search_bar_test.dart` : Tests du widget de recherche
- `inventory_filter_panel_test.dart` : Tests du panneau de filtres
- `quick_quantity_update_test.dart` : Tests de mise à jour quantités

### Tests d'Intégration
- `inventory_search_integration_test.dart` : Tests de recherche end-to-end
- Validation du filtrage combiné (recherche + filtres)
- Tests de performance avec grandes listes

### Tests Manuels
1. **Recherche multi-critères** : Tester nom, catégorie, pièce
2. **Filtres combinés** : Recherche + pièce + expiration
3. **Mise à jour quantités** : Validation, erreurs, succès
4. **Persistance état** : Navigation et retour
5. **Performance** : Listes de 100+ objets

## Performance

### Optimisations
- **Debounce recherche** : Évite les calculs excessifs
- **Filtrage local** : Pas d'appels base de données répétés
- **État immutable** : Évite les reconstructions inutiles
- **Lazy loading** : Chargement différé des pièces disponibles

### Métriques Cibles
- **Temps de recherche** : < 50ms pour 100 objets
- **Temps de filtrage** : < 30ms pour changement de filtre
- **Mise à jour quantité** : < 500ms avec feedback immédiat

## Évolutions Futures

### Fonctionnalités Avancées
- **Tri personnalisé** : Par nom, quantité, date d'expiration
- **Filtres sauvegardés** : Presets de filtres fréquents
- **Recherche vocale** : Intégration speech-to-text
- **Code-barres** : Recherche par scan de produit

### Améliorations UX
- **Suggestions de recherche** : Autocomplétion basée sur l'historique
- **Filtres intelligents** : Suggestions basées sur les habitudes
- **Raccourcis gestuels** : Swipe pour actions rapides
- **Mode hors ligne** : Synchronisation différée des modifications

## Compatibilité

- **Flutter SDK** : Version actuelle du projet
- **Packages** : Aucune dépendance externe supplémentaire
- **Performance** : Optimisé pour devices Android mid-range
- **Accessibilité** : Support des lecteurs d'écran et navigation clavier