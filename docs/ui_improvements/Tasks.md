# Implementation Plan

- [ ] 1. Rendre le dashboard interactif
  - [ ] Rendre les cartes `StatsCard` cliquables et rediriger vers les listes détaillées
  - [ ] Ajouter un indicateur de dernière synchronisation
  - _Requirements: 1_

- [ ] 2. Ajouter recherche et filtres dans l'inventaire
  - [ ] Intégrer une barre de recherche avec filtrage en temps réel
  - [ ] Créer un panneau de filtres (pièce, date d'expiration)
  - [ ] Permettre la mise à jour rapide des quantités depuis la liste
  - _Requirements: 2_

- [ ] 3. Implémenter les alertes de budget
  - [ ] Permettre la création et l'édition de catégories de budget
  - [ ] Déclencher des alertes visuelles et notifications en cas de dépassement
  - [ ] Afficher l'historique des dépenses par mois
  - _Requirements: 3_

- [ ] 4. Persister les paramètres et supporter le multilingue
  - [ ] Sauvegarder les préférences via `SharedPreferences`
  - [ ] Appliquer dynamiquement la langue sélectionnée
  - [ ] Gérer l'activation/désactivation des notifications
  - _Requirements: 4_

- [ ] 5. Améliorer l'accessibilité et les feedbacks
  - [ ] Vérifier les contrastes pour les thèmes clair/sombre
  - [ ] Afficher des messages d'erreur/action clairs lors des échecs de synchronisation
  - [ ] Confirmer les actions réussies via SnackBars ou toasts
  - _Requirements: 5_

