# Documentation Technique - Gestion de la Connectivité

Version : v1.0 — Décembre 2024

## Vue d'ensemble

NgonNest implémente une gestion intelligente de la connectivité réseau pour informer l'utilisateur de l'état de sa connexion internet de manière non-intrusive. Cette fonctionnalité améliore l'expérience utilisateur en fournissant un feedback visuel clair sur la disponibilité du réseau.

## Architecture

### Composants Principaux

#### ConnectivityService
Service singleton qui surveille l'état de la connectivité réseau :
- Utilise le package `connectivity_plus` pour la détection réseau
- Notifie les changements d'état via `ChangeNotifier`
- Gère les états : connecté, déconnecté, reconnecté
- Optimisé pour les connexions instables (contexte Cameroun)

#### ConnectivityBanner
Widget de bannière qui affiche le statut de connectivité :
- **Hors ligne** : Bannière orange avec "Vous êtes hors ligne"
- **Reconnecté** : Bannière verte avec "De retour en ligne" (3 secondes)
- **Connecté** : Masqué automatiquement
- Compatible thèmes light/dark via `Theme.of(context).colorScheme`
- Animation fluide avec `AnimatedOpacity`
- Bouton de fermeture intégré

#### AppWithConnectivityOverlay
Wrapper global qui intègre la bannière sur tous les écrans :
- Positionnement fixe en haut de l'écran
- Respecte la safe area du device
- Superposition non-intrusive sur le contenu

### Intégration

La bannière est intégrée globalement dans `main.dart` :

```dart
// Toutes les routes utilisent le wrapper
'/dashboard': (context) => const AppWithConnectivityOverlay(child: DashboardScreen()),
'/inventory': (context) => const AppWithConnectivityOverlay(child: InventoryScreen()),
// etc.
```

## Comportement

### États de Connectivité

1. **Connexion normale** : Aucune bannière affichée
2. **Perte de connexion** : Bannière orange persistante "Vous êtes hors ligne"
3. **Reconnexion** : Bannière verte temporaire "De retour en ligne" (4 secondes)

### Gestion des Transitions

- Détection automatique des changements réseau
- Masquage automatique après reconnexion
- Option de fermeture manuelle par l'utilisateur
- Pas d'affichage au démarrage de l'app (évite les faux positifs)

## Tests

### Tests Unitaires
- `test/widgets/connectivity_banner_test.dart` : Tests complets du widget
- Couverture des états connecté/déconnecté/reconnecté
- Validation des couleurs de thème
- Test du bouton de fermeture

### Tests Manuels
1. Activer/désactiver le WiFi sur l'appareil
2. Vérifier l'affichage de la bannière sur différents écrans
3. Tester la fermeture manuelle
4. Valider les couleurs en mode light/dark

## Configuration

### Dépendances
```yaml
dependencies:
  connectivity_plus: ^6.0.5
  provider: ^6.1.2
```

### Paramètres
- Durée d'affichage reconnexion : 4 secondes
- Position : Top safe area + 8px
- Marges horizontales : 16px
- Border radius : 16px

## Évolutions Futures

- Support multi-langues (anglais/français)
- Analytics sur les patterns de connectivité
- Gestion offline avancée avec cache local
- Personnalisation des messages par région