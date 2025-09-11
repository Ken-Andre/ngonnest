# NgonNest App

Application mobile Flutter pour la gestion d'inventaire domestique au Cameroun.

## Architecture

### Widgets Principaux

#### ConnectivityBanner
Widget de bannière de connectivité dynamique qui affiche le statut de connexion réseau :

- **Offline** : Bannière rouge avec "Vous êtes hors ligne" (colorScheme.error)
- **Reconnecté** : Bannière verte avec "De retour en ligne" (colorScheme.secondary)
- **Connecté** : Masqué automatiquement

**Utilisation :**
```dart
const ConnectivityBanner(), // Utilise automatiquement ConnectivityService
```

**Caractéristiques :**
- Compatible thème light/dark automatiquement
- Utilise UNIQUEMENT les couleurs du thème Flutter (colorScheme)
- Intégration automatique avec ConnectivityService via Provider
- Animation fluide avec AnimatedOpacity
- Bouton de fermeture intégré
- Masquage automatique quand connecté normalement
- **Intégration globale** : Superposée sur tous les écrans via AppWithConnectivityOverlay

#### AppWithConnectivityOverlay
Wrapper global qui affiche la bannière de connectivité en overlay sur tous les écrans :

```dart
class AppWithConnectivityOverlay extends StatelessWidget {
  final Widget child;
  // Positionne la bannière en haut de l'écran avec safe area
}
```

**Intégration :**
- Appliquée automatiquement à toutes les routes de l'app
- Respecte la safe area du device
- Positionnement fixe en haut avec marges (top: safe area + 8px, left/right: 16px)

#### MainNavigationWrapper
Widget wrapper qui fournit une structure de navigation cohérente pour tous les écrans principaux :

```dart
class MainNavigationWrapper extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;
}
```

**Utilisation :**
```dart
MainNavigationWrapper(
  body: DashboardScreen(),
  currentIndex: 0,
  onTabChanged: (index) => NavigationService.navigateToTab(context, index),
)
```

**Caractéristiques :**
- Encapsule automatiquement le contenu dans un Scaffold
- Intègre la barre de navigation en bas avec animations fluides
- Utilise les couleurs du thème pour compatibilité light/dark
- Gère la mise en évidence de l'onglet actuel
- Transitions animées de 200ms pour les changements d'état

#### Barre de Navigation Intégrée
Barre de navigation avec 5 onglets principaux adaptés au contexte camerounais :

**Onglets disponibles :**
- **Accueil** (index 0) : Dashboard principal avec vue d'ensemble
- **Inventaire** (index 1) : Liste des produits et gestion de l'inventaire
- **Ajouter** (index 2) : Ajout de nouveaux produits
- **Budget** (index 3) : Gestion du budget et suivi des dépenses
- **Paramètres** (index 4) : Configuration et profil utilisateur

**Icônes utilisées :**
- Accueil : `CupertinoIcons.house`
- Inventaire : `CupertinoIcons.cube_box`
- Ajouter : `CupertinoIcons.add`
- Budget : `CupertinoIcons.money_dollar`
- Paramètres : `CupertinoIcons.gear`

#### Widgets d'Inventaire Avancés

##### InventorySearchBar
Widget de barre de recherche avec debounce intégré pour filtrage en temps réel :

```dart
const InventorySearchBar(
  onSearchChanged: (query) => _filterItems(query),
  hintText: 'Rechercher par nom, catégorie ou pièce...',
),
```

**Caractéristiques :**
- Debounce de 150ms pour optimiser les performances
- Bouton de suppression automatique quand du texte est saisi
- Recherche par nom, catégorie et pièce/localisation
- Interface cohérente avec le design de l'application

##### InventoryFilterPanel
Panneau de filtres avancés pour l'inventaire avec état persistant :

```dart
InventoryFilterPanel(
  filterState: _filterState,
  onFilterChanged: (newState) => _applyFilters(newState),
  availableRooms: _getAvailableRooms(),
  isExpanded: _isFilterExpanded,
  onToggleExpanded: () => _toggleFilterPanel(),
)
```

**Fonctionnalités :**
- Filtrage par pièce/localisation avec chips sélectionnables
- Filtrage par date d'expiration (tous, expire bientôt, expirés)
- Compteur de filtres actifs avec badge visuel
- État persistant lors de la navigation
- Interface expandable/collapsible

##### QuickQuantityUpdate
Widget de mise à jour rapide des quantités directement depuis la liste :

```dart
QuickQuantityUpdate(
  objet: objet,
  onQuantityChanged: (newQuantity) => _updateQuantity(objet, newQuantity),
)
```

**Caractéristiques :**
- Édition en place avec validation en temps réel
- Sauvegarde automatique avec feedback utilisateur
- Gestion d'erreurs avec messages explicites
- Interface optimisée pour les consommables uniquement
- Indicateur de chargement pendant la mise à jour

### Modèle de Données

#### Objet (Produit)
Le modèle `Objet` représente un produit dans l'inventaire avec support des localisations :

```dart
class Objet {
  final String nom;
  final String categorie;
  final TypeObjet type; // consommable ou durable
  final String? room; // Pièce/localisation où l'objet est stocké
  final double quantiteRestante;
  final String unite;
  // ... autres propriétés
}
```

**Nouveautés :**
- **Champ `room`** : Localisation/pièce où l'objet est stocké
- Support complet des consommables et biens durables
- Commentaires personnalisés pour les biens durables
- Gestion des dates d'expiration et alertes

#### BudgetCategory (Catégorie de Budget)
Le modèle `BudgetCategory` représente une catégorie de budget mensuel :

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

**Fonctionnalités :**
- **Suivi mensuel** : Gestion par mois avec format standardisé YYYY-MM
- **Calculs automatiques** : `spendingPercentage`, `isOverBudget`, `isNearLimit`, `remainingBudget`
- **Persistance SQLite** : Méthodes `toMap()` et `fromMap()` pour la base de données
- **Immutabilité** : Méthode `copyWith()` pour les mises à jour
- **Alertes intelligentes** : Détection automatique des dépassements et seuils

### Structure du Projet

```
lib/
├── widgets/
│   ├── connectivity_banner.dart           # Bannière de connectivité
│   ├── main_navigation_wrapper.dart       # Wrapper de navigation cohérente
│   ├── inventory_search_bar.dart          # Barre de recherche inventaire
│   ├── inventory_filter_panel.dart        # Panneau de filtres avancés
│   ├── quick_quantity_update.dart         # Mise à jour rapide quantités
│   └── sync_banner.dart                   # Bannière de synchronisation
├── screens/
│   ├── dashboard_screen.dart              # Écran principal avec navigation
│   ├── inventory_screen.dart              # Écran inventaire avec recherche/filtres
│   ├── budget_screen.dart                 # Écran budget avec navigation
│   ├── developer_console_screen.dart      # Console développeur
│   └── [autres écrans...]
├── models/
│   ├── objet.dart                         # Modèle produit avec support pièces
│   └── budget_category.dart               # Modèle catégorie de budget
├── services/
│   ├── connectivity_service.dart          # Service de connectivité
│   └── navigation_service.dart            # Service de navigation
├── main.dart                              # Point d'entrée avec overlay global
└── test/
    ├── widgets/
    │   ├── connectivity_banner_test.dart  # Tests unitaires bannière
    │   ├── inventory_search_bar_test.dart # Tests barre de recherche
    │   ├── inventory_filter_panel_test.dart # Tests panneau filtres
    │   └── quick_quantity_update_test.dart # Tests mise à jour quantités
    └── integration/
        ├── connectivity_integration_test.dart # Tests d'intégration connectivité
        └── inventory_search_integration_test.dart # Tests d'intégration inventaire
```

## Installation

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

Les tests unitaires pour ConnectivityBanner se trouvent dans `test/widgets/connectivity_banner_test.dart`.

## Développement

### Fonctionnalités Implémentées

#### Bannière de Connectivité Globale
- ✅ Widget ConnectivityBanner avec support thème light/dark
- ✅ Service ConnectivityService avec surveillance réseau en temps réel
- ✅ Intégration globale via AppWithConnectivityOverlay sur tous les écrans
- ✅ Tests unitaires complets
- ✅ Animation fluide et bouton de fermeture

#### Console Développeur
- ✅ Écran DeveloperConsoleScreen pour debug et logs
- ✅ Filtrage par sévérité d'erreur
- ✅ Interface dark theme style console
- ✅ Gestion des logs avec métadonnées

#### Navigation Cohérente
- ✅ Widget MainNavigationWrapper pour structure unifiée
- ✅ Barre de navigation intégrée avec 5 onglets principaux
- ✅ Intégration sur Dashboard, Inventory et Budget screens
- ✅ Animations fluides et feedback visuel immédiat
- ✅ Utilisation du NavigationService pour la gestion des routes
- ✅ Interface harmonisée respectant le thème de l'application
- ✅ Support complet des couleurs de thème light/dark

#### Dashboard Interactif
- ✅ Cartes statistiques cliquables avec feedback visuel Material Design
- ✅ Navigation directe vers l'inventaire depuis "Articles totaux"
- ✅ Accès rapide aux articles urgents avec indication visuelle
- ✅ Ouverture du panneau de notifications depuis "Urgences"
- ✅ Transitions fluides avec InkWell et Material components

#### Gestion d'Inventaire Avancée
- ✅ Modèle Objet étendu avec support des pièces/localisations (champ `room`)
- ✅ Barre de recherche avec debounce de 150ms et filtrage en temps réel
- ✅ Panneau de filtres avancés (pièce, date d'expiration) avec état persistant
- ✅ Mise à jour rapide des quantités directement depuis la liste
- ✅ Interface de filtrage intuitive avec compteur de filtres actifs
- ✅ Support complet des consommables et biens durables
- ✅ Affichage contextuel des informations par type d'objet

### Tests
Pour tester la bannière de connectivité :
1. Utiliser les tests unitaires : `flutter test test/widgets/connectivity_banner_test.dart`
2. Tester manuellement en activant/désactivant le WiFi sur l'appareil
3. Utiliser la console développeur pour voir les logs de connectivité
