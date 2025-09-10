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
class MainNavigationWrapper extends StatefulWidget {
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
  onTabChanged: (index) => _navigateToTab(index),
)
```

#### _buildBottomNavigation
Barre de navigation spécifique au contexte  avec 5 onglets principaux :

```dart
class CameroonBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
}
```

**Onglets disponibles :**
- **Accueil** (index 0) : Dashboard principal
- **Produits** (index 1) : Liste des produits/inventaire
- **Ajouter** (index 2) : Ajout de nouveaux produits
- **Budget** (index 3) : Gestion du budget
- **Profil** (index 3) : Paramètres et profil utilisateur

### Structure du Projet

```
lib/
├── widgets/
│   ├── connectivity_banner.dart           # Bannière de connectivité
│   ├── main_navigation_wrapper.dart       # Wrapper de navigation cohérente
│   └── cameroon_bottom_navigation.dart    # Barre de navigation camerounaise
├── screens/
│   ├── developer_console_screen.dart      # Console développeur
│   └── [autres écrans...]
├── services/
│   └── connectivity_service.dart          # Service de connectivité
├── main.dart                              # Point d'entrée avec overlay global
└── test/
    └── widgets/
        └── connectivity_banner_test.dart  # Tests unitaires bannière
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
- ✅ Widget CameroonBottomNavigation avec 4 onglets principaux
- ✅ Définition des routes et index pour navigation fluide
- ✅ Interface harmonisée respectant le thème de l'application

### Tests
Pour tester la bannière de connectivité :
1. Utiliser les tests unitaires : `flutter test test/widgets/connectivity_banner_test.dart`
2. Tester manuellement en activant/désactivant le WiFi sur l'appareil
3. Utiliser la console développeur pour voir les logs de connectivité
