# Implementation Plan

- [x] 1. Créer le widget ConnectivityBanner de base
  - ✅ Implémenter le widget ConnectivityBanner avec affichage statique
  - ✅ Utiliser UNIQUEMENT les couleurs du thème courant via Theme.of(context) (colorScheme.error pour offline, colorScheme.secondary pour reconnecté)
  - ✅ Assurer la compatibilité automatique avec le thème light et dark existant
  - ✅ Créer le visuel et les styles avec les composants, padding, borderRadius, textes respectant les guidelines de l'app
  - ✅ Widget StatelessWidget avec paramètres explicites (isConnected, isReconnected, onDismiss)
  - ✅ Masquage automatique quand connecté normalement (SizedBox.shrink())
  - ✅ Option de fermeture manuelle avec callback onDismiss
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Intégrer la détection de connectivité





  - Ajouter le package connectivity_plus au pubspec.yaml
  - Créer le service de détection de connectivité réseau
  - Connecter le service au ConnectivityBanner pour mise à jour en temps réel
  - _Requirements: 1.1, 1.2, 1.5_

- [x] 3. Implémenter l'overlay global pour la bannière
  - ✅ Modifier le point d'entrée de l'app pour intégrer l'overlay
  - ✅ Positionner la bannière en superposition sur tous les écrans
  - ✅ Tester que la bannière reste visible lors de la navigation
  - _Requirements: 1.3, 1.4_

- [x] 4. Créer une structure de navigation cohérente
    - ✅ Implémenter le widget MainNavigationWrapper pour encapsuler les écrans principaux et intégrer la barre de navigation inférieure de manière réutilisable
    - ✅ Créer la barre de navigation intégrée avec support de la mise en évidence de l'onglet actif et transitions fluides (200ms)
    - ✅ Définir les routes et index pour tous les onglets : index 0 pour dashboard (Accueil), 1 pour inventory (Inventaire), 2 pour add-product (Ajouter), 3 pour budget (Budget), 4 pour settings (Paramètres)
    - ✅ Utiliser les couleurs du thème pour compatibilité light/dark automatique
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 5. Intégrer la navigation sur l'écran dashboard
    - ✅ Wrapper l'écran dashboard existant avec MainNavigationWrapper
    - ✅ Configurer l'onglet dashboard comme actif (index 0) et mettre en évidence visuellement l'icône/label correspondant
    - ✅ Intégrer NavigationService.navigateToTab pour la gestion des transitions fluides
    - ✅ Tester la navigation depuis le dashboard vers les autres sections
    - _Requirements: 2.1, 2.4, 2.5_

- [x] 6. Intégrer la navigation sur l'écran inventaire (liste des produits)
    - ✅ Wrapper l'écran inventory existant avec MainNavigationWrapper
    - ✅ Configurer l'onglet inventaire comme actif (index 1) et mettre en évidence visuellement l'icône/label correspondant
    - ✅ Intégrer NavigationService.navigateToTab pour la cohérence de navigation
    - ✅ Tester la navigation bidirectionnelle avec le dashboard et les autres écrans
    - _Requirements: 2.2, 2.4, 2.5_

- [x] 7. Intégrer la navigation sur l'écran budget
    - ✅ Wrapper l'écran budget existant avec MainNavigationWrapper
    - ✅ Configurer l'onglet budget comme actif (index 3) et mettre en évidence visuellement l'icône/label correspondant
    - ✅ Intégrer NavigationService.navigateToTab pour la cohérence de navigation
    - ✅ Interface harmonisée avec header gradient et statistiques
    - _Requirements: 2.3, 2.4, 2.5_

- [ ] 8. Intégrer la navigation sur les écrans restants (add-product et settings)
    - Wrapper l'écran add-product avec MainNavigationWrapper et configurer comme actif (index 2)
    - Wrapper l'écran settings avec MainNavigationWrapper et configurer comme actif (index 4)
    - Tester la navigation complète entre tous les onglets, avec feedback visuel immédiat et transitions <300ms
    - _Requirements: 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 9. Harmoniser les styles et transitions
  - Unifier les couleurs, typographie et espacements sur tous les écrans
  - Implémenter des transitions fluides entre les onglets (< 300ms)
  - Ajouter le feedback visuel sur les interactions de navigation
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 10. Gérer l'état temporaire "connexion rétablie"
  - Implémenter la logique d'affichage temporaire (3 secondes) de la bannière verte
  - Tester le cycle complet : offline → reconnecté → masqué
  - Optimiser pour éviter les rebuilds inutiles
  - _Requirements: 1.2_

- [ ] 11. Tests finaux et optimisations MVP
  - Tester le comportement complet sur un device Android mid-range
  - Vérifier la fluidité avec connexion instable (simulation Cameroun)
  - Valider l'expérience utilisateur sur tous les écrans principaux
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_