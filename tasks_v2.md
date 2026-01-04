# NGONNEST – TASKS V2 (POST-MVP)

> Ce fichier contient les tâches V2 (améliorations UX, IA, monétisation).
> À travailler UNIQUEMENT après V1 complet et publié.
> Respecte AI_RULES.md et requirements.md (V2.*).

## 0. Prérequis V2

AVANT de commencer toute tâche V2, vérifier que :
- ✅ V1 est 100% terminé (toutes tasks de tasks_v1.md = DONE)
- ✅ App est publiée sur App Store et Google Play
- ✅ Au moins 100 utilisateurs actifs collectés

---

## Phase V2.1: Visualisations Budget (Semaines 14-15)

### Task 2.1: Graphiques Budget

**Liée à** : Requirement V2.1 (Budget Graphs & Visualization)

- [ ] **2.1.1** Choisir librairie de graphiques
  - Évaluer : `fl_chart`, `charts_flutter`, `syncfusion_flutter_charts`
  - Critères : performance, customisation, licence
  - Choisir et ajouter dans `pubspec.yaml`

- [ ] **2.1.2** Implémenter graphique dépenses mensuelles (barres)
  - Créer widget `MonthlyExpensesBarChart`
  - Données : dépenses par mois (6 derniers mois)
  - Source SQLite : `SELECT month, SUM(spent) FROM budgets GROUP BY month`
  - Customiser couleurs selon thème app

- [ ] **2.1.3** Implémenter graphique dépenses par catégorie (camembert)
  - Widget `CategoryExpensesPieChart`
  - Données : % par catégorie alimentaire
  - Couleurs distinctes par catégorie
  - Légende interactive

- [ ] **2.1.4** Intégrer dans BudgetScreen
  - Ajouter tab ou section "Graphiques"
  - Lazy load graphiques (uniquement quand tab activé)
  - Tester performance avec 12 mois de données

#### Tests pour Task 2.1
- [ ] Widget test charts rendering
- [ ] Performance test : génération graphique <500ms
- [ ] F2P/P2F checks

---

## Phase V2.2: Export PDF (Semaines 16)

### Task 2.2: Génération PDF Rapports Budget

**Liée à** : Requirement V2.2 (PDF Export)

- [ ] **2.2.1** Ajouter dépendance PDF
  - Ajouter `pdf: ^3.10.0` dans `pubspec.yaml`
  - Tester génération PDF simple

- [ ] **2.2.2** Créer service `PdfExportService`
  - Méthode `Future<File> generateBudgetReport(int month, int year)`
  - Template PDF : header (logo, titre), body (tableau dépenses), footer (date)
  - Utiliser données de `BudgetRepository`

- [ ] **2.2.3** Implémenter partage PDF
  - Utiliser `share_plus` pour partager fichier
  - Bouton "Exporter PDF" dans BudgetScreen
  - Enregistrer dans dossier accessible utilisateur

#### Tests pour Task 2.2
- [ ] Unit test génération PDF réussit
- [ ] Integration test : export + partage fonctionne
- [ ] F2P/P2F checks

---

## Phase V2.3: IA On-Device (Semaines 17-18)

### Task 2.3: Prédiction Consommation

**Liée à** : Requirement V2.3 (On-Device AI)

- [ ] **2.3.1** Analyser faisabilité TensorFlow Lite
  - Rechercher modèles pré-entraînés de séries temporelles
  - Évaluer taille modèle (<5MB pour mobile)
  - Tester inférence locale sans cloud

- [ ] **2.3.2** Collecter données historiques consommation
  - Créer table `consumption_history` : produit, quantité, date
  - Enregistrer à chaque ajout/modification produit
  - Accumuler minimum 30 jours de données par produit

- [ ] **2.3.3** Entraîner modèle basique (Python)
  - Script Python : analyse patterns consommation
  - Prédire "jours avant rupture" pour chaque produit
  - Exporter modèle TFLite

- [ ] **2.3.4** Intégrer modèle dans app Flutter
  - Ajouter `tflite_flutter: ^0.10.0`
  - Charger modèle depuis assets
  - Service `AiPredictionService.predictStockout(String productId)`

- [ ] **2.3.5** Afficher prédictions dans UI
  - Badge "Rupture prévue dans X jours" sur produits
  - Section "Suggestions d'achat" dans dashboard
  - Disclaimer : "Prédiction basée sur vos habitudes"

#### Tests pour Task 2.3
- [ ] Unit test modèle prédit correctement (données test)
- [ ] Performance test : inférence <100ms
- [ ] Battery test : impact minimal
- [ ] F2P/P2F checks

---

## Phase V2.4: Premium Features (Semaines 19-20)

### Task 2.4: Monétisation RevenueCat

**Liée à** : Requirement V2.4 (Premium Features)

- [ ] **2.4.1** Configurer RevenueCat
  - Créer compte RevenueCat
  - Configurer produits : "Premium Unique" (5000 FCFA), "Premium Mensuel" (500 FCFA/mois)
  - Intégrer SDK : `purchases_flutter: ^6.0.0`

- [ ] **2.4.2** Implémenter PaywallScreen
  - Écran présentant features premium vs gratuit
  - Boutons achat : "Achat unique" / "Abonnement mensuel"
  - Gérer workflow achat avec RevenueCat

- [ ] **2.4.3** Débloquer features premium
  - Vérifier statut premium au démarrage : `Purchases.getCustomerInfo()`
  - Si premium actif :
    - `FeatureFlagService.isPremiumEnabled = true`
    - Débloquer : IA predictions, PDF export, graphs avancés
  - Si non premium : afficher paywall

- [ ] **2.4.4** Gérer restauration achats
  - Bouton "Restaurer achats" dans Settings
  - Appeler `Purchases.restorePurchases()`

#### Tests pour Task 2.4
- [ ] Integration test : workflow achat complet (sandbox)
- [ ] Test restauration achats
- [ ] F2P/P2F checks

---

## Phase V2.5: Micro-interactions (Semaines 21)

### Task 2.5: Animations & Haptic Feedback

**Liée à** : Requirement V2.5 (Advanced Micro-interactions)

- [ ] **2.5.1** Ajouter haptic feedback
  - Importer `flutter/services.dart`
  - Sur boutons importants : `HapticFeedback.lightImpact()`
  - Sur erreurs : `HapticFeedback.heavyImpact()`

- [ ] **2.5.2** Animations success/failure
  - Package : `lottie: ^2.0.0`
  - Animations Lottie pour : succès (checkmark), échec (croix)
  - Afficher après actions critiques (ajout produit, paiement, etc.)

- [ ] **2.5.3** Confetti célébration budget
  - Package : `confetti: ^0.7.0`
  - Déclencher quand budget respecté en fin de mois
  - Animation joyeuse + message félicitations

- [ ] **2.5.4** Skeleton screens
  - Remplacer CircularProgressIndicator par skeletons
  - Utiliser `shimmer: ^3.0.0`
  - Appliquer sur : liste produits, dashboard cards

#### Tests pour Task 2.5
- [ ] Widget test animations présentes
- [ ] Performance test : animations fluides 60fps
- [ ] F2P/P2F checks

---

## Phase V2.6: Mode Simplifié (Semaines 22)

### Task 2.6: Beginner vs Advanced Mode

**Liée à** : Requirement V2.6 (Simplified Mode)

- [ ] **2.6.1** Créer PreferencesService
  - Enum `UIMode { beginner, advanced }`
  - Méthode `setUIMode(UIMode mode)` avec SharedPreferences
  - Méthode `UIMode getUIMode()`

- [ ] **2.6.2** Adapter formulaires selon mode
  - En mode beginner : formulaire ajout produit simplifié (3 champs)
  - En mode advanced : tous les champs disponibles
  - Toggle mode dans Settings

- [ ] **2.6.3** Tutoriel intégré
  - Package : `tutorial_coach_mark: ^1.2.0`
  - Highlights sur fonctionnalités clés
  - Activable depuis Settings ou "?" icon

#### Tests pour Task 2.6
- [ ] Widget test mode beginner affiche formulaire simplifié
- [ ] Widget test mode advanced affiche tous champs
- [ ] F2P/P2F checks

---

**FIN TASKS V2**
