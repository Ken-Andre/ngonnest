# NgonNest

NgonNest est une application mobile de gestion de commandes pour la gestion de son domicile, conçue pour fonctionner en mode hors‑ligne et faciliter l'expansion régionale et internationale. Ce dépôt GitHub constitue la **référence unique (Single Source of Truth)** du projet, centralisant tout le code s la documentation technique et fonctionnelle, ainsi que les tickets de suivi source, la documentation technique et fonctionnelle, ainsi que les tickets de suivi【535510735933765†screenshot】.】.

- `code/flutter/` – contient l'application mobile Flutter. Un fichier `.gitkeep` est présent pour conserver l'arborescence.
- `code/telegram_bot/` – contiendra le code du bot Telegram qui permet de créer automatiquement des issues GitHub depuis l'application【845134010872208†screenshot】.
- `docs/` – documentation du projet : cahier des charges, dictionnaire de données, matrice d'accès, guide utilisateur et plans de test.
- `issues/` – modèles pour créer des tickets de **bug** et de **feedback** dans GitHub Issues.

## Prérequis

- Flutter 3.x installé (https://flutter.dev)
- Dart 3.x
- Un éditeur de code (Visual Studio Code ou Android Studio)
- Optionnel : Node.js ou Python pour exécuter le bot Telegram (selon l'implémentation)

## Installation de l'application mobile

Clonez ce dépôt et installez les dépendances :

```bash
git clone https://github.com/Ken-Andre/ngonnest.git
cd ngonnest/code/flutter
flutter pub get
flutter run
```

L'application repose sur une base de données locale SQLite pour permettre une utilisation hors‑ligne et la synchronisation ultérieure lorsqu'une connexion est disponible. 

## Fonctionnalités Implémentées

### Gestion de la Connectivité
- **Bannière de connectivité globale** : Affichage automatique du statut réseau sur tous les écrans
- **Service de surveillance réseau** : Détection en temps réel des changements de connectivité
- **Interface adaptative** : Support automatique des thèmes light/dark
- **Tests unitaires** : Couverture complète des widgets et services de connectivité

### Navigation Cohérente
- **MainNavigationWrapper** : Structure de navigation unifiée pour tous les écrans principaux
- **Barre de navigation intégrée** : 5 onglets adaptés au contexte camerounais (Accueil, Inventaire, Ajouter, Budget, Paramètres)
- **Navigation fluide** : Transitions cohérentes avec animations de 200ms et feedback visuel immédiat
- **Interface harmonisée** : Styles et couleurs cohérents respectant le thème de l'application
- **Intégration complète** : Implémentée sur Dashboard, Inventory et Budget screens

### Gestion d'Inventaire Avancée
- **Recherche en temps réel** : Barre de recherche avec debounce de 150ms pour filtrer par nom, catégorie et pièce
- **Filtres avancés** : Panneau de filtres par localisation et date d'expiration avec état persistant
- **Mise à jour rapide** : Modification des quantités directement depuis la liste avec sauvegarde immédiate
- **Support des localisations** : Champ `room` dans le modèle Objet pour organiser par pièce/zone
- **Interface contextuelle** : Affichage adapté selon le type d'objet (consommable vs durable)

### Gestion Budgétaire
- **Modèle BudgetCategory** : Structure complète pour les catégories de budget avec limites et dépenses
- **Suivi mensuel** : Gestion des budgets par mois avec format YYYY-MM
- **Calculs automatiques** : Pourcentage de dépenses, détection de dépassement, budget restant
- **Alertes intelligentes** : Détection automatique des budgets proches de la limite (>80%) ou dépassés
- **Historique détaillé** : Écran BudgetExpenseHistory avec visualisation sur 12 mois
- **Analyse des tendances** : Cartes de résumé avec totaux et moyennes mensuelles
- **Performance optimisée** : Chargement de l'historique garanti en moins de 2 secondes
- **Persistance données** : Sérialisation complète pour base de données SQLite
- **Interface budget** : Écran dédié avec statistiques et gestion des catégories

### Console Développeur
- **Interface de debug** : Écran dédié pour visualiser les logs et erreurs
- **Filtrage avancé** : Tri par sévérité et type d'erreur
- **Métadonnées système** : Informations contextuelles pour le debug

### Dashboard Interactif
- **Cartes statistiques cliquables** : Navigation directe vers les sections détaillées
- **Articles totaux** : Accès rapide à l'inventaire complet
- **Articles à surveiller** : Navigation vers les produits urgents avec indication visuelle
- **Alertes urgentes** : Ouverture directe du panneau de notifications

Les tests unitaires et fonctionnels se trouvent dans le dossier `code/flutter/ngonnest_app/test/` et sont maintenus à jour avec les nouvelles fonctionnalités.

## Lancer le bot Telegram

Le dossier `code/telegram_bot` contient l'implémentation du bot permettant de remonter des bugs et suggestions vers GitHub. Après avoir configuré vos variables d'environnement (`.env`), exécutez le bot selon les instructions du README spécifique dans ce dossier.

## Contribution

Les contributions se font via des tickets. Utilisez les modèles `issues/bug_template.md` et `issues/feedback_template.md` pour signaler un bug ou soumettre une amélioration. Les labels `bug`, `feedback` ainsi que les priorités `P1`, `P2` et `P3` permettent de classifier les demandes.

## Licence

Ce projet est sous licence propriétaire. Toute diffusion nécessite l'accord du Product Owner.
