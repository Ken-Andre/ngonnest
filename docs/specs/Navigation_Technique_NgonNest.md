# Documentation Technique - Système de Navigation

Version : v1.0 — Décembre 2024

## Vue d'ensemble

NgonNest implémente un système de navigation cohérent et unifié pour améliorer l'expérience utilisateur sur l'application mobile. Cette fonctionnalité fournit une structure de navigation harmonisée sur tous les écrans principaux avec des transitions fluides et une interface adaptée au contexte camerounais.

## Architecture

### Composants Principaux

#### MainNavigationWrapper
Widget wrapper qui fournit une structure de navigation cohérente :
- Encapsule le contenu de chaque écran principal dans un Scaffold
- Intègre automatiquement la barre de navigation en bas
- Gère l'état de l'onglet actuel et les transitions animées
- Utilise les couleurs du thème pour la compatibilité light/dark
- Implémenté comme StatelessWidget pour optimiser les performances

#### Barre de Navigation Intégrée
Barre de navigation intuitive intégrée dans MainNavigationWrapper :
- **5 onglets principaux** : Accueil, Inventaire, Ajouter, Budget, Paramètres
- **Icônes Cupertino** : Interface moderne et cohérente
- **Labels en français** : Adaptés au contexte camerounais
- **Feedback visuel** : Mise en évidence de l'onglet actuel avec couleur primaire
- **Animations fluides** : Transitions de 200ms pour icônes et textes
- **Thème adaptatif** : Support automatique light/dark via Theme.of(context)

#### NavigationTab (Modèle de données)
Structure de données pour définir les onglets :
```dart
class NavigationTab {
  final String label;
  final IconData icon;
  final String route;
  final int index;
}
```

### Intégration

La navigation est intégrée sur les écrans principaux via le wrapper :

```dart
// Exemple d'utilisation sur le dashboard
MainNavigationWrapper(
  body: DashboardScreen(),
  currentIndex: 0,
  onTabChanged: (index) => _navigateToTab(index),
)
```

## Comportement

### Onglets de Navigation

1. **Accueil (index 0)** : Dashboard principal avec vue d'ensemble et statistiques
2. **Inventaire (index 1)** : Liste des produits et gestion de l'inventaire
3. **Ajouter (index 2)** : Écran d'ajout de nouveaux produits
4. **Budget (index 3)** : Gestion des budgets et suivi des dépenses
5. **Paramètres (index 4)** : Configuration et profil utilisateur

### Gestion des Transitions

- Navigation fluide entre les onglets (< 300ms)
- Mise en évidence visuelle de l'onglet actuel
- Feedback immédiat sur les interactions
- Cohérence visuelle sur tous les écrans

## Styles et Thème

### Couleurs
- Utilise exclusivement `Theme.of(context).colorScheme`
- Support automatique des thèmes light et dark
- Couleurs adaptées au contexte camerounais

### Typographie
- Labels en français pour le contexte local
- Tailles et poids de police cohérents
- Respect des guidelines de l'application

### Espacements
- Padding et marges standardisés
- Respect des safe areas du device
- Interface optimisée pour les écrans mobiles

## Configuration

### Configuration des Onglets
```dart
final tabs = [
  {'icon': CupertinoIcons.house, 'label': 'Accueil'},           // index 0 - Dashboard
  {'icon': CupertinoIcons.cube_box, 'label': 'Inventaire'},     // index 1 - Inventory
  {'icon': CupertinoIcons.add, 'label': 'Ajouter'},             // index 2 - Add Product
  {'icon': CupertinoIcons.money_dollar, 'label': 'Budget'},     // index 3 - Budget
  {'icon': CupertinoIcons.gear, 'label': 'Paramètres'},         // index 4 - Settings
];
```

### Intégration avec NavigationService
```dart
MainNavigationWrapper(
  currentIndex: 0, // Index de l'écran actuel
  onTabChanged: (index) => NavigationService.navigateToTab(context, index),
  body: SafeArea(child: /* Contenu de l'écran */),
)
```

### Paramètres de Performance
- Transitions : < 300ms (requirement 3.2)
- Feedback visuel : Immédiat
- Compatibilité : Devices Android mid-range

## Tests

### Tests Unitaires
- Tests des widgets de navigation
- Validation des transitions entre onglets
- Vérification des couleurs de thème
- Test de l'état de l'onglet actuel

### Tests d'Intégration
- Navigation complète entre tous les écrans
- Cohérence visuelle sur différents thèmes
- Performance sur devices moyens-gamme

### Tests Manuels
1. Tester la navigation sur tous les écrans principaux (Dashboard ✅, Inventory ✅, Budget ✅)
2. Vérifier la fluidité des transitions (200ms animations ✅)
3. Valider l'interface en mode light/dark (thème adaptatif ✅)
4. Contrôler la mise en évidence de l'onglet actuel (couleur primaire ✅)
5. Tester les interactions tactiles et le feedback visuel (CupertinoButton ✅)

## Évolutions Futures

- Support multi-langues (anglais/français)
- Badges de notification sur les onglets
- Animations personnalisées par région
- Analytics sur les patterns de navigation
- Gestion des permissions par onglet