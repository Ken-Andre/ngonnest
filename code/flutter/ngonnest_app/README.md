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

### Structure du Projet

```
lib/
├── widgets/
│   ├── connectivity_banner.dart           # Bannière de connectivité
│   └── main_navigation_wrapper.dart       # Wrapper de navigation cohérente
├── screens/
│   ├── dashboard_screen.dart              # Écran principal avec navigation
│   ├── inventory_screen.dart              # Écran inventaire avec navigation
│   ├── budget_screen.dart                 # Écran budget avec navigation
│   ├── developer_console_screen.dart      # Console développeur
│   └── [autres écrans...]
├── services/
│   ├── connectivity_service.dart          # Service de connectivité
│   └── navigation_service.dart            # Service de navigation
├── main.dart                              # Point d'entrée avec overlay global
└── test/
    ├── widgets/
    │   └── connectivity_banner_test.dart  # Tests unitaires bannière
    └── integration/
        └── connectivity_integration_test.dart # Tests d'intégration
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

### Tests
Pour tester la bannière de connectivité :
1. Utiliser les tests unitaires : `flutter test test/widgets/connectivity_banner_test.dart`
2. Tester manuellement en activant/désactivant le WiFi sur l'appareil
3. Utiliser la console développeur pour voir les logs de connectivité
