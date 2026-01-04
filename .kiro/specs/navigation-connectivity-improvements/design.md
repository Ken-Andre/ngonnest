# Design Document

## Overview

Cette solution implémente une bannière de connectivité globale et une navigation cohérente pour l'app MVP NgonNest. L'approche privilégie la simplicité et l'efficacité, en utilisant des widgets Flutter natifs et une architecture minimale adaptée au contexte MVP.

## Architecture

### Structure Globale
- **MainApp** : Point d'entrée avec gestion de connectivité globale
- **ConnectivityBanner** : Widget superposé gérant l'affichage du statut réseau
- **MainNavigationWrapper** : Container unifié pour tous les écrans principaux
- **BottomNavigation** : Barre de navigation cohérente

### Flux de Données
```
ConnectivityService → Parent WidConnectivityBanner (overlay)
NavigationState → MainNavigationWrapper → BottomNavigation
```

## Components and Interfaces

### 1. ConnectivityBanner Widget
**Finalité MVP** : Afficher le statut de connexion de manière centrée et temporaire sur toute l'app

```dart
class ConnectivityBanner extends StatelessWidget {
  final bool isConnected;
  final bool isReconnected;
  final VoidCallback? onDismiss;
}
```

**Comportement** :
- Widget statique qui prend des paramètres explicites pour l'état
- Rouge "Pas de connexion" quand offline (colorScheme.error)
- Vert "Connexion rétablie" quand reconnecté (colorScheme.secondary)
- Toutes les couleurs proviennent du thème courant (compatibilité light/dark)
- Masqué automatiquement quand connecté normalement
- Option de fermeture manuelle avec onDismiss
- Utilise les guidelines de l'app (padding, borderRadius, typographie)

### 2. MainNavigationWrapper Widget
**Finalité MVP** : Fournir une structure de navigation cohérente pour tous les écrans principaux

```dart
class MainNavigationWrapper extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;
}
```

**Écrans principaux** :
- Dashboard (index 0)
- Liste des produits (index 1) 
- Ajouter produit (index 2)
- Profil/Paramètres (index 3)

### 3. _buildBottomNavigation  Widget
**Finalité MVP** : Barre de navigation spécifique au contexte  avec icônes et labels adaptés

```dart
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
}
```

## Data Models

### ConnectivityState
```dart
enum ConnectivityState {
  connected,
  disconnected,
  reconnected // État temporaire pour afficher "connexion rétablie"
}
```

### NavigationTab
```dart
class NavigationTab {
  final String label;
  final IconData icon;
  final String route;
  final int index;
}
```

## Error Handling

### Connectivité
- **Timeout réseau** : Considéré comme déconnecté après 7 secondes
- **Erreur de service** : Fallback sur état déconnecté
- **Reconnexion** : Vérification automatique toutes les 5 secondes quand offline

### Navigation
- **Route invalide** : Redirection vers dashboard
- **État incohérent** : Reset de l'index à 0
- **Erreur de transition** : Animation par défaut Flutter

## Testing Strategy

### Tests Unitaires
1. **ConnectivityBanner** : États connected/disconnected/reconnected
2. **MainNavigationWrapper** : Changement d'onglets et état
3. **Navigation logic** : Routes et index valides

### Tests d'Intégration
1. **Connectivité end-to-end** : Simulation perte/retour connexion
2. **Navigation complète** : Parcours entre tous les écrans
3. **Overlay behavior** : Bannière superposée correctement

### Tests Manuels MVP
1. **Scénario Cameroun** : Test avec connexion instable typique
2. **UX cohérente** : Vérification visuelle sur tous les écrans
3. **Performance** : Fluidité des transitions sur device moyen-gamme

## Implementation Notes

### Priorités MVP
1. **Simplicité** : Pas d'état management complexe, utilisation de StatefulWidget
2. **Performance** : Minimal rebuilds, utilisation d'Overlay pour la bannière
3. **Localisation** : Messages en français, adaptés au contexte camerounais

### TODO pour versions futures
- Support multi-langues (anglais/français)
<!-- - Personnalisation des couleurs par région -->
- Analytics sur les patterns de connectivité
- Gestion offline avancée avec cache local

### Contraintes Techniques
- **Flutter SDK** : Version actuelle du projet
- **Packages** : connectivity_plus pour la détection réseau
- **Performance** : Optimisé pour devices Android mid-range populaires au Cameroun