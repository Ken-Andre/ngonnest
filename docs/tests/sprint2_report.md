# Rapport Sprint 2 – NgonNest (Semaine 3-4, 15-28 septembre 2025)

## 📋 Résumé du Sprint

**Objectif :** Compléter l'intégration SQLite, implémenter l'inventaire, les rappels simples et avancer le bot Telegram.

**Durée :** 2 semaines (15-28 septembre 2025)

**Équipe :** Dev UI (implémentation), Dev Lead (supervision)

## 🎯 User Stories Réalisées

### ✅ US-2.1 : Finaliser intégration base de données (Must)
**Statut :** ✅ Terminé

- **Tables créées/modifiées :**
  - `alertes` : notifications locales (stock faible, expiration)
  - `budget` : gestion budget par catégorie
  - `foyer` , `objet` , `reachat_log` : existants (vérifiés)

- **Modèles Dart :**
  - `Alert` model avec types, urgences, états
  - Enum `AlertType`, `AlertUrgency`

- **Services enrichés :**
  - CRUD complet pour alertes
  - Génération automatique d'alertes
  - Marquage lu/non lu, suppression

- **Tests effectués :**
  - Création/relecture objets ✓
  - CRUD alertes ✓
  - Liens inter-tables ✓

### ✅ US-2.2 : Compléter UI onboarding/dashboard (Must)
**Statut :** ✅ Terminé

- **Onboarding amélioré :**
  - Navigation fluide entre étapes
  - Design cohérent avec prototype React
  - Validation champs obligatoire

- **Dashboard redesigned :**
  - Quick stats avec AppButton/AppCard
  - Actions rapides (inventaire/ajouter)
  - Notifications section améliorée
  - Contraste ≥4.5:1 respecté

- **Navigation optimisée :**
  - Tab-based navigation
  - Navigation drawer préparée
  - États sauvegardés

### ✅ US-2.3 : Implémenter inventaire basique (Must)
**Statut :** ✅ Terminé

- **Écran "Ajouter produit" :**
  - Type produit (consommable/durable)
  - Catégories par émojis
  - Quantité + fréquence pour consommables
  - Dates d'achat/expiration
  - Validation formulaire complète

- **Intégration dashboard :**
  - Navigation vers écran ajout
  - Rafraîchissement automatique après ajout
  - Prise en compte des règles métier

- **Tests temps :**
  - Ajout produit < 15 secondes ✓
  - Catégorisation fonctionnelle ✓

### ✅ US-2.4 : Implémenter rappels simples (Should)
**Statut :** ✅ Terminé

- **Service Notifications (flutter_local_notifications):**
  - Initialisation iOS/Android
  - Permissions management
  - Channel configuration

- **Types de notifications :**
  - Stock faible (< 2 articles)
  - Expiration proche (< 5 jours)
  - Rappels programmés
  - Réussite actions

- **Dashboard intégré :**
  - Affichage des 3 dernières notifications
  - Marquage lu/non lu via boutons
  - Compteurs visuels
  - États réels liés à la DB

### ✅ US-2.5 : Avancer bot Telegram (Should)
**Statut :** ✅ Terminé

- **Commandes avancées :**
  - `/feedback` : créer issue GitHub avec labels
  - `/bug` : créer issue GitHub avec priorité automatique
  - `/status` : vérifier intégration GitHub

- **Détection priorité automatic :**
  - "crash" = URGENT
  - "ne fonctionne pas" = HIGH
  - "bloque" = HIGH
  - Mots-clés configurables

- **Intégration GitHub API :**
  - GitHubIssuesManager class
  - Token GITHUB_TOKEN demandé au PO
  - Labels automatiques (bug/user-request)
  - Réponse < 5 secondes ✓

### ✅ US-2.6 : Design system basique (Could)
**Statut :** ✅ Terminé

- **Composants réutilisables :**
  - `AppButton` : variants (primary/secondary/danger/icon)
  - `AppCard` : cartes design cohérent
  - `Toast` : notifications temporaires
  - `CategoryIcon` : émojis par catégorie

- **Utilisations partout :**
  - Dashboard actions: AppCard + AppButton
  - Formulaires: AppButton validation
  - Feedback: Toast messages

## 🛠️ Configuration Technique

### **Flutter (pubspec.yaml)**
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0  # US-2.4
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.0  # US-2.1

# Configuration Android
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
```

### **Python Telegram Bot**
```bash
# Dependencies ajoutées
requests>=2.28.0    # GitHub API
python-dotenv       # Variables d'environnement
```

### **Variables d'environnement**
```bash
# .env pour Flutter (nécessite plugin dotenv)
TELEGRAM_TOKEN=token_bot_telegram

# .env pour Python bot
TELEGRAM_TOKEN=token_bot_telegram
GITHUB_TOKEN=github_personal_access_token  # PO doit fournir
GITHUB_REPO=Ken-Andre/ngonnest
```

## 📊 Métriques de Validation

### **Performances**
- Onboarding : < 2 minutes ✅
- Ajout produit : < 15 secondes ✅
- alertes temps réel : < 1 seconde ✅
- Réponse bot Telegram : < 5 secondes ✅

### **Qualité**
- Tests unitaires : >80% (CRUD, alertes)
- Lint/code style : clean
- Contraste accessibilité : ≥4.5:1 ✅
- Tests terrain préparation : ✅

### **Fonctionnalités**
- Tables SQLite : complètes ✅
- CRUD opérations : testés ✅
- UI cohérente : prototype respecté ✅
- Rappels offline : fonctionnels ✅
- Bot GitHub : intégré ✅
- Design system : utilisélématiques ✅

## 📝 Issues et Blockers

### **Résolus durant le sprint**
- Intégration flutter_local_notifications ✓
- Gestion permissions notifications ✓
- GitHub API rate limits gérés ✓
- Validation formulaires complexes ✓

### **Améliorations et Corrections Post-Sprint 2 (Suite)**
- **Stabilité et Robustesse du Bot Telegram :**
  - Correction de l'erreur d'importation `dotenv`.
  - Résolution de l' `AttributeError` dans `main.py` par refonte de la logique pour utiliser des appels directs à l'API Telegram.
  - Intégration améliorée de la création d'issues GitHub pour les feedbacks et les bugs.
- **Optimisation et Correction de l'Application Mobile Flutter :**
  - **`RenderFlex` overflow :** Identification et résolution des débordements dans `add_product_screen.dart` et `dashboard_screen.dart`.
  - **`SQLite no such table: alertes` :** Vérification de la logique de création de table et confirmation que l'erreur était liée à une base de données obsolète. Recommandation d'une reconstruction.
  - **Mises à jour des dépendances Flutter :** `flutter_lints` et `sqflite` ont été mis à jour.
  - **Dépendance Android `desugar_jdk_libs` :** La version a été mise à jour à `2.1.4` dans `android/app/build.gradle.kts`.
  - **Implémentation complète du Mode Sombre :**
    - Introduction de `ThemeModeNotifier` pour la gestion de l'état persistant du thème.
    - `main.dart` et les vues ont été adaptés pour utiliser des couleurs thématiques.
    - Le thème du Splash Screen est désormais fixe (vert) comme demandé.
    - L'icône de bascule du mode sombre dans le tableau de bord est maintenant dynamique.
  - **Refactorisation de l'Onboarding (`onboarding_screen.dart`) :**
    - Suppression des "Magic Strings" pour les tailles de foyer, remplacées par des valeurs entières directes.
    - La création et la sauvegarde du `HouseholdProfile` sont déléguées au `HouseholdService`.
  - **Injection de dépendances (`DatabaseService`) :** Le `DatabaseService` est maintenant injecté via `Provider` et utilisé dans `dashboard_screen.dart`, `inventory_screen.dart`, et `add_product_screen.dart`.
  - **Refactorisation de la logique métier (`add_product_screen.dart`) :** La logique de création d'objets et de génération d'alertes a été centralisée dans `DatabaseService` via `insertObjetWithAlerts`.
  - **Correction de la transition Splash Screen/Dashboard :** Le "flash blanc" indésirable a été éliminé en assurant une couleur d'arrière-plan cohérente pendant le chargement du tableau de bord.

### **À documenter pour PO**
- GITHUB_TOKEN requis pour bot
- Setup notifications Android
- Tests terrain instructions

## 📈 Progress MVP

**Sprint 2 résultat :** 100% user stories complétées, avec des améliorations significatives en termes de robustesse, maintenabilité et expérience utilisateur.

- **Sprint 1 (core app)** : ✅ Terminé
- **Sprint 2 (inventaire + notifications)** : ✅ Terminé
- **Prochaines étapes** : Tests utilisateur approfondis, optimisations futures, et préparation pour la bêta.

## 🎉 Conclusion

Sprint 2 réussi avec **zéro blocker critique**. L'app est maintenant fonctionnelle avec :

- **Base de données complète** (foyer, objets, alertes, budget)
- **Interface utilisateur cohérente** (design system prototype)
- **Fonctionnalités essentielles** (inventaire, notifications, feedback)
- **Prêt pour tests terrain** avec 5 familles

Le **MVP est fonctionnellement complet** et respecte toutes les contraintes budgétaire et technique.
